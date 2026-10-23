import altair as alt
import pandas as pd
import streamlit as st
from utils import AGENT_COLORS, GREEN, RED, run

st.caption("Every tool call is logged under the agent that made it. Source: Cortex Agent observability events (SNOWFLAKE.LOCAL).")

source = st.segmented_control("Source", ["Live (V_AGENT_AUDIT)", "Saved snapshot"], default="Live (V_AGENT_AUDIT)")
try:
    if source == "Saved snapshot":
        raise RuntimeError("snapshot")
    df = run("SELECT event_time, trace_id, viewer_role, sub_agent, tool_type, tool, object_touched FROM WAR_ROOM.OPS.V_AGENT_AUDIT")
    label = "live"
except Exception:
    df = run("SELECT event_time, trace_id, viewer_role, sub_agent, tool_type, tool, object_touched, snapshot_at FROM WAR_ROOM.OPS.AGENT_AUDIT_SNAPSHOT")
    label = f"snapshot from {pd.to_datetime(df['snapshot_at']).max():%d %b %H:%M}" if not df.empty else "snapshot"

if df.empty:
    st.warning("No agent tool calls recorded yet. Run the lead once, then refresh.")
    st.stop()

df["viewer_role"] = df["viewer_role"].fillna("direct test")
roles = sorted(df["viewer_role"].unique())
pick = st.multiselect("Viewer role", roles, default=roles)
df = df[df["viewer_role"].isin(pick)]

# Checks: each sub-agent stays inside its own sources
allowed = {
    "NEWS_SCOUT": {"NEWS_SEARCH"},
    "CONTRACT_ANALYST": {"SUPPLIER_DOCS_SEARCH", "SUPPLIER_DOCS_SEARCH_APAC", "SUPPLIER_DOCS_SEARCH_EMEA"},
    "RISK_HISTORIAN": {"V_LESSONS", "V_RISK_CALENDAR"},
    "INVENTORY_ANALYST": {"SUPPLIERS", "INVENTORY", "SHIPMENTS", "V_EXPOSURE", "V_LESSONS", "V_RISK_CALENDAR"},
}
checks = [
    ("CONTRACT_ANALYST never read shipments", "CONTRACT_ANALYST", {"SHIPMENTS", "INVENTORY", "V_EXPOSURE"}),
    ("RISK_HISTORIAN never read inventory or shipments", "RISK_HISTORIAN", {"SHIPMENTS", "INVENTORY", "V_EXPOSURE", "SUPPLIERS"}),
    ("NEWS_SCOUT never read internal data", "NEWS_SCOUT", {"SHIPMENTS", "INVENTORY", "V_EXPOSURE", "SUPPLIERS", "SUPPLIER_DOCS_SEARCH"}),
]
cols = st.columns(len(checks))
for col, (title, agent, forbidden) in zip(cols, checks):
    hits = df[(df["sub_agent"] == agent) & (df["object_touched"].isin(forbidden))]
    calls = int((df["sub_agent"] == agent).sum())
    ok = hits.empty
    col.markdown(
        f"<div style='border-radius:12px;padding:14px;background:{GREEN if ok else RED};color:white'>"
        f"<div style='font-size:1.4em;font-weight:700'>{'✓ PASS' if ok else '✗ FAIL'}</div>"
        f"<div>{title}</div><div style='opacity:0.8;font-size:0.85em'>{calls} tool calls checked</div></div>",
        unsafe_allow_html=True)

st.write("")
viol = df[[o not in allowed.get(a, {o}) for a, o in zip(df["sub_agent"], df["object_touched"])]]
st.metric("Tool calls outside the agent's own sources", len(viol), help="Any object not in that sub-agent's allowed list")

st.subheader("Agent → tool → object")
edges = df.groupby(["sub_agent", "tool", "object_touched"]).size().reset_index(name="n")
lines = ['digraph G { rankdir=LR; bgcolor="transparent"; node [fontname="Helvetica", fontsize=11, shape=box, style="filled,rounded"];']
for a in edges["sub_agent"].unique():
    lines.append(f'"{a}" [fillcolor="{AGENT_COLORS.get(a, "#455a64")}", fontcolor="white", color="white"];')
for t in edges["tool"].unique():
    lines.append(f'"tool:{t}" [label="{t}", fillcolor="white", color="#90a4ae"];')
for o in edges["object_touched"].unique():
    if o not in set(edges["tool"]):
        lines.append(f'"obj:{o}" [label="{o}", shape=cylinder, fillcolor="#eceff1", color="#b0bec5"];')
for (a, t), n in edges.groupby(["sub_agent", "tool"])["n"].sum().items():
    lines.append(f'"{a}" -> "tool:{t}" [label=" {n} ", fontsize=9, color="#90a4ae"];')
for _, e in edges.iterrows():
    if e["object_touched"] != e["tool"]:
        lines.append(f'"tool:{e["tool"]}" -> "obj:{e["object_touched"]}" [label=" {e["n"]} ", fontsize=9, color="#90a4ae"];')
lines.append("}")
st.graphviz_chart("\n".join(lines), width="stretch")
st.caption(f"Edge label = number of tool calls ({label}). Search services are both the tool and the object they read.")

st.subheader("Timeline of tool calls")
df["event_time"] = pd.to_datetime(df["event_time"])
tl = (
    alt.Chart(df)
    .mark_circle(size=140, opacity=0.85)
    .encode(
        x=alt.X("event_time:T", title="Time (Stockholm)"),
        y=alt.Y("sub_agent:N", title=None, sort=list(AGENT_COLORS)),
        color=alt.Color("sub_agent:N", scale=alt.Scale(domain=list(AGENT_COLORS), range=list(AGENT_COLORS.values())), legend=None),
        shape=alt.Shape("viewer_role:N", title="Viewer"),
        tooltip=["event_time", "viewer_role", "sub_agent", "tool", "object_touched", "trace_id"],
    )
    .properties(height=260)
)
st.altair_chart(tl, width="stretch")

with st.expander("Audit table"):
    st.dataframe(df.sort_values("event_time", ascending=False), hide_index=True, width="stretch")
st.caption("Note: sub-agents run under the viewer's role, so they are identified by agent and tool name in the trace, not by a separate session role.")

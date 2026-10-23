import streamlit as st
from utils import AGENT_COLORS

st.caption("One question in. A research team of four least-privilege sub-agents. One cited brief out.")

dot = f"""
digraph G {{
  rankdir=LR; bgcolor="transparent"; nodesep=0.35; ranksep=0.9;
  node [fontname="Helvetica", fontsize=11, style="filled,rounded", shape=box, color="white", fontcolor="white"];
  edge [color="#90a4ae", arrowsize=0.7];

  subgraph cluster_viewers {{
    label="Viewer roles (row access policy)"; fontname="Helvetica"; fontsize=11; color="#cfd8dc"; style="rounded";
    GLOBAL [label="OPS_GLOBAL\\nall regions", fillcolor="#455a64"];
    EMEA   [label="OPS_EMEA\\nPL / DE / SE", fillcolor="#455a64"];
    APAC   [label="OPS_APAC\\nTW / MY / CN", fillcolor="#455a64"];
  }}

  LEAD [label="WAR_ROOM_LEAD\\nDeep Research\\nwrites the cited brief", fillcolor="#263238", fontsize=12];

  NEWS [label="NEWS_SCOUT\\nAGENT_NEWS_ROLE", fillcolor="{AGENT_COLORS['NEWS_SCOUT']}"];
  INV  [label="INVENTORY_ANALYST\\nAGENT_INVENTORY_ROLE", fillcolor="{AGENT_COLORS['INVENTORY_ANALYST']}"];
  CON  [label="CONTRACT_ANALYST\\nAGENT_CONTRACTS_ROLE", fillcolor="{AGENT_COLORS['CONTRACT_ANALYST']}"];
  HIS  [label="RISK_HISTORIAN\\nAGENT_HISTORIAN_ROLE", fillcolor="{AGENT_COLORS['RISK_HISTORIAN']}"];

  node [style="rounded", fontcolor="#263238", color="#90a4ae", fillcolor="white"];
  T_NEWS [label="Cortex Search\\nNEWS_SEARCH"];
  T_INV  [label="Cortex Analyst\\nSV_OPERATIONS"];
  T_CON  [label="Cortex Search\\nSUPPLIER_DOCS_SEARCH\\n(+ _APAC / _EMEA)"];
  T_HIS  [label="Cortex Analyst\\nSV_HISTORY"];

  node [shape=cylinder, style="filled", fillcolor="#eceff1", fontcolor="#263238", color="#b0bec5"];
  D_NEWS [label="news_feed"];
  D_INV  [label="suppliers · inventory\\nshipments · v_exposure"];
  D_CON  [label="supplier_documents\\ncontracts · emails · quotes"];
  D_HIS  [label="v_lessons\\nv_risk_calendar"];

  GLOBAL -> LEAD; EMEA -> LEAD; APAC -> LEAD;
  LEAD -> NEWS [label=" 1 ", fontsize=9]; LEAD -> INV [label=" 2 ", fontsize=9];
  LEAD -> CON [label=" 2 ", fontsize=9]; LEAD -> HIS [label=" 2 ", fontsize=9];
  NEWS -> T_NEWS -> D_NEWS; INV -> T_INV -> D_INV; CON -> T_CON -> D_CON; HIS -> T_HIS -> D_HIS;
}}
"""
st.graphviz_chart(dot, width="stretch")

TAG = "background:#1e88e5;color:white;padding:2px 8px;border-radius:10px;font-size:0.75em;font-weight:600;margin-right:4px"


def gov_col(title, text, tags):
    tag_html = "".join(f"<span style='{TAG}'>◆ {t}</span>" for t in tags)
    return (f"<div style='flex:1;padding:4px 12px'>"
            f"<div style='color:#e65100;font-weight:700;margin-bottom:4px'>{title}</div>"
            f"<div style='font-size:0.85em;color:#37474f;margin-bottom:8px'>{text}</div>{tag_html}</div>")


st.markdown(
    "<div style='border:2px solid #ffa726;background:#fff8e1;border-radius:10px;padding:12px 8px;margin:8px 0 16px 0'>"
    "<div style='color:#e65100;font-weight:700;font-size:1.05em;padding:0 12px 8px 12px'>Governance layer (applies to every step above)</div>"
    "<div style='display:flex;gap:8px'>"
    + gov_col("Agent identity: least privilege",
              "Each sub-agent has its own role and can reach only its own source. The news scout cannot read shipments.",
              ["Agent Identity", "Roles + Grants (RBAC)"])
    + gov_col("Row access policy: per viewer",
              "viewer_region_access decides which internal rows a role sees. News and history stay public.",
              ["Row Access Policy"])
    + gov_col("Chain of custody: audit trail",
              "Every tool call and query is logged under the agent that made it, so each brief can be traced end to end.",
              ["Cortex AI Observability", "Query + Access History"])
    + "</div></div>",
    unsafe_allow_html=True,
)

c1, c2, c3, c4 = st.columns(4)
c1.metric("Sub-agents", "4", help="Each with its own role and one tool")
c2.metric("Viewer roles", "3", help="Row access policy on internal tables")
c3.metric("Search services", "4", help="News, full docs, APAC docs, EMEA docs")
c4.metric("Semantic views", "2", help="SV_OPERATIONS, SV_HISTORY")

st.markdown(
    "**How a brief is made:** 1. NEWS_SCOUT finds the HIGH-severity alerts and region codes. "
    "2. Those codes go to the other three sub-agents in parallel. "
    "3. The lead cross-checks and writes a one-page brief where every number carries its source."
)
st.info("Sub-agent tools run under the **viewer's** role, so the row access policy decides what each viewer's brief can contain.", icon=":material/shield:")

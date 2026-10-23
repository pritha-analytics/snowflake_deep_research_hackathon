import altair as alt
import pandas as pd
import streamlit as st
from utils import GREEN, GREY, RED, run

st.caption("Same agent, same question. The row access policy decides what each viewer's brief can contain.")

access = run("SELECT role_name, region FROM WAR_ROOM.OPS.VIEWER_REGION_ACCESS")
regions = run("SELECT DISTINCT region FROM WAR_ROOM.OPS.SUPPLIERS ORDER BY 1")["region"].tolist()
roles = ["OPS_GLOBAL", "OPS_EMEA", "OPS_APAC"]

grid = pd.DataFrame([(r, g) for r in roles for g in regions], columns=["role_name", "region"])
grid = grid.merge(access.assign(visible="Visible"), how="left", on=["role_name", "region"]).fillna({"visible": "Hidden"})

st.subheader("Who can see which region")
mx = alt.Chart(grid).encode(x=alt.X("region:N", title=None, sort=regions), y=alt.Y("role_name:N", title=None, sort=roles))
st.altair_chart(
    (mx.mark_rect(cornerRadius=6, stroke="white", strokeWidth=3).encode(
        color=alt.Color("visible:N", scale=alt.Scale(domain=["Visible", "Hidden"], range=[GREEN, "#eceff1"]), legend=None),
        tooltip=["role_name", "region", "visible"])
     + mx.mark_text(fontSize=16).encode(text=alt.condition(alt.datum.visible == "Visible", alt.value("✓"), alt.value("✗")),
                                        color=alt.condition(alt.datum.visible == "Visible", alt.value("white"), alt.value(GREY))))
    .properties(height=200), width="stretch")
st.caption("Source: viewer_region_access, read by row access policy REGION_POLICY on suppliers, inventory, shipments and supplier_documents.")

st.subheader("Tested as each role (secondary roles off)")
res = run("SELECT * FROM WAR_ROOM.OPS.GOVERNANCE_TEST_RESULTS")
if res.empty:
    st.warning("No saved test results yet.")
else:
    st.caption(f"Tests ran at {pd.to_datetime(res['tested_at']).max():%d %b %Y %H:%M}. "
               "The app runs as its owner, so it shows saved results instead of switching roles live.")
    cols = st.columns(3)
    for col, role in zip(cols, roles):
        r = res[res["role_name"] == role]
        if r.empty:
            continue
        r = r.iloc[0]
        tw = int(r["tw_south_shipments"])
        with col, st.container(border=True):
            st.markdown(f"#### {role}")
            st.metric("TW-SOUTH shipments", tw)
            st.metric("MY-PENANG shipments", int(r["my_penang_shipments"]))
            st.metric("EMEA shipments", int(r["emea_shipments"]))
            st.metric("Taiwan stock stuck at port", f"€{int(r['tw_at_port_eur']):,}")
            st.caption(f"Documents visible: {r['visible_docs'] or 'none'}")
            st.markdown(f"<span style='color:{GREEN if tw else RED};font-weight:600'>"
                        f"{'Taiwan exposure visible' if tw else 'Taiwan exposure hidden'}</span>", unsafe_allow_html=True)

st.subheader("The two briefs")
briefs = run("SELECT viewer_role, run_at, brief FROM WAR_ROOM.OPS.BRIEF_RUNS")
if briefs.empty:
    st.info("No saved briefs yet.")
else:
    bcols = st.columns(2)
    for col, role in zip(bcols, ["OPS_EMEA", "OPS_APAC"]):
        b = briefs[briefs["viewer_role"] == role]
        with col, st.container(border=True, height=650):
            st.markdown(f"**As {role}** · {pd.to_datetime(b['run_at']).max():%H:%M}" if not b.empty else f"**As {role}**")
            st.markdown(b.iloc[0]["brief"] if not b.empty else "_Not run yet._")

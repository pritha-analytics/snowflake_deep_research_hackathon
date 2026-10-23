import altair as alt
import streamlit as st
from utils import GREEN, RED, SCOREBOARD_SQL, big_tile, run

with st.spinner("Running 28 checks live..."):
    df = run(SCOREBOARD_SQL)

passed = int((df["result"] == "PASS").sum())
total = len(df)
color = GREEN if passed == total else RED

c1, c2, c3 = st.columns([2, 1, 1])
with c1:
    big_tile("Scoreboard (run live against WAR_ROOM.OPS)", f"{passed} / {total} PASS", color,
             "Every fact the brief must state is checked against the data")
for col, grp in zip((c2, c3), ("Test questions", "Data quality")):
    g = df[df["grp"] == grp]
    with col:
        big_tile(grp, f"{int((g['result'] == 'PASS').sum())} / {len(g)}", GREEN if (g["result"] == "PASS").all() else RED)

st.write("")
df["col"] = (df["id"].astype(int) - 1) % 7
df["row"] = (df["id"].astype(int) - 1) // 7
grid = (
    alt.Chart(df)
    .mark_rect(cornerRadius=6, stroke="white", strokeWidth=3)
    .encode(
        x=alt.X("col:O", axis=None),
        y=alt.Y("row:O", axis=None),
        color=alt.Color("result:N", scale=alt.Scale(domain=["PASS", "FAIL"], range=[GREEN, RED]), legend=None),
        tooltip=["id", "grp", "check_name", "expected", "actual", "result"],
    )
)
labels = alt.Chart(df).mark_text(color="white", fontSize=11, fontWeight="bold").encode(
    x="col:O", y="row:O", text="id:N")
st.altair_chart((grid + labels).properties(height=260), width="stretch")
st.caption("Hover a tile for the expected and actual value.")

with st.expander("All 28 checks"):
    st.dataframe(df[["id", "grp", "check_name", "expected", "actual", "result"]], hide_index=True, width="stretch")

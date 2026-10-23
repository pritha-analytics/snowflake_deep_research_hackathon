import altair as alt
import streamlit as st
from utils import AMBER, run

cal = run("SELECT region, month_no, month_name, historical_risk, avg_closure_days_per_year AS avg_days, closure_days, warnings "
          "FROM WAR_ROOM.OPS.V_RISK_CALENDAR")
les = run("SELECT event_id, event_date, region, event_type, port_closed_days, shipments_delayed, cost_eur, lesson "
          "FROM WAR_ROOM.OPS.V_LESSONS")

regions = sorted(cal["region"].unique())
region = st.segmented_control("Region", regions, default="TW-SOUTH" if "TW-SOUTH" in regions else regions[0])
region = region or "TW-SOUTH"

st.subheader("Typhoon risk calendar")
months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
risk_scale = alt.Scale(domain=["LOW", "MEDIUM", "HIGH"], range=["#c8e6c9", "#ffcc80", "#e53935"])
base = alt.Chart(cal).encode(
    x=alt.X("month_name:N", sort=months, title=None),
    y=alt.Y("region:N", title=None),
)
heat = base.mark_rect(stroke="white", strokeWidth=2).encode(
    color=alt.Color("historical_risk:N", scale=risk_scale, title="Risk"),
    opacity=alt.condition(alt.datum.region == region, alt.value(1), alt.value(0.35)),
    tooltip=["region", "month_name", "historical_risk", "avg_days", "closure_days", "warnings"],
)
text = base.mark_text(fontSize=10).encode(text=alt.Text("avg_days:Q", format=".1f"))
now = alt.Chart(cal[cal["month_no"] == 10]).mark_rect(fill=None, stroke="#263238", strokeWidth=3).encode(
    x=alt.X("month_name:N", sort=months), y="region:N")
st.altair_chart((heat + text + now).properties(height=40 * len(regions) + 40), width="stretch")
st.caption("Number = average port closure days per year. Black outline = October (today).")

r = cal[cal["region"] == region].sort_values("avg_days", ascending=False)
oct_row = r[r["month_no"] == 10]
c1, c2 = st.columns(2)
c1.metric(f"October risk in {region}", oct_row["historical_risk"].iloc[0] if len(oct_row) else "–")
c2.metric("Riskiest months", ", ".join(r[r["historical_risk"] == "HIGH"]["month_name"].head(3)) or "–")

st.subheader(f"Past disruptions in {region}")
lr = les[les["region"] == region]
if lr.empty:
    st.info(f"No past disruptions recorded for {region}.")
else:
    tl = (
        alt.Chart(lr)
        .mark_circle(color=AMBER, opacity=0.85, stroke="#263238", strokeWidth=1)
        .encode(
            x=alt.X("event_date:T", title=None),
            y=alt.Y("port_closed_days:Q", title="Port closed (days)", scale=alt.Scale(zero=True)),
            size=alt.Size("cost_eur:Q", scale=alt.Scale(range=[200, 2500]), title="Cost EUR"),
            tooltip=["event_id", "event_date", "event_type", "port_closed_days", "shipments_delayed",
                     alt.Tooltip("cost_eur:Q", format=",.0f"), "lesson"],
        )
    )
    ids = alt.Chart(lr).mark_text(dy=-22, fontWeight="bold").encode(x="event_date:T", y="port_closed_days:Q", text="event_id")
    st.altair_chart((tl + ids).properties(height=300), width="stretch")
    st.metric("Total cost of these disruptions", f"€{lr['cost_eur'].sum():,.0f}")
    for _, row in lr.sort_values("event_date", ascending=False).iterrows():
        st.markdown(f"**[{row['event_id']}]** {row['event_date']} · {row['port_closed_days']} days closed · "
                    f"€{row['cost_eur']:,.0f}  \n{row['lesson']}")

st.subheader("Have we been here before?")
try:
    then = run("SELECT event_id, event_date, port_closed_days, shipments_delayed, cost_eur, lesson "
               "FROM WAR_ROOM.OPS.V_LESSONS WHERE event_id = 'D-006'")
    now = run("SELECT sku_id, days_of_cover FROM WAR_ROOM.OPS.V_EXPOSURE "
              "WHERE region = 'TW-SOUTH' AND days_of_cover < 20 ORDER BY sku_id")
    then.columns = [c.lower() for c in then.columns]
    now.columns = [c.lower() for c in now.columns]
    t = then.iloc[0]
    left, right = st.columns(2)
    with left, st.container(border=True):
        st.markdown(f"#### September 2024 · {t['event_id']}")
        st.metric("Cost of that typhoon", f"€{float(t['cost_eur']):,.0f}")
        st.write(f"Port closed {int(t['port_closed_days'])} days, {int(t['shipments_delayed'])} shipments delayed.")
        st.caption(t["lesson"])
    with right, st.container(border=True):
        st.markdown("#### Today · 22 October 2026")
        st.metric("Products below the 20-day rule", len(now))
        st.write(", ".join(f"{r.sku_id}: {float(r.days_of_cover):.0f} days" for r in now.itertuples()))
        st.markdown("<span style='color:#c62828;font-weight:600'>SKU-1001 is at 9 days, the same as when it ran out in 2024.</span>",
                    unsafe_allow_html=True)
    st.caption("Incident log and typhoon history are simulated.")
except Exception:
    st.info("Lessons or exposure data not available for this app.")
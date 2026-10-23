import altair as alt
import pandas as pd
import streamlit as st
from utils import RED, run

st.caption("Which product runs out first once the port closes? Bars run from today to the stock-out date. "
           "The black triangle is when the stock held at port arrives (10-day delay: alert A02 + clause 11.3).")

try:
    df = run("""SELECT sku_id, sku_name, days_of_cover, cover_with_in_transit, at_port_delayed_eta,
                       stockout_date_with_in_transit, at_port_margin_days, at_port_status, scenario_date
                FROM WAR_ROOM.OPS.V_EXPOSURE WHERE region = 'TW-SOUTH' ORDER BY sku_id""")
except Exception:
    st.warning("V_EXPOSURE is not available for this app.")
    st.stop()

df.columns = [c.lower() for c in df.columns]
for c in ["scenario_date", "stockout_date_with_in_transit", "at_port_delayed_eta"]:
    df[c] = pd.to_datetime(df[c])
df["tight"] = df["at_port_status"].astype(str).str.startswith(("TIGHT", "LATE"))
df["label"] = "runs out " + df["stockout_date_with_in_transit"].dt.strftime("%d %b")

urgent = df[df["tight"]].sort_values("at_port_margin_days").head(1)
low = df.sort_values("days_of_cover").iloc[0]
a, b, c = st.columns(3)
a.metric("Lowest cover today", low["sku_id"])
a.caption(f"{low['days_of_cover']:.0f} days of cover")
if len(urgent):
    u = urgent.iloc[0]
    b.metric("Most urgent", u["sku_id"])
    b.markdown(f"<span style='color:#c62828;font-weight:600'>only {float(u['at_port_margin_days']):.0f} days margin</span>", unsafe_allow_html=True)
    c.metric("Save first", "SH-004")
    c.caption("expedite under clause 7.2")

y = alt.Y("sku_id:N", title=None, sort=list(df["sku_id"]))
bars = alt.Chart(df).mark_bar(height=26, cornerRadius=5).encode(
    y=y, x=alt.X("scenario_date:T", title=None), x2="stockout_date_with_in_transit:T",
    color=alt.condition("datum.tight", alt.value(RED), alt.value("#90a4ae")),
    tooltip=["sku_id", "sku_name", "days_of_cover", "cover_with_in_transit", "stockout_date_with_in_transit", "at_port_status"])
arrive = alt.Chart(df.dropna(subset=["at_port_delayed_eta"])).mark_point(shape="triangle-down", size=260, filled=True, color="black").encode(
    y=y, x="at_port_delayed_eta:T",
    tooltip=[alt.Tooltip("at_port_delayed_eta:T", title="held stock arrives"), "at_port_margin_days"])
text = alt.Chart(df).mark_text(align="left", dx=6, fontSize=13).encode(
    y=y, x="stockout_date_with_in_transit:T", text="label")
st.altair_chart((bars + arrive + text).properties(height=220), use_container_width=True)

st.caption("SKU-1001 has the least stock today, but 6,000 units are already at sea (SH-001, arriving 27 Oct). "
           "SKU-1003 has no stock at sea: its only shipment (SH-004) is held at Kaohsiung and arrives just 2 days before it runs out.")
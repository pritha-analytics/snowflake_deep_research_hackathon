# Streamlit in Snowflake page: history, map and lessons. Needs war_room_tables.sql and war_room_data.sql loaded.
import calendar
import altair as alt
import pandas as pd
import pydeck as pdk
import streamlit as st

st.set_page_config(page_title="War Room: history and map", layout="wide")
sess = st.connection("snowflake").session()

def load(t):
    d = sess.table(f"WAR_ROOM.OPS.{t}").to_pandas()
    d.columns = [c.lower() for c in d.columns]
    return d

hist, ports, inv, ship, track, dis = (load(t) for t in ["TYPHOON_HISTORY", "PORTS", "INVENTORY", "SHIPMENTS", "TYPHOON_TRACK", "PAST_DISRUPTIONS"])
for d, cols in [(hist, ["typhoon_year", "typhoon_month", "warnings_issued", "port_closure_days"]), (ports, ["latitude", "longitude"]),
                (inv, ["units_on_hand", "daily_demand"]), (ship, ["value_eur", "qty"]), (track, ["latitude", "longitude", "point_order"]), (dis, ["cost_eur", "port_closed_days"])]:
    for c in cols:
        d[c] = d[c].astype(float)

st.title("Taiwan typhoon risk: history, map and lessons")
st.caption("Simulated data. Shows historical patterns, not a forecast.")
t1, t2, t2b, t3 = st.tabs(["Risk calendar", "Map", "Shipping lanes", "Lessons"])

with t1:
    cal = hist.groupby("typhoon_month").agg(closure=("port_closure_days", "sum")).reset_index()
    cal["avg_closure_days"] = cal["closure"] / hist["typhoon_year"].nunique()
    cal["risk"] = cal["avg_closure_days"].apply(lambda v: "HIGH" if v >= 0.8 else ("MEDIUM" if v >= 0.3 else "LOW"))
    cal["month"] = cal["typhoon_month"].astype(int).apply(lambda m: calendar.month_abbr[m])
    st.altair_chart(
        alt.Chart(cal).mark_bar().encode(
            x=alt.X("month:N", sort=list(calendar.month_abbr)[1:], title=None),
            y=alt.Y("avg_closure_days:Q", title="Avg port-closure days per year"),
            color=alt.Color("risk:N", title="Historical risk", scale=alt.Scale(domain=["LOW", "MEDIUM", "HIGH"], range=["#2e7d32", "#f2a900", "#c62828"])),
            tooltip=["month", alt.Tooltip("avg_closure_days:Q", format=".2f"), "risk"],
        ),
        use_container_width=True,
    )
    m = st.selectbox("Planned shipping month", list(calendar.month_abbr)[1:], index=9)
    row = cal[cal["month"] == m].iloc[0]
    safer = ", ".join(cal[cal["risk"] == "LOW"]["month"])
    st.write(f"**{m}** has been **{row['risk']}** risk historically ({row['avg_closure_days']:.2f} closure days per year). Historically safer months: {safer}.")

with t2:
    open_ship = ship[ship["status"].isin(["IN_TRANSIT", "AT_PORT"])]
    tw = inv[inv["region"] == "TW-SOUTH"].copy()
    tw["days_of_cover"] = tw["units_on_hand"] / tw["daily_demand"]
    twv = open_ship[open_ship["region"] == "TW-SOUTH"]
    asia = ports[ports["region"].isin(["TW-SOUTH", "CN-SOUTH"])].copy()
    asia["color"] = asia["region"].apply(lambda r: [198, 40, 40, 230] if r == "TW-SOUTH" else [76, 120, 168, 220])
    asia["label"] = asia["port_name"].apply(lambda n: "Kaohsiung: port closed 48 to 72 hours" if n == "Kaohsiung" else n)
    kao = asia[asia["region"] == "TW-SOUTH"].iloc[0]
    zone = pd.DataFrame([{"longitude": kao["longitude"], "latitude": kao["latitude"], "radius": 150000}])
    trk = track.sort_values("point_order")
    path = [{"path": trk[["longitude", "latitude"]].values.tolist()}]
    storm_label = trk.iloc[:1].assign(label="Typhoon Meilin path")
    fit = pd.concat([trk[["longitude", "latitude"]], asia[["longitude", "latitude"]]]).values.tolist()
    left, right = st.columns([3, 2])
    with left:
        st.pydeck_chart(pdk.Deck(
            layers=[pdk.Layer("ScatterplotLayer", zone, get_position=["longitude", "latitude"], get_radius="radius", get_fill_color=[198, 40, 40, 60]),
                    pdk.Layer("PathLayer", path, get_path="path", get_color=[198, 40, 40], width_min_pixels=4),
                    pdk.Layer("ScatterplotLayer", asia, get_position=["longitude", "latitude"], get_radius=40000, get_fill_color="color"),
                    pdk.Layer("TextLayer", asia, get_position=["longitude", "latitude"], get_text="label", get_size=16, get_color=[255, 255, 255],
                              get_text_anchor="'start'", get_alignment_baseline="'center'", get_pixel_offset=[14, 0]),
                    pdk.Layer("TextLayer", storm_label, get_position=["longitude", "latitude"], get_text="label", get_size=16, get_color=[255, 160, 160],
                              get_text_anchor="'start'", get_alignment_baseline="'bottom'", get_pixel_offset=[0, -10])],
            initial_view_state=pdk.data_utils.compute_view(fit, 0.85),
        ))
        st.caption("Red line = storm path. Red circle = area hit. Blue dot = our other supplier port nearby (Yantian), not in the storm path.")
    with right:
        st.markdown("### What is hit")
        st.markdown(f"**Port:** Kaohsiung, closed 48 to 72 hours\n\n**Supplier:** Formosa Chip Works\n\n**Shipments on the way:** {len(twv)}, worth EUR {twv['value_eur'].sum():,.0f}")
        st.markdown("**Products exposed and days of stock left:**")
        for r in tw.sort_values("days_of_cover").itertuples():
            st.markdown(f"- {r.sku_name}: **{r.days_of_cover:.0f} days**")

with t2b:
    # shortcut: sea routes are rough waypoints (not real vessel tracks), fine for a story map
    TODAY = pd.Timestamp("2026-10-22")  # the scenario date
    GOT = [11.97, 57.71]
    back = [[104.0, 1.2], [97.0, 5.5], [80.0, 5.8], [45.0, 12.0], [43.3, 12.6], [34.0, 27.5], [32.3, 31.3], [25.0, 34.0], [-5.6, 36.0], [-9.5, 43.5], [-5.5, 48.8], [1.5, 51.0], [4.5, 53.5], [8.0, 57.7], [10.6, 57.8], GOT]
    route_start = {"Kaohsiung": [[120.3, 22.6], [112.0, 10.0]], "Yantian": [[114.28, 22.57], [110.0, 10.0]], "Penang": [[100.33, 5.42]]}
    cut = {"Kaohsiung": 0, "Yantian": 0, "Penang": 1}  # Penang joins the main route further west
    openx = ship[ship["status"].isin(["IN_TRANSIT", "AT_PORT", "DELAYED"])]
    lanes = openx.groupby("origin_port").agg(n=("shipment_id", "count"), value=("value_eur", "sum")).reset_index()
    lanes = lanes[lanes["origin_port"].isin(route_start)]
    lanes["hit"] = lanes["origin_port"] == "Kaohsiung"
    lanes["path"] = lanes["origin_port"].apply(lambda o: route_start[o] + back[cut[o]:])
    lanes["color"] = lanes["hit"].apply(lambda h: [198, 40, 40, 230] if h else [120, 150, 190, 200])
    lanes["width"] = lanes["hit"].apply(lambda h: 7 if h else 3)
    lanes["label"] = lanes.apply(lambda r: f"{r['origin_port']}: {r['n']} shipments, EUR {r['value']:,.0f}" + (" AT RISK" if r["hit"] else ""), axis=1)
    lanes["lon"] = lanes["origin_port"].apply(lambda o: route_start[o][0][0])
    lanes["lat"] = lanes["origin_port"].apply(lambda o: route_start[o][0][1])
    dest = pd.DataFrame([{"lon": GOT[0], "lat": GOT[1], "label": "Gothenburg: our warehouse"}])
    storm = pd.DataFrame([{"lon": kao["longitude"], "lat": kao["latitude"], "r": 400000}])
    pts = [pt for pth in lanes["path"] for pt in pth]
    st.pydeck_chart(pdk.Deck(
        layers=[pdk.Layer("ScatterplotLayer", storm, get_position=["lon", "lat"], get_radius="r", get_fill_color=[198, 40, 40, 70]),
                pdk.Layer("PathLayer", lanes[~lanes["hit"]], get_path="path", get_color="color", width_min_pixels=3),
                pdk.Layer("PathLayer", lanes[lanes["hit"]], get_path="path", get_color="color", width_min_pixels=7),
                pdk.Layer("ScatterplotLayer", dest, get_position=["lon", "lat"], get_radius=120000, get_fill_color=[255, 255, 255]),
                pdk.Layer("TextLayer", dest, get_position=["lon", "lat"], get_text="label", get_size=16, get_color=[255, 255, 255],
                          get_text_anchor="'middle'", get_alignment_baseline="'bottom'", get_pixel_offset=[0, -12]),
                *[pdk.Layer("TextLayer", lanes[lanes["origin_port"] == o], get_position=["lon", "lat"], get_text="label", get_size=16, get_color=[255, 255, 255],
                            get_text_anchor="'start'", get_alignment_baseline="'center'", get_pixel_offset=[14, dy]) for o, dy in [("Kaohsiung", -18), ("Yantian", 22), ("Penang", 22)]]],
        initial_view_state=pdk.data_utils.compute_view(pts, 0.95),
    ), height=450)
    st.caption("Red lane = shipments from Kaohsiung, where the typhoon closes the port. Blue lanes = other open shipments, not in the storm path. Routes are drawn roughly.")
    tl = open_ship[open_ship["region"] == "TW-SOUTH"].merge(tw[["sku_id", "sku_name", "days_of_cover"]], on="sku_id")
    tl["eta"] = pd.to_datetime(tl["eta"])
    tl["held"] = tl["status"] == "AT_PORT"
    tl["days_to_arrival"] = (tl["eta"] - TODAY).dt.days
    tl["if_closed"] = tl["days_to_arrival"] + tl["held"] * 3
    st.markdown("**Taiwan shipments this month, and what a 3-day port closure does**")
    st.dataframe(
        tl.sort_values("eta").assign(
            what_happens=tl["held"].map({True: "Held in port, arrives 3 days later", False: "Already at sea, no delay assumed"}))[
            ["shipment_id", "sku_name", "value_eur", "status", "days_of_cover", "days_to_arrival", "if_closed", "what_happens"]].rename(columns={
            "days_of_cover": "days of stock now", "days_to_arrival": "days to arrival", "if_closed": "days to arrival if closed"}).round(0),
        hide_index=True, use_container_width=True)
    late = tl[tl["held"] & (tl["if_closed"] > tl["days_of_cover"])]
    if len(late):
        st.warning("Arrives after the stock is gone, if nothing else comes in: " + ", ".join(f"{r.shipment_id} ({r.sku_name}: stock {r.days_of_cover:.0f} days, arrives in {r.if_closed:.0f})" for r in late.itertuples()))
    st.caption("Worst case: ignores other incoming shipments. The 3 days is the upper end of the 48 to 72 hour closure in the news alerts. Today is 22 Oct 2026 in the scenario.")

with t3:
    ty = dis[dis["event_type"] == "TYPHOON"].sort_values("event_date")
    a, b, c = st.columns(3)
    a.metric("Typhoon events on record", len(ty))
    b.metric("Total cost (EUR)", f"{ty['cost_eur'].sum():,.0f}")
    c.metric("Longest port closure (days)", f"{ty['port_closed_days'].max():.0f}")
    st.dataframe(ty[["event_date", "port_closed_days", "shipments_delayed", "cost_eur", "lesson"]], hide_index=True, use_container_width=True)
    tw = inv[inv["region"] == "TW-SOUTH"].copy()
    tw["days_of_cover"] = tw["units_on_hand"] / tw["daily_demand"]
    low = tw[tw["days_of_cover"] < 20]
    st.warning(f"Today {len(low)} of {len(tw)} Taiwan-sourced SKUs are below the 20-day cover rule we adopted after the 2024 event: "
               + ", ".join(f"{r.sku_id} ({r.days_of_cover:.0f} days)" for r in low.itertuples()))
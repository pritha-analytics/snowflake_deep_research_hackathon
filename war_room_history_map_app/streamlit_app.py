# Streamlit in Snowflake page: history, map and lessons. Needs war_room_tables.sql and war_room_data.sql loaded.
import calendar
import altair as alt
import numpy as np
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
if hist["data_source"].str.upper().str.contains("SIMULATED").any():
    st.caption("Simulated data. Shows historical patterns, not a forecast.")
else:
    st.caption("History: NOAA IBTrACS storms within 200 km of Kaohsiung (a proxy for port closure). Company, shipment and stock data are simulated. Shows patterns, not a forecast.")
t1, t2, t2b, t3, t4 = st.tabs(["Risk calendar", "Map", "Shipping lanes", "Lessons", "Shipment calendar"])

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
    
    try:
        exp = load("V_EXPOSURE")
        exp = exp[exp["region"] == "TW-SOUTH"].sort_values("sku_id")
        st.markdown("**Taiwan products once the port closes** (from V_EXPOSURE, the same view the agents use)")
        st.dataframe(
            exp[["sku_id", "sku_name", "days_of_cover", "cover_with_in_transit", "at_port_qty",
                 "at_port_delayed_eta", "stockout_date_with_in_transit", "at_port_margin_days", "at_port_status"]]
            .rename(columns={"days_of_cover": "days of stock now", "cover_with_in_transit": "days incl. stock at sea",
                             "at_port_qty": "units held at port", "at_port_delayed_eta": "held stock arrives",
                             "stockout_date_with_in_transit": "stock runs out", "at_port_margin_days": "margin (days)",
                             "at_port_status": "status"}),
            hide_index=True, use_container_width=True)
        risky = exp[exp["at_port_status"].astype(str).str.startswith(("TIGHT", "LATE"))]
        if len(risky):
            st.warning("Hidden risk: " + ", ".join(
                f"{r.sku_id} {r.sku_name} looks safe, but its stock held at port arrives {r.at_port_delayed_eta} "
                f"and stock runs out {r.stockout_date_with_in_transit}: only {float(r.at_port_margin_days):.0f} days margin"
                for r in risky.itertuples()))
        st.caption("Assumes stock held at port arrives 10 days late (3 days closure from alert A02 + up to 5 business days restart under clause 11.3); "
                   "stock already at sea arrives on its ETA. Scenario date 22 Oct 2026.")
    except Exception:
        st.info("Exposure table not available (V_EXPOSURE). The map above still shows the shipping lanes.")

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


with t4:  # last in the script on purpose: if the new tables are missing, the other tabs still render
    try:
        ps, psh = load("PLANNED_SHIPMENTS"), load("PORT_STORM_HISTORY_REAL")
    except Exception:
        st.info("Run war_room_ports_plan.sql first. It creates the planned shipments and the storm history per port.")
        st.stop()
    TODAY = pd.Timestamp("2026-10-22")  # the scenario date

    def feats(m):  # month as a circle, so December and January are neighbours
        m = np.asarray(m, dtype=float)
        return np.column_stack([np.sin(2 * np.pi * m / 12), np.cos(2 * np.pi * m / 12)])

    def fit_logit(X, y, l2=0.2):  # logistic regression by Newton steps, same as the risk model page
        A = np.column_stack([np.ones(len(X)), X]); w = np.zeros(A.shape[1]); R = l2 * np.eye(A.shape[1]); R[0, 0] = 0
        for _ in range(50):
            p = 1 / (1 + np.exp(-A @ w))
            w -= np.linalg.solve(A.T @ (A * (p * (1 - p))[:, None]) + R + 1e-9 * np.eye(len(w)), A.T @ (p - y) + R @ w)
        return w

    def month_risk(port_id):  # chance of a storm near the port, per month 1..12; None if there were too few storm months to learn from
        h = psh[psh["port_id"] == port_id]
        y = (h["storm_days_200km"].astype(float) > 0).astype(int).values
        if y.sum() < 5:
            return None
        w = fit_logit(feats(h["storm_month"].astype(int)), y)
        return 1 / (1 + np.exp(-(np.column_stack([np.ones(12), feats(range(1, 13))]) @ w)))

    for c in ["value_eur", "qty"]:
        ps[c] = ps[c].astype(float)
    ps["sail_date"] = pd.to_datetime(ps["sail_date"])
    ps = ps.merge(ports[["port_id", "port_name", "country", "latitude", "longitude"]], on="port_id")
    ps["days_to_sail"] = (ps["sail_date"] - TODAY).dt.days
    ps["urgency"] = ps["days_to_sail"].apply(lambda d: "RED" if d <= 14 else ("ORANGE" if d <= 45 else "GREEN"))
    ps["label"] = ps["country"] + ": " + ps["port_name"]
    psh["storm_month"] = psh["storm_month"].astype(int)
    typhoon_ports = set(ports[(ports["longitude"] > 95) & (ports["latitude"] > 0)]["port_id"])  # the NOAA data covers the West Pacific only
    risk = {pid: month_risk(pid) for pid in ps["port_id"].unique() if pid in typhoon_ports}

    def storm_text(r):
        if r["port_id"] not in typhoon_ports:
            return "Outside the typhoon region"
        pr = risk.get(r["port_id"])
        if pr is None:
            return "Almost no storms in 10 years"
        m = r["sail_date"].month
        yrs = int(((psh["port_id"] == r["port_id"]) & (psh["storm_month"] == m) & (psh["storm_days_200km"].astype(float) > 0)).sum())
        return f"{pr[m - 1]:.0%} {'HIGH' if pr[m - 1] >= 0.35 else ('MEDIUM' if pr[m - 1] >= 0.15 else 'LOW')} (storm in {yrs} of 10 years)"
    ps["storm_risk_in_sailing_month"] = ps.apply(storm_text, axis=1)

    st.subheader("Which shipments sail when, and which ports have storm history")
    pick = st.selectbox("Country and port", ["All ports"] + sorted(ps["label"].unique()))
    sel = ps if pick == "All ports" else ps[ps["label"] == pick]

    soon = sel.sort_values("days_to_sail").groupby("port_id").agg(
        port_name=("port_name", "first"), latitude=("latitude", "first"), longitude=("longitude", "first"),
        n=("shipment_id", "count"), first_days=("days_to_sail", "min"), urgency=("urgency", "first")).reset_index()
    soon["color"] = soon["urgency"].map({"RED": [198, 40, 40, 235], "ORANGE": [242, 169, 0, 235], "GREEN": [46, 125, 50, 235]})
    soon["text"] = soon.apply(lambda r: f"{r['port_name']}: {r['n']} shipment{'s' if r['n'] > 1 else ''}, next in {r['first_days']} days", axis=1)
    got = ports[ports["port_name"] == "Gothenburg"].head(1)
    if pick == "All ports":
        view_pts = soon[soon["port_id"].isin(typhoon_ports)][["longitude", "latitude"]]  # Asian ports; the European ones are in the table
    else:
        view_pts = pd.concat([soon[["longitude", "latitude"]], got[["longitude", "latitude"]]]) if soon["port_id"].iloc[0] not in typhoon_ports else soon[["longitude", "latitude"]]
    layers = [pdk.Layer("ScatterplotLayer", soon, get_position=["longitude", "latitude"], get_radius=60000, get_fill_color="color"),
              pdk.Layer("TextLayer", soon, get_position=["longitude", "latitude"], get_text="text", get_size=15, get_color=[255, 255, 255],
                        get_text_anchor="'start'", get_alignment_baseline="'center'", get_pixel_offset=[14, 0])]
    if pick != "All ports" and soon["port_id"].iloc[0] not in typhoon_ports and len(got):
        layers.append(pdk.Layer("ScatterplotLayer", got, get_position=["longitude", "latitude"], get_radius=60000, get_fill_color=[255, 255, 255, 235]))
    st.pydeck_chart(pdk.Deck(layers=layers, initial_view_state=pdk.ViewState(longitude=float(view_pts.iloc[0, 0]), latitude=float(view_pts.iloc[0, 1]), zoom=5) if len(view_pts) == 1 else pdk.data_utils.compute_view(view_pts.values.tolist(), 0.9)), height=430)
    st.caption("Dot colour = how soon the next shipment from that port sails. Red: within 2 weeks. Orange: 2 to 6 weeks. Green: later than 6 weeks. "
               "The map shows the Asian ports; shipments from Europe are in the table.")

    show = sel.sort_values("sail_date")[["shipment_id", "country", "port_name", "supplier_name", "product", "value_eur", "sail_date", "days_to_sail", "urgency", "storm_risk_in_sailing_month"]].copy()
    show["sail_date"] = show["sail_date"].dt.strftime("%Y-%m-%d")
    st.dataframe(show, hide_index=True, use_container_width=True)
    st.download_button("Download as CSV (opens in Excel)", show.to_csv(index=False), "upcoming_shipments.csv", "text/csv")

    if pick != "All ports":
        pid = sel["port_id"].iloc[0]
        st.markdown(f"**Storm history for {sel['port_name'].iloc[0]}** (real NOAA storms, 2016 to 2025)")
        if pid not in typhoon_ports:
            st.write("This port is outside the typhoon region, so there is no storm history to show.")
        else:
            h = psh[psh["port_id"] == pid].groupby("storm_month").agg(days=("storm_days_200km", lambda v: v.astype(float).sum())).reset_index()
            h["avg_days_per_year"] = h["days"] / psh["storm_year"].nunique()
            h["month"] = h["storm_month"].apply(lambda m: calendar.month_abbr[m])
            st.altair_chart(alt.Chart(h).mark_bar(color="#4c78a8").encode(
                x=alt.X("month:N", sort=list(calendar.month_abbr)[1:], title=None),
                y=alt.Y("avg_days_per_year:Q", title="Avg days a storm was within 200 km, per year"),
                tooltip=["month", alt.Tooltip("avg_days_per_year:Q", format=".2f")]), use_container_width=True)
            if risk.get(pid) is None:
                st.write("Too few storms in 10 years to estimate a risk by month.")
    st.caption("Storm risk = the chance that a tropical storm comes within 200 km of the port in the sailing month, from a simple model on 10 years of real NOAA storms. "
               "It is not a forecast and not a record of port closures. Shipments and suppliers are simulated.")
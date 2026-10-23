# Streamlit in Snowflake page: monthly storm-risk model with Snowpark. Needs war_room_data.sql loaded.
# No extra packages needed: the model is plain numpy (trial accounts cannot install packages).
import altair as alt
import numpy as np
import pandas as pd
import streamlit as st

st.set_page_config(page_title="War Room: risk model", layout="wide")
sess = st.connection("snowflake").session()  # Snowpark session: the data and the result both stay in Snowflake

hist = sess.table("WAR_ROOM.OPS.TYPHOON_HISTORY").to_pandas()
hist.columns = [c.lower() for c in hist.columns]
hist["month"] = hist["typhoon_month"].astype(int)
hist["closure"] = (hist["port_closure_days"].astype(float) > 0).astype(int)

def feats(m):  # month as a circle, so December and January are neighbours
    m = np.asarray(m, dtype=float)
    return np.column_stack([np.sin(2 * np.pi * m / 12), np.cos(2 * np.pi * m / 12)])

def fit(X, y, l2=0.2):  # logistic regression by Newton steps, intercept not penalised
    A = np.column_stack([np.ones(len(X)), X]); w = np.zeros(A.shape[1]); R = l2 * np.eye(A.shape[1]); R[0, 0] = 0
    for _ in range(50):
        p = 1 / (1 + np.exp(-A @ w))
        w -= np.linalg.solve(A.T @ (A * (p * (1 - p))[:, None]) + R + 1e-9 * np.eye(len(w)), A.T @ (p - y) + R @ w)
    return w

def predict(w, X):
    return 1 / (1 + np.exp(-(np.column_stack([np.ones(len(X)), X]) @ w)))

def auc_score(y, s):  # chance that a closure month is scored higher than a quiet month
    r = pd.Series(s).rank().values; n1 = int(y.sum()); n0 = len(y) - n1
    return (r[y == 1].sum() - n1 * (n1 + 1) / 2) / (n1 * n0)

st.title("Which months does a Taiwan port closure usually happen?")
st.caption("Model: logistic regression on month. Trained on the history table inside Snowflake.")
if hist["closure"].nunique() < 2:
    st.error("The history has only one outcome, so a model cannot be trained.")
    st.stop()

X, y = feats(hist["month"]), hist["closure"].values
rng = np.random.default_rng(0); fold = np.zeros(len(y), dtype=int)
for cls in (0, 1):
    idx = rng.permutation(np.where(y == cls)[0]); fold[idx] = np.arange(len(idx)) % 5
aucs = [auc_score(y[fold == k], predict(fit(X[fold != k], y[fold != k]), X[fold == k])) for k in range(5) if y[fold == k].sum() > 0]
auc = float(np.mean(aucs))
w = fit(X, y)
pred = pd.DataFrame({"month_no": range(1, 13)})
pred["probability_closure"] = predict(w, feats(pred["month_no"])).round(3)
pred["risk_level"] = pred["probability_closure"].apply(lambda p: "HIGH" if p >= 0.35 else ("MEDIUM" if p >= 0.15 else "LOW"))

a, b, c = st.columns(3)
a.metric("Months in history", len(hist))
b.metric("Share of months with a closure", f"{y.mean():.0%}")
c.metric("Model accuracy (AUC, 5-fold)", f"{auc:.2f}", help="0.5 = no better than guessing, 1.0 = perfect")

names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
pred["month"] = pred["month_no"].apply(lambda m: names[m - 1])
st.altair_chart(
    alt.Chart(pred).mark_bar().encode(
        x=alt.X("month:N", sort=names, title=None), y=alt.Y("probability_closure:Q", title="Chance of a port closure in that month", axis=alt.Axis(format="%")),
        color=alt.Color("risk_level:N", title="Risk", scale=alt.Scale(domain=["LOW", "MEDIUM", "HIGH"], range=["#2e7d32", "#f2a900", "#c62828"])),
        tooltip=["month", alt.Tooltip("probability_closure:Q", format=".0%"), "risk_level"],
    ),
    use_container_width=True,
)
if hist["data_source"].str.upper().str.contains("SIMULATED").any():
    st.warning("The history table is simulated, so the model only recovers the seasonal pattern in it. Load real storm history into TYPHOON_HISTORY and run this page again.")
else:
    st.info("Real storm history (NOAA IBTrACS). A 'closure' here means a tropical storm came within 200 km of Kaohsiung that month. It is a proxy for port closure, not a record of closures.")

if st.button("Save predictions to Snowflake (table MONTH_RISK_PREDICTION)"):
    out = pred[["month_no", "probability_closure", "risk_level"]].rename(columns=str.upper)
    out["MODEL_NOTE"] = f"logistic regression on month, AUC {auc:.2f}"
    out["TRAINED_AT"] = pd.Timestamp.now()
    sess.create_dataframe(out).write.mode("overwrite").save_as_table("WAR_ROOM.OPS.MONTH_RISK_PREDICTION")
    st.success("Saved. In SQL: SELECT * FROM WAR_ROOM.OPS.MONTH_RISK_PREDICTION ORDER BY MONTH_NO;")
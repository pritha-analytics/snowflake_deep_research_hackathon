import os

import streamlit as st
from utils import clear_cache

st.set_page_config(page_title="War Room · Nordlys Electronics", page_icon=":material/storm:", layout="wide")

if "conn" not in st.session_state:
    st.session_state.conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))

page = st.navigation(
    [
        st.Page("app_pages/architecture.py", title="Architecture", icon=":material/hub:"),
        st.Page("app_pages/hidden_risk.py", title="The hidden risk", icon=":material/warning:"),
        st.Page("app_pages/scoreboard.py", title="Scoreboard", icon=":material/fact_check:"),
        st.Page("app_pages/risk_history.py", title="Risk history", icon=":material/history:"),
        st.Page("app_pages/two_viewers.py", title="Two viewers, two briefs", icon=":material/group:"),
        st.Page("app_pages/custody.py", title="Chain of custody", icon=":material/verified_user:"),
    ],
    position="top",
)

with st.sidebar:
    st.markdown("### Supply Chain War Room")
    st.caption("Nordlys Electronics AB (fictional) · Typhoon Meilin · 22 Oct 2026")
    st.button("Refresh data", on_click=clear_cache, icon=":material/refresh:")
    st.caption("Map page: open the WAR_ROOM_MAP app.")

st.title(f"{page.title}")
page.run()

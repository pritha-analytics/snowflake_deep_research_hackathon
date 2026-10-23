"""Shared helpers for the War Room showcase."""
import pandas as pd
import streamlit as st

GREEN, RED, AMBER, GREY, BLUE = "#2e7d32", "#c62828", "#ef6c00", "#9e9e9e", "#1565c0"

AGENT_COLORS = {
    "NEWS_SCOUT": "#6a1b9a",
    "INVENTORY_ANALYST": "#1565c0",
    "CONTRACT_ANALYST": "#00838f",
    "RISK_HISTORIAN": "#ef6c00",
}


@st.cache_data(ttl=600, show_spinner=False)
def run(sql: str) -> pd.DataFrame:
    df = st.session_state.conn.query(sql, ttl=0)
    df.columns = [c.lower() for c in df.columns]
    return df


def clear_cache():
    run.clear()


def badge(text: str, color: str) -> str:
    return (f"<span style='background:{color};color:white;padding:2px 10px;"
            f"border-radius:12px;font-size:0.85em;font-weight:600'>{text}</span>")


def big_tile(label: str, value: str, color: str, sub: str = ""):
    st.markdown(
        f"<div style='border-radius:14px;padding:18px 20px;background:{color};color:white'>"
        f"<div style='font-size:0.9em;opacity:0.85'>{label}</div>"
        f"<div style='font-size:2.2em;font-weight:700;line-height:1.2'>{value}</div>"
        f"<div style='font-size:0.85em;opacity:0.85'>{sub}</div></div>",
        unsafe_allow_html=True,
    )


SCOREBOARD_SQL = """
WITH checks AS (
          SELECT '01' AS id, 'Rows' AS grp, 'suppliers' AS check_name, '6' AS expected, (SELECT COUNT(*) FROM WAR_ROOM.OPS.suppliers)::STRING AS actual
UNION ALL SELECT '02','Rows','inventory','25',(SELECT COUNT(*) FROM WAR_ROOM.OPS.inventory)::STRING
UNION ALL SELECT '03','Rows','shipments','60',(SELECT COUNT(*) FROM WAR_ROOM.OPS.shipments)::STRING
UNION ALL SELECT '04','Rows','news_feed','20',(SELECT COUNT(*) FROM WAR_ROOM.OPS.news_feed)::STRING
UNION ALL SELECT '05','Rows','supplier_documents','10',(SELECT COUNT(*) FROM WAR_ROOM.OPS.supplier_documents)::STRING
UNION ALL SELECT '06','Rows','viewer_region_access','12',(SELECT COUNT(*) FROM WAR_ROOM.OPS.viewer_region_access)::STRING
UNION ALL SELECT '07','Rows','typhoon_history','120',(SELECT COUNT(*) FROM WAR_ROOM.OPS.typhoon_history)::STRING
UNION ALL SELECT '08','Rows','past_disruptions','8',(SELECT COUNT(*) FROM WAR_ROOM.OPS.past_disruptions)::STRING
UNION ALL SELECT '09','Rows','ports','6',(SELECT COUNT(*) FROM WAR_ROOM.OPS.ports)::STRING
UNION ALL SELECT '10','Rows','typhoon_track','6',(SELECT COUNT(*) FROM WAR_ROOM.OPS.typhoon_track)::STRING
UNION ALL SELECT '11','Test questions','Q1 supplier + SKUs','Formosa Chip Works: SKU-1001, SKU-1002, SKU-1003',(SELECT MIN(s.supplier_name)||': '||LISTAGG(i.sku_id,', ') WITHIN GROUP (ORDER BY i.sku_id) FROM WAR_ROOM.OPS.suppliers s JOIN WAR_ROOM.OPS.inventory i ON i.supplier_id=s.supplier_id WHERE s.region='TW-SOUTH')
UNION ALL SELECT '12','Test questions','Q2 days of cover','9 / 14 / 21',(SELECT LISTAGG(ROUND(days_of_cover)::INT,' / ') WITHIN GROUP (ORDER BY sku_id) FROM WAR_ROOM.OPS.v_exposure WHERE region='TW-SOUTH')
UNION ALL SELECT '13','Test questions','Q3 open shipments','4 shipments, EUR 1200000',(SELECT COUNT(*)||' shipments, EUR '||SUM(value_eur)::INT FROM WAR_ROOM.OPS.shipments WHERE region='TW-SOUTH' AND status IN ('IN_TRANSIT','AT_PORT'))
UNION ALL SELECT '14','Test questions','Q3 at port / at sea','615000 / 585000',(SELECT SUM(at_port_value_eur)::INT||' / '||SUM(in_transit_value_eur)::INT FROM WAR_ROOM.OPS.v_exposure WHERE region='TW-SOUTH')
UNION ALL SELECT '15','Test questions','Q4 clause 7.2','D01',(SELECT LISTAGG(doc_id,',') FROM WAR_ROOM.OPS.supplier_documents WHERE doc_type='CONTRACT' AND content ILIKE '%7.2 Expedited shipping%')
UNION ALL SELECT '16','Test questions','Q4 clause 11.3','D01',(SELECT LISTAGG(doc_id,',') FROM WAR_ROOM.OPS.supplier_documents WHERE doc_type='CONTRACT' AND content ILIKE '%11.3 Force majeure%')
UNION ALL SELECT '17','Test questions','Q5 Penang quote terms','found',(SELECT IFF(content ILIKE '%15 percent%' AND content ILIKE '%40,000 units%' AND content ILIKE '%21 days%','found','missing') FROM WAR_ROOM.OPS.supplier_documents WHERE doc_id='D08')
UNION ALL SELECT '18','Test questions','Q5 Penang vs Formosa price','0.15',(SELECT ROUND(69.00/unit_cost_eur-1,2)::STRING FROM WAR_ROOM.OPS.inventory WHERE sku_id='SKU-1001')
UNION ALL SELECT '19','Test questions','Q6 riskiest months','Aug, Jul, Sep',(SELECT LISTAGG(month_name,', ') WITHIN GROUP (ORDER BY avg_closure_days_per_year DESC) FROM WAR_ROOM.OPS.v_risk_calendar WHERE region='TW-SOUTH' AND historical_risk='HIGH')
UNION ALL SELECT '20','Test questions','Q6 October risk','MEDIUM',(SELECT historical_risk FROM WAR_ROOM.OPS.v_risk_calendar WHERE region='TW-SOUTH' AND month_no=10)
UNION ALL SELECT '21','Test questions','Q7 SKUs below 20-day rule','SKU-1001, SKU-1002',(SELECT LISTAGG(sku_id,', ') WITHIN GROUP (ORDER BY sku_id) FROM WAR_ROOM.OPS.v_exposure WHERE region='TW-SOUTH' AND days_of_cover<20)
UNION ALL SELECT '22','Test questions','Q7 lessons D-006, D-008','2',(SELECT COUNT(*)::STRING FROM WAR_ROOM.OPS.v_lessons WHERE event_id IN ('D-006','D-008') AND region='TW-SOUTH')
UNION ALL SELECT '23','Test questions','Hidden risk: at-port stock','SKU-1003 margin 2',(SELECT LISTAGG(sku_id||' margin '||at_port_margin_days,', ') FROM WAR_ROOM.OPS.v_exposure WHERE at_port_status LIKE 'TIGHT%')
UNION ALL SELECT '24','Test questions','Typhoon alerts','A01, A02, A03',(SELECT LISTAGG(alert_id,', ') WITHIN GROUP (ORDER BY alert_id) FROM WAR_ROOM.OPS.news_feed WHERE region='TW-SOUTH' AND severity='HIGH')
UNION ALL SELECT '25','Data quality','History mismatches','0',(SELECT COUNT(*)::STRING FROM WAR_ROOM.OPS.past_disruptions d JOIN WAR_ROOM.OPS.typhoon_history h ON h.typhoon_year=YEAR(d.event_date) AND h.typhoon_month=MONTH(d.event_date) AND h.region=d.region WHERE d.event_type='TYPHOON' AND d.port_closed_days<>h.port_closure_days)
UNION ALL SELECT '26','Data quality','History joined rows','5',(SELECT COUNT(*)::STRING FROM WAR_ROOM.OPS.past_disruptions d JOIN WAR_ROOM.OPS.typhoon_history h ON h.typhoon_year=YEAR(d.event_date) AND h.typhoon_month=MONTH(d.event_date) AND h.region=d.region WHERE d.event_type='TYPHOON')
UNION ALL SELECT '27','Data quality','Distinct region codes','9',(SELECT COUNT(DISTINCT region)::STRING FROM (SELECT region FROM WAR_ROOM.OPS.suppliers UNION SELECT region FROM WAR_ROOM.OPS.inventory UNION SELECT region FROM WAR_ROOM.OPS.shipments UNION SELECT region FROM WAR_ROOM.OPS.supplier_documents UNION SELECT region FROM WAR_ROOM.OPS.news_feed UNION SELECT region FROM WAR_ROOM.OPS.past_disruptions UNION SELECT region FROM WAR_ROOM.OPS.typhoon_history UNION SELECT region FROM WAR_ROOM.OPS.ports))
UNION ALL SELECT '28','Data quality','Damaged region text','0',(SELECT ((SELECT COUNT(*) FROM WAR_ROOM.OPS.supplier_documents WHERE REGEXP_INSTR(content,'[A-Za-z]TW-SOUTH|TW-SOUTH[A-Za-z-]')>0)+(SELECT COUNT(*) FROM WAR_ROOM.OPS.past_disruptions WHERE REGEXP_INSTR(lesson,'[A-Za-z]TW-SOUTH|TW-SOUTH[A-Za-z-]')>0)+(SELECT COUNT(*) FROM WAR_ROOM.OPS.news_feed WHERE REGEXP_INSTR(headline||' '||body,'[A-Za-z]TW-SOUTH|TW-SOUTH[A-Za-z-]')>0))::STRING)
)
SELECT id, grp, check_name, expected, actual, IFF(expected = actual, 'PASS', 'FAIL') AS result FROM checks ORDER BY id
"""

-- War Room: step 5 of 5. One scoreboard query: every line should say PASS.
-- Run as WAR_ROOM_ADMIN (check the role selector at the top right).
-- Click anywhere inside the query and press Ctrl+Enter. It is one single statement.
-- Governance tests (T1-T5) are in war_room_governance.sql and run in the hackathon account.
USE SCHEMA WAR_ROOM.OPS;

WITH checks AS (
            SELECT '01 rows: suppliers'        AS check_name, '6'   AS expected, (SELECT COUNT(*) FROM suppliers)::STRING            AS actual
  UNION ALL SELECT '02 rows: inventory',        '25',  (SELECT COUNT(*) FROM inventory)::STRING
  UNION ALL SELECT '03 rows: shipments',        '60',  (SELECT COUNT(*) FROM shipments)::STRING
  UNION ALL SELECT '04 rows: news_feed',        '20',  (SELECT COUNT(*) FROM news_feed)::STRING
  UNION ALL SELECT '05 rows: supplier_documents','10', (SELECT COUNT(*) FROM supplier_documents)::STRING
  UNION ALL SELECT '06 rows: viewer_region_access','12',(SELECT COUNT(*) FROM viewer_region_access)::STRING
  UNION ALL SELECT '07 rows: typhoon_history',  '120', (SELECT COUNT(*) FROM typhoon_history)::STRING
  UNION ALL SELECT '08 rows: past_disruptions', '8',   (SELECT COUNT(*) FROM past_disruptions)::STRING
  UNION ALL SELECT '09 rows: ports',            '6',   (SELECT COUNT(*) FROM ports)::STRING
  UNION ALL SELECT '10 rows: typhoon_track',    '6',   (SELECT COUNT(*) FROM typhoon_track)::STRING

  -- Test questions (what the brief must say)
  UNION ALL SELECT '11 Q1 supplier + SKUs in typhoon region', 'Formosa Chip Works: SKU-1001, SKU-1002, SKU-1003',
    (SELECT MIN(s.supplier_name) || ': ' || LISTAGG(i.sku_id, ', ') WITHIN GROUP (ORDER BY i.sku_id)
     FROM suppliers s JOIN inventory i ON i.supplier_id = s.supplier_id WHERE s.region = 'TW-SOUTH')
  UNION ALL SELECT '12 Q2 days of cover (1001/1002/1003)', '9 / 14 / 21',
    (SELECT LISTAGG(ROUND(days_of_cover)::INT, ' / ') WITHIN GROUP (ORDER BY sku_id) FROM v_exposure WHERE region = 'TW-SOUTH')
  UNION ALL SELECT '13 Q3 open shipments from Formosa', '4 shipments, EUR 1200000',
    (SELECT COUNT(*) || ' shipments, EUR ' || SUM(value_eur)::INT FROM shipments WHERE region = 'TW-SOUTH' AND status IN ('IN_TRANSIT','AT_PORT'))
  UNION ALL SELECT '14 Q3 split: at port / at sea', '615000 / 585000',
    (SELECT SUM(at_port_value_eur)::INT || ' / ' || SUM(in_transit_value_eur)::INT FROM v_exposure WHERE region = 'TW-SOUTH')
  UNION ALL SELECT '15 Q4 clause 7.2 expedited shipping', 'D01',
    (SELECT LISTAGG(doc_id, ',') FROM supplier_documents WHERE doc_type = 'CONTRACT' AND content ILIKE '%7.2 Expedited shipping%')
  UNION ALL SELECT '16 Q4 clause 11.3 force majeure', 'D01',
    (SELECT LISTAGG(doc_id, ',') FROM supplier_documents WHERE doc_type = 'CONTRACT' AND content ILIKE '%11.3 Force majeure%')
  UNION ALL SELECT '17 Q5 Penang quote: 15 percent, 40,000 units, 21 days', 'found',
    (SELECT IFF(content ILIKE '%15 percent%' AND content ILIKE '%40,000 units%' AND content ILIKE '%21 days%', 'found', 'missing')
     FROM supplier_documents WHERE doc_id = 'D08')
  UNION ALL SELECT '18 Q5 Penang price vs Formosa (SKU-1001)', '0.15',
    (SELECT ROUND(69.00 / unit_cost_eur - 1, 2)::STRING FROM inventory WHERE sku_id = 'SKU-1001')
  UNION ALL SELECT '19 Q6 riskiest months (HIGH)', 'Aug, Jul, Sep',
    (SELECT LISTAGG(month_name, ', ') WITHIN GROUP (ORDER BY avg_closure_days_per_year DESC)
     FROM v_risk_calendar WHERE region = 'TW-SOUTH' AND historical_risk = 'HIGH')
  UNION ALL SELECT '20 Q6 October risk', 'MEDIUM',
    (SELECT historical_risk FROM v_risk_calendar WHERE region = 'TW-SOUTH' AND month_no = 10)
  UNION ALL SELECT '21 Q7 SKUs below 20-day rule (D-006)', 'SKU-1001, SKU-1002',
    (SELECT LISTAGG(sku_id, ', ') WITHIN GROUP (ORDER BY sku_id) FROM v_exposure WHERE region = 'TW-SOUTH' AND days_of_cover < 20)
  UNION ALL SELECT '22 Q7 lessons D-006 and D-008 exist', '2',
    (SELECT COUNT(*)::STRING FROM v_lessons WHERE event_id IN ('D-006','D-008') AND region = 'TW-SOUTH')
  UNION ALL SELECT '23 hidden risk: at-port stock arrives just in time', 'SKU-1003 margin 2',
    (SELECT LISTAGG(sku_id || ' margin ' || at_port_margin_days, ', ') FROM v_exposure WHERE at_port_status LIKE 'TIGHT%')
  UNION ALL SELECT '24 typhoon alerts (HIGH, TW-SOUTH)', 'A01, A02, A03',
    (SELECT LISTAGG(alert_id, ', ') WITHIN GROUP (ORDER BY alert_id) FROM news_feed WHERE region = 'TW-SOUTH' AND severity = 'HIGH')

  -- Data quality
  UNION ALL SELECT '25 history matches past disruptions (mismatches)', '0',
    (SELECT COUNT(*)::STRING FROM past_disruptions d JOIN typhoon_history h
       ON h.typhoon_year = YEAR(d.event_date) AND h.typhoon_month = MONTH(d.event_date) AND h.region = d.region
     WHERE d.event_type = 'TYPHOON' AND d.port_closed_days <> h.port_closure_days)
  UNION ALL SELECT '26 history rows joined to past disruptions', '5',
    (SELECT COUNT(*)::STRING FROM past_disruptions d JOIN typhoon_history h
       ON h.typhoon_year = YEAR(d.event_date) AND h.typhoon_month = MONTH(d.event_date) AND h.region = d.region
     WHERE d.event_type = 'TYPHOON')
  UNION ALL SELECT '27 distinct region codes', '9',
    (SELECT COUNT(DISTINCT region)::STRING FROM (
       SELECT region FROM suppliers UNION SELECT region FROM inventory UNION SELECT region FROM shipments
       UNION SELECT region FROM supplier_documents UNION SELECT region FROM news_feed
       UNION SELECT region FROM past_disruptions UNION SELECT region FROM typhoon_history UNION SELECT region FROM ports))
  UNION ALL SELECT '28 damaged text from TW replace', '0',
    (SELECT (
       (SELECT COUNT(*) FROM supplier_documents WHERE REGEXP_INSTR(content, '[A-Za-z]TW-SOUTH|TW-SOUTH[A-Za-z-]') > 0)
     + (SELECT COUNT(*) FROM past_disruptions   WHERE REGEXP_INSTR(lesson,  '[A-Za-z]TW-SOUTH|TW-SOUTH[A-Za-z-]') > 0)
     + (SELECT COUNT(*) FROM news_feed          WHERE REGEXP_INSTR(headline || ' ' || body, '[A-Za-z]TW-SOUTH|TW-SOUTH[A-Za-z-]') > 0)
     )::STRING)
)
SELECT check_name, expected, actual,
       IFF(expected = actual, 'PASS', 'FAIL') AS result
FROM checks
ORDER BY check_name;
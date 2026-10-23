-- War Room: step 3 of 5. Analysis views. Run after war_room_data.sql.
-- Simulated data. Views are not filtered by region: agents filter on the region the news scout finds.
-- Row access policies on the base tables (step 4) also apply through these views.
USE ROLE WAR_ROOM_ADMIN;
USE WAREHOUSE WAR_ROOM_WH;
USE SCHEMA WAR_ROOM.OPS;

-- 1. Risk calendar: average port-closure days per year, by region and month
CREATE OR REPLACE VIEW v_risk_calendar
  COMMENT = 'Historical typhoon risk by region and month (simulated history 2016-2025)'
AS
SELECT
  region,
  typhoon_month                                                          AS month_no,
  TO_CHAR(DATE_FROM_PARTS(2000, typhoon_month, 1), 'MON')                AS month_name,
  SUM(warnings_issued)                                                   AS warnings,
  SUM(port_closure_days)                                                 AS closure_days,
  ROUND(SUM(port_closure_days) / COUNT(DISTINCT typhoon_year), 2)        AS avg_closure_days_per_year,
  CASE WHEN SUM(port_closure_days) / COUNT(DISTINCT typhoon_year) >= 0.8 THEN 'HIGH'
       WHEN SUM(port_closure_days) / COUNT(DISTINCT typhoon_year) >= 0.3 THEN 'MEDIUM'
       ELSE 'LOW' END                                                    AS historical_risk,
  MIN(data_source)                                                       AS data_source
FROM typhoon_history
GROUP BY region, typhoon_month;

-- 2. Exposure per SKU, all regions
--    Assumption (stated so the agent can quote it): stock held at port arrives
--    10 days late = 3 days port closure (alert A02) + up to 5 business days restart (contract clause 11.3).
--    Stock already at sea is assumed to arrive on its ETA.
CREATE OR REPLACE VIEW v_exposure
  COMMENT = 'Stock cover and open shipment exposure per SKU. Scenario date 2026-10-22. At-port delay assumption: 10 days (A02 + clause 11.3).'
AS
WITH params AS (
  SELECT '2026-10-22'::DATE AS scenario_date, 10 AS port_delay_days
),
agg AS (
  SELECT
    i.region, i.supplier_id, i.sku_id, i.sku_name,
    i.units_on_hand, i.daily_demand, i.unit_cost_eur,
    SUM(IFF(s.status = 'IN_TRANSIT', s.qty, 0))        AS in_transit_qty,
    SUM(IFF(s.status = 'AT_PORT',    s.qty, 0))        AS at_port_qty,
    SUM(IFF(s.status = 'IN_TRANSIT', s.value_eur, 0))  AS in_transit_value_eur,
    SUM(IFF(s.status = 'AT_PORT',    s.value_eur, 0))  AS at_port_value_eur,
    MIN(IFF(s.status = 'AT_PORT',    s.eta, NULL))     AS first_at_port_eta,
    LISTAGG(s.shipment_id, ', ') WITHIN GROUP (ORDER BY s.shipment_id) AS open_shipment_ids
  FROM inventory i
  LEFT JOIN shipments s
    ON s.sku_id = i.sku_id AND s.status IN ('IN_TRANSIT', 'AT_PORT')
  GROUP BY i.region, i.supplier_id, i.sku_id, i.sku_name, i.units_on_hand, i.daily_demand, i.unit_cost_eur
)
SELECT
  a.region, a.supplier_id, a.sku_id, a.sku_name,
  a.units_on_hand, a.daily_demand, a.unit_cost_eur,
  ROUND(a.units_on_hand / NULLIF(a.daily_demand, 0), 1)                                   AS days_of_cover,
  DATEADD(day, FLOOR(a.units_on_hand / NULLIF(a.daily_demand, 0)), p.scenario_date)       AS stockout_date_no_inbound,
  a.in_transit_qty, a.at_port_qty,
  a.in_transit_value_eur, a.at_port_value_eur,
  a.in_transit_value_eur + a.at_port_value_eur                                            AS open_value_eur,
  ROUND((a.units_on_hand + a.in_transit_qty) / NULLIF(a.daily_demand, 0), 1)              AS cover_with_in_transit,
  DATEADD(day, FLOOR((a.units_on_hand + a.in_transit_qty) / NULLIF(a.daily_demand, 0)), p.scenario_date) AS stockout_date_with_in_transit,
  DATEADD(day, p.port_delay_days, a.first_at_port_eta)                                    AS at_port_delayed_eta,
  DATEDIFF(day, at_port_delayed_eta, stockout_date_with_in_transit)                       AS at_port_margin_days,
  CASE WHEN days_of_cover < 20 THEN 'BELOW 20-DAY RULE (D-006)' ELSE 'OK' END             AS rule_status,
  CASE WHEN a.at_port_qty = 0       THEN 'NO STOCK HELD AT PORT'
       WHEN at_port_margin_days < 0 THEN 'LATE: at-port stock arrives after stock-out'
       WHEN at_port_margin_days <= 3 THEN 'TIGHT: at-port stock arrives within 3 days of stock-out'
       ELSE 'OK' END                                                                      AS at_port_status,
  a.open_shipment_ids,
  p.scenario_date,
  p.port_delay_days
FROM agg a CROSS JOIN params p;

-- 3. Lessons from all past disruptions, with ids for citation
CREATE OR REPLACE VIEW v_lessons
  COMMENT = 'Our past disruptions and what we learned. Cite event_id.'
AS
SELECT event_id, event_date, region, event_type, port_closed_days, shipments_delayed, cost_eur, lesson
FROM past_disruptions;

-- ============ CHECKS (run each with Ctrl+Enter) ============

-- C1. Risk calendar for Taiwan.
--     Expect: JUL 1.2 HIGH, AUG 1.3 HIGH, SEP 1.0 HIGH, JUN 0.6 MEDIUM, OCT 0.6 MEDIUM, FEB/APR/NOV 0.2 LOW, rest 0 LOW
SELECT month_no, month_name, closure_days, avg_closure_days_per_year, historical_risk
FROM v_risk_calendar WHERE region = 'TW-SOUTH' ORDER BY month_no;

-- C2. Exposure for Taiwan. Expect:
--   SKU-1001: cover 9,  at sea 6000, at port 5000, cover_with_in_transit 24, delayed ETA 2026-11-09, margin 6, OK
--   SKU-1002: cover 14, at sea 5000, at port 0,    cover_with_in_transit 34, NO STOCK HELD AT PORT
--   SKU-1003: cover 21, at sea 0,    at port 10500, stock-out 2026-11-12, delayed ETA 2026-11-10, margin 2, TIGHT  <- hidden risk
SELECT sku_id, days_of_cover, in_transit_qty, at_port_qty, cover_with_in_transit,
       stockout_date_with_in_transit, at_port_delayed_eta, at_port_margin_days, rule_status, at_port_status, open_shipment_ids
FROM v_exposure WHERE region = 'TW-SOUTH' ORDER BY sku_id;

-- C3. Money split for Taiwan. Expect: at port 615,000; at sea 585,000; total 1,200,000
SELECT SUM(at_port_value_eur) AS at_port, SUM(in_transit_value_eur) AS at_sea, SUM(open_value_eur) AS total
FROM v_exposure WHERE region = 'TW-SOUTH';

-- C4. Lessons. Expect 8 rows; typhoon lessons D-001, D-002, D-004, D-006, D-008
SELECT event_id, event_date, event_type, lesson FROM v_lessons ORDER BY event_date;

SELECT region, COUNT(*) FROM typhoon_history GROUP BY region;

-- Expect exactly these 7 regions, no other spellings:
-- CN-SOUTH, DE-NRW, MY-PENANG, PL-GDANSK, SE-GOTHENBURG, TW-SOUTH (+ NL-ROTTERDAM, GLOBAL, TW-NORTH only in news/lessons)
SELECT DISTINCT region FROM (
  SELECT region FROM suppliers UNION SELECT region FROM inventory UNION SELECT region FROM shipments
  UNION SELECT region FROM supplier_documents UNION SELECT region FROM news_feed
  UNION SELECT region FROM past_disruptions UNION SELECT region FROM typhoon_history UNION SELECT region FROM ports)
ORDER BY region;
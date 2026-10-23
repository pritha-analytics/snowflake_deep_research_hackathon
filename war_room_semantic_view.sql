-- War Room: step 6a. Semantic view for the INVENTORY_ANALYST sub-agent (Cortex Analyst tool).
-- Run after war_room_governance.sql, with Run All.
USE ROLE WAR_ROOM_ADMIN;
USE WAREHOUSE WAR_ROOM_WH;
USE SCHEMA WAR_ROOM.OPS;

CREATE OR REPLACE SEMANTIC VIEW SV_OPERATIONS
  TABLES (
    suppliers AS WAR_ROOM.OPS.SUPPLIERS
      PRIMARY KEY (supplier_id)
      COMMENT = 'Our suppliers and the region they ship from',
    exposure AS WAR_ROOM.OPS.V_EXPOSURE
      PRIMARY KEY (sku_id)
      WITH SYNONYMS = ('inventory', 'stock', 'SKUs', 'products', 'cover')
      COMMENT = 'One row per SKU: stock, demand, days of cover, open shipment exposure. Scenario date 2026-10-22. At-port delay assumption 10 days (alert A02 + clause 11.3).',
    shipments AS WAR_ROOM.OPS.SHIPMENTS
      PRIMARY KEY (shipment_id)
      COMMENT = 'Purchase order shipments, open and past',
    lessons AS WAR_ROOM.OPS.V_LESSONS
      PRIMARY KEY (event_id)
      COMMENT = 'Our past disruptions and lessons learned. Cite event_id.',
    risk_calendar AS WAR_ROOM.OPS.V_RISK_CALENDAR
      PRIMARY KEY (region, month_no)
      COMMENT = 'Simulated typhoon history by region and month'
  )
  RELATIONSHIPS (
    exposure_supplier AS exposure (supplier_id) REFERENCES suppliers,
    shipment_sku      AS shipments (sku_id)      REFERENCES exposure
  )
  FACTS (
    exposure.units_on_hand         AS units_on_hand,
    exposure.daily_demand          AS daily_demand,
    exposure.unit_cost_eur         AS unit_cost_eur COMMENT = 'Current unit price from the current supplier, EUR',
    exposure.days_of_cover         AS days_of_cover COMMENT = 'units_on_hand / daily_demand for one SKU',
    exposure.cover_with_in_transit AS cover_with_in_transit COMMENT = 'Days of cover counting stock already at sea',
    exposure.at_port_margin_days   AS at_port_margin_days COMMENT = 'Days between delayed arrival of at-port stock and stock-out. Small or negative = risk',
    exposure.at_port_value_eur     AS at_port_value_eur COMMENT = 'Value waiting at the origin port (stuck if the port closes)',
    exposure.in_transit_value_eur  AS in_transit_value_eur COMMENT = 'Value already at sea',
    shipments.qty                  AS qty,
    shipments.value_eur            AS value_eur,
    lessons.cost_eur               AS cost_eur,
    risk_calendar.avg_closure_days AS avg_closure_days_per_year
  )
  DIMENSIONS (
    suppliers.supplier_name   AS supplier_name WITH SYNONYMS = ('supplier', 'vendor'),
    suppliers.supplier_region AS region COMMENT = 'Region code, e.g. TW-SOUTH. Use the region code the news agent reports.',
    suppliers.risk_tier       AS risk_tier,
    suppliers.country         AS country,
    exposure.sku_id           AS sku_id,
    exposure.sku_name         AS sku_name,
    exposure.sku_region       AS region COMMENT = 'Region code of the SKU supplier',
    exposure.rule_status      AS rule_status COMMENT = 'BELOW 20-DAY RULE (D-006) when cover is under 20 days',
    exposure.at_port_status   AS at_port_status COMMENT = 'TIGHT or LATE when stock held at port arrives close to or after stock-out',
    exposure.stockout_date_with_in_transit AS stockout_date_with_in_transit,
    exposure.at_port_delayed_eta AS at_port_delayed_eta,
    exposure.open_shipment_ids AS open_shipment_ids COMMENT = 'Shipment ids to cite',
    shipments.shipment_id     AS shipment_id,
    shipments.status          AS status COMMENT = 'IN_TRANSIT = at sea. AT_PORT = waiting at origin port. DELAYED. DELIVERED.',
    shipments.eta             AS eta,
    shipments.origin_port     AS origin_port,
    shipments.shipment_region AS region,
    lessons.event_id          AS event_id,
    lessons.event_date        AS event_date,
    lessons.event_type        AS event_type,
    lessons.lesson_region     AS region,
    lessons.lesson            AS lesson,
    risk_calendar.calendar_region AS region,
    risk_calendar.month_no    AS month_no,
    risk_calendar.month_name  AS month_name,
    risk_calendar.historical_risk AS historical_risk,
    risk_calendar.data_source AS data_source COMMENT = 'SIMULATED: say so when quoting history'
  )
  METRICS (
    shipments.open_shipment_value AS SUM(IFF(shipments.status IN ('IN_TRANSIT', 'AT_PORT'), shipments.value_eur, 0))
      WITH SYNONYMS = ('open exposure', 'value at risk'),
    shipments.open_shipment_count AS COUNT_IF(shipments.status IN ('IN_TRANSIT', 'AT_PORT')),
    exposure.min_days_of_cover    AS MIN(exposure.days_of_cover),
    exposure.total_at_port_value  AS SUM(exposure.at_port_value_eur),
    exposure.total_in_transit_value AS SUM(exposure.in_transit_value_eur),
    lessons.total_disruption_cost AS SUM(lessons.cost_eur)
  )
  COMMENT = 'War Room operations: suppliers, stock cover, shipments, lessons, typhoon risk calendar. Simulated data.';

-- Access: the inventory agent and the two viewers
GRANT SELECT ON SEMANTIC VIEW SV_OPERATIONS TO ROLE AGENT_INVENTORY_ROLE;
GRANT SELECT ON SEMANTIC VIEW SV_OPERATIONS TO ROLE OPS_GLOBAL;
GRANT SELECT ON SEMANTIC VIEW SV_OPERATIONS TO ROLE OPS_EMEA;

-- Check: expect Formosa Chip Works = 1200000 (other suppliers smaller or 0)
SELECT * FROM SEMANTIC_VIEW(
  SV_OPERATIONS
  DIMENSIONS suppliers.supplier_name
  METRICS shipments.open_shipment_value
) ORDER BY open_shipment_value DESC;
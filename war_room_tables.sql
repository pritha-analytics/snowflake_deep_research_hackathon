-- War Room: step 1 of 5. Creates admin role, warehouse, database and 10 empty tables.
-- Run order: tables -> data -> analysis -> governance -> checks.
-- WARNING: CREATE OR REPLACE wipes data and detaches policies. If you re-run this file, re-run the whole chain.
-- All names, events and numbers are fictional.

-- 1. Admin role and warehouse (run as ACCOUNTADMIN)
-- USE ROLE ACCOUNTADMIN;
-- DROP DATABASE IF EXISTS WAR_ROOM;   -- clean start: old tables were owned by ACCOUNTADMIN
USE ROLE ACCOUNTADMIN;
CREATE ROLE IF NOT EXISTS WAR_ROOM_ADMIN COMMENT = 'Owns War Room objects, runs checks, owns search services';
GRANT ROLE WAR_ROOM_ADMIN TO ROLE SYSADMIN;            -- keeps the role hierarchy clean
SET my_user = CURRENT_USER();
GRANT ROLE WAR_ROOM_ADMIN TO USER IDENTIFIER($my_user);
GRANT CREATE DATABASE ON ACCOUNT TO ROLE WAR_ROOM_ADMIN;

CREATE WAREHOUSE IF NOT EXISTS WAR_ROOM_WH
  WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE;
GRANT USAGE ON WAREHOUSE WAR_ROOM_WH TO ROLE WAR_ROOM_ADMIN;

-- 2. Everything below is owned by WAR_ROOM_ADMIN
USE ROLE WAR_ROOM_ADMIN;
USE WAREHOUSE WAR_ROOM_WH;
CREATE DATABASE IF NOT EXISTS WAR_ROOM;
CREATE SCHEMA IF NOT EXISTS WAR_ROOM.OPS;
USE SCHEMA WAR_ROOM.OPS;

-- Source 1: structured (internal, region-restricted in step 4)
CREATE OR REPLACE TABLE suppliers (
  supplier_id   STRING COMMENT 'Supplier key, e.g. S01',
  supplier_name STRING,
  country       STRING,
  region        STRING COMMENT 'Region code, e.g. TW-SOUTH. Same codes in all tables. Drives row-level access.',
  risk_tier     STRING COMMENT 'HIGH | MEDIUM | LOW',
  contact_email STRING,
  port_id       STRING COMMENT 'Joins to ports.port_id'
) COMMENT = 'Our suppliers and the region they ship from';

CREATE OR REPLACE TABLE inventory (
  sku_id        STRING COMMENT 'Product key, e.g. SKU-1001',
  sku_name      STRING,
  supplier_id   STRING COMMENT 'Joins to suppliers.supplier_id (single source per SKU)',
  region        STRING COMMENT 'Region of the supplier',
  warehouse     STRING COMMENT 'Our warehouse, e.g. GOT-DC1 (Gothenburg)',
  units_on_hand NUMBER COMMENT 'Stock on hand',
  daily_demand  NUMBER COMMENT 'Units used per day',
  unit_cost_eur NUMBER(10,2) COMMENT 'Current unit price from the supplier, EUR',
  reorder_point NUMBER
) COMMENT = 'Stock and demand per SKU';

CREATE OR REPLACE TABLE shipments (
  shipment_id  STRING COMMENT 'Shipment key, e.g. SH-001',
  po_number    STRING,
  sku_id       STRING COMMENT 'Joins to inventory.sku_id',
  supplier_id  STRING COMMENT 'Joins to suppliers.supplier_id',
  region       STRING COMMENT 'Region the shipment leaves from',
  qty          NUMBER,
  value_eur    NUMBER(14,2),
  ship_date    DATE,
  eta          DATE COMMENT 'Expected arrival at our warehouse',
  status       STRING COMMENT 'IN_TRANSIT (at sea) | AT_PORT (waiting at origin port) | DELAYED | DELIVERED',
  origin_port  STRING
) COMMENT = 'Purchase order shipments, open and past';

-- Source 2: unstructured (internal, region-restricted in step 4)
CREATE OR REPLACE TABLE supplier_documents (
  doc_id      STRING COMMENT 'Document key, e.g. D01. Cite this.',
  supplier_id STRING,
  region      STRING,
  doc_type    STRING COMMENT 'CONTRACT | EMAIL | QUOTE',
  file_name   STRING COMMENT 'Original file name. Cite this.',
  doc_date    DATE,
  content     STRING COMMENT 'Full text, indexed by Cortex Search'
) COMMENT = 'Simulated supplier contracts, emails and quotes';

-- Source 3: external (public, not restricted)
CREATE OR REPLACE TABLE news_feed (
  alert_id     STRING COMMENT 'Alert key, e.g. A01. Cite this.',
  published_at TIMESTAMP_NTZ,
  source       STRING,
  region       STRING COMMENT 'Affected region, or GLOBAL',
  event_type   STRING COMMENT 'WEATHER | PORT | LOGISTICS | LABOR | ...',
  severity     STRING COMMENT 'HIGH | MEDIUM | LOW',
  headline     STRING,
  body         STRING
) COMMENT = 'Simulated external news and disruption alerts';

-- History and map (shared knowledge, not restricted)
CREATE OR REPLACE TABLE typhoon_history (
  typhoon_year      NUMBER,
  typhoon_month     NUMBER,
  region            STRING COMMENT 'TW-SOUTH',
  warnings_issued   NUMBER,
  landfalls         NUMBER,
  port_closure_days NUMBER,
  data_source       STRING COMMENT 'SIMULATED'
) COMMENT = 'Simulated monthly typhoon activity 2016-2025';

CREATE OR REPLACE TABLE past_disruptions (
  event_id          STRING COMMENT 'Event key, e.g. D-006. Cite this.',
  event_date        DATE,
  region            STRING,
  event_type        STRING COMMENT 'TYPHOON | STRIKE | FLOOD | LOCKDOWN',
  port_closed_days  NUMBER,
  shipments_delayed NUMBER,
  cost_eur          NUMBER(14,2),
  lesson            STRING COMMENT 'What we learned'
) COMMENT = 'Our own past incidents and lessons learned';

CREATE OR REPLACE TABLE ports (
  port_id STRING, port_name STRING, country STRING, region STRING, latitude FLOAT, longitude FLOAT
) COMMENT = 'Supplier ports, for the map';

CREATE OR REPLACE TABLE typhoon_track (
  track_id STRING, point_order NUMBER, observed_at TIMESTAMP_NTZ, latitude FLOAT, longitude FLOAT, wind_kph NUMBER
) COMMENT = 'Storm path of Typhoon Meilin, for the map';

-- Access map: which viewer role may see which region (used by the policy in step 4)
CREATE OR REPLACE TABLE viewer_region_access (
  role_name STRING COMMENT 'Viewer role, e.g. OPS_EMEA',
  region    STRING
) COMMENT = 'Row-level access map: viewer role to region';

-- Check: expect 10 rows
SHOW TABLES IN SCHEMA WAR_ROOM.OPS;

--DROP VIEW IF EXISTS WAR_ROOM.OPS.TYPHOON_HISTORY;
--SHOW OBJECTS LIKE 'TYPHOON_HISTORY%' IN SCHEMA WAR_ROOM.OPS;
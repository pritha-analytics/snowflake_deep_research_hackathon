-- War Room: step 4 of 5. Governance: roles, row access policy, grants, search services.
-- Run after war_room_analysis.sql. Run All runs the setup and stops at T3 (an expected error). Run tests block by block.check where 

-- ============ A. Roles and account-level grants (ACCOUNTADMIN) ============
USE ROLE ACCOUNTADMIN;

-- Viewer roles: the people who open the brief
CREATE ROLE IF NOT EXISTS OPS_GLOBAL COMMENT = 'Viewer: sees all regions';
CREATE ROLE IF NOT EXISTS OPS_EMEA   COMMENT = 'Viewer: sees EMEA regions only';

-- Agent roles: one identity per sub-agent, least privilege
CREATE ROLE IF NOT EXISTS AGENT_NEWS_ROLE      COMMENT = 'Sub-agent NEWS_SCOUT: external news only';
CREATE ROLE IF NOT EXISTS AGENT_INVENTORY_ROLE COMMENT = 'Sub-agent INVENTORY_ANALYST: structured inventory data only';
CREATE ROLE IF NOT EXISTS AGENT_CONTRACTS_ROLE COMMENT = 'Sub-agent CONTRACT_ANALYST: supplier document search only';

-- Keep the hierarchy clean and give yourself the roles for testing
GRANT ROLE OPS_GLOBAL, OPS_EMEA TO ROLE SYSADMIN;
GRANT ROLE AGENT_NEWS_ROLE, AGENT_INVENTORY_ROLE, AGENT_CONTRACTS_ROLE TO ROLE SYSADMIN;
SET my_user = CURRENT_USER();
GRANT ROLE OPS_GLOBAL           TO USER IDENTIFIER($my_user);
GRANT ROLE OPS_EMEA             TO USER IDENTIFIER($my_user);
GRANT ROLE AGENT_NEWS_ROLE      TO USER IDENTIFIER($my_user);
GRANT ROLE AGENT_INVENTORY_ROLE TO USER IDENTIFIER($my_user);
GRANT ROLE AGENT_CONTRACTS_ROLE TO USER IDENTIFIER($my_user);

-- Warehouse and Cortex access for every role
GRANT USAGE ON WAREHOUSE WAR_ROOM_WH TO ROLE OPS_GLOBAL;
GRANT USAGE ON WAREHOUSE WAR_ROOM_WH TO ROLE OPS_EMEA;
GRANT USAGE ON WAREHOUSE WAR_ROOM_WH TO ROLE AGENT_NEWS_ROLE;
GRANT USAGE ON WAREHOUSE WAR_ROOM_WH TO ROLE AGENT_INVENTORY_ROLE;
GRANT USAGE ON WAREHOUSE WAR_ROOM_WH TO ROLE AGENT_CONTRACTS_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE OPS_GLOBAL;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE OPS_EMEA;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE AGENT_NEWS_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE AGENT_INVENTORY_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE AGENT_CONTRACTS_ROLE;

-- ============ B. Policy, object grants, search services (WAR_ROOM_ADMIN) ============
USE ROLE WAR_ROOM_ADMIN;
USE WAREHOUSE WAR_ROOM_WH;
USE SCHEMA WAR_ROOM.OPS;

-- B1. Row access policy (detach first so this file can be re-run)
ALTER TABLE suppliers          DROP ALL ROW ACCESS POLICIES;
ALTER TABLE inventory          DROP ALL ROW ACCESS POLICIES;
ALTER TABLE shipments          DROP ALL ROW ACCESS POLICIES;
ALTER TABLE supplier_documents DROP ALL ROW ACCESS POLICIES;

-- A viewer as primary role sees only its own regions, even if secondary roles (e.g. WAR_ROOM_ADMIN) are active.
CREATE OR REPLACE ROW ACCESS POLICY region_policy AS (r STRING) RETURNS BOOLEAN ->
  CASE
    WHEN STARTSWITH(CURRENT_ROLE(), 'OPS_') THEN EXISTS (
      SELECT 1 FROM WAR_ROOM.OPS.viewer_region_access v WHERE v.region = r AND v.role_name = CURRENT_ROLE())
    WHEN IS_ROLE_IN_SESSION('WAR_ROOM_ADMIN') THEN TRUE      -- admin and checks see everything
    ELSE EXISTS (SELECT 1 FROM WAR_ROOM.OPS.viewer_region_access v
                 WHERE v.region = r AND IS_ROLE_IN_SESSION(v.role_name))
  END
  COMMENT = 'Internal data: a role sees only the regions listed for it in viewer_region_access';

-- Internal data only. news_feed, typhoon_history, past_disruptions, ports, typhoon_track stay public.
ALTER TABLE suppliers          ADD ROW ACCESS POLICY region_policy ON (region);
ALTER TABLE inventory          ADD ROW ACCESS POLICY region_policy ON (region);
ALTER TABLE shipments          ADD ROW ACCESS POLICY region_policy ON (region);
ALTER TABLE supplier_documents ADD ROW ACCESS POLICY region_policy ON (region);

-- PLAN B (decide after the identity check): if sub-agents run as their OWN role instead of the viewer's,
-- they need region access here, and per-viewer filtering then comes from the CoWork Artifact permissions.
-- INSERT INTO viewer_region_access SELECT 'AGENT_INVENTORY_ROLE', region FROM viewer_region_access WHERE role_name = 'OPS_GLOBAL';
-- INSERT INTO viewer_region_access SELECT 'AGENT_CONTRACTS_ROLE', region FROM viewer_region_access WHERE role_name = 'OPS_GLOBAL';

-- B2. Database and schema usage for everyone
GRANT USAGE ON DATABASE WAR_ROOM TO ROLE OPS_GLOBAL;
GRANT USAGE ON DATABASE WAR_ROOM TO ROLE OPS_EMEA;
GRANT USAGE ON DATABASE WAR_ROOM TO ROLE AGENT_NEWS_ROLE;
GRANT USAGE ON DATABASE WAR_ROOM TO ROLE AGENT_INVENTORY_ROLE;
GRANT USAGE ON DATABASE WAR_ROOM TO ROLE AGENT_CONTRACTS_ROLE;
GRANT USAGE ON SCHEMA WAR_ROOM.OPS TO ROLE OPS_GLOBAL;
GRANT USAGE ON SCHEMA WAR_ROOM.OPS TO ROLE OPS_EMEA;
GRANT USAGE ON SCHEMA WAR_ROOM.OPS TO ROLE AGENT_NEWS_ROLE;
GRANT USAGE ON SCHEMA WAR_ROOM.OPS TO ROLE AGENT_INVENTORY_ROLE;
GRANT USAGE ON SCHEMA WAR_ROOM.OPS TO ROLE AGENT_CONTRACTS_ROLE;

-- B3. Viewers: read all tables and views (rows are filtered by the policy), but not the access map itself
GRANT SELECT ON ALL TABLES IN SCHEMA WAR_ROOM.OPS TO ROLE OPS_GLOBAL;
GRANT SELECT ON ALL TABLES IN SCHEMA WAR_ROOM.OPS TO ROLE OPS_EMEA;
GRANT SELECT ON ALL VIEWS  IN SCHEMA WAR_ROOM.OPS TO ROLE OPS_GLOBAL;
GRANT SELECT ON ALL VIEWS  IN SCHEMA WAR_ROOM.OPS TO ROLE OPS_EMEA;
REVOKE SELECT ON TABLE viewer_region_access FROM ROLE OPS_GLOBAL;
REVOKE SELECT ON TABLE viewer_region_access FROM ROLE OPS_EMEA;

-- B4. Agents: least privilege, each only its own source
GRANT SELECT ON TABLE news_feed TO ROLE AGENT_NEWS_ROLE;

GRANT SELECT ON TABLE suppliers       TO ROLE AGENT_INVENTORY_ROLE;
GRANT SELECT ON TABLE inventory       TO ROLE AGENT_INVENTORY_ROLE;
GRANT SELECT ON TABLE shipments       TO ROLE AGENT_INVENTORY_ROLE;
GRANT SELECT ON VIEW  v_exposure      TO ROLE AGENT_INVENTORY_ROLE;
GRANT SELECT ON VIEW  v_lessons       TO ROLE AGENT_INVENTORY_ROLE;
GRANT SELECT ON VIEW  v_risk_calendar TO ROLE AGENT_INVENTORY_ROLE;
-- AGENT_CONTRACTS_ROLE gets no table access at all: only the search service (B5)

-- B5. Search services, owned by WAR_ROOM_ADMIN so the index holds every document
CREATE OR REPLACE CORTEX SEARCH SERVICE SUPPLIER_DOCS_SEARCH
  ON content
  ATTRIBUTES supplier_id, region, doc_type
  WAREHOUSE = WAR_ROOM_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'Contract clauses, supplier emails and quotes. Cite doc_id and file_name.'
  AS (
    SELECT doc_id, supplier_id, region, doc_type, file_name,
           TO_VARCHAR(doc_date) AS doc_date, content
    FROM supplier_documents
  );

CREATE OR REPLACE CORTEX SEARCH SERVICE NEWS_SEARCH
  ON search_text
  ATTRIBUTES region, severity, event_type
  WAREHOUSE = WAR_ROOM_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'External disruption alerts. Cite alert_id.'
  AS (
    SELECT alert_id, region, severity, event_type, source, headline,
           TO_VARCHAR(published_at) AS published_at,
           headline || '. ' || body AS search_text
    FROM news_feed
  );

-- B6. EMEA-only document search. Cortex Search does not apply the row policy,
--     so EMEA gets its own service and no access to the full one.
CREATE OR REPLACE CORTEX SEARCH SERVICE SUPPLIER_DOCS_SEARCH_EMEA
  ON content
  ATTRIBUTES supplier_id, region, doc_type
  WAREHOUSE = WAR_ROOM_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'EMEA supplier documents only (PL-GDANSK, DE-NRW, SE-GOTHENBURG)'
  AS (
    SELECT doc_id, supplier_id, region, doc_type, file_name, TO_VARCHAR(doc_date) AS doc_date, content
    FROM supplier_documents
    WHERE region IN ('PL-GDANSK', 'DE-NRW', 'SE-GOTHENBURG')
  );

-- B7. Search grants
--     News: everyone.  Full docs: GLOBAL + contracts agent.  EMEA docs: EMEA + contracts agent.
GRANT USAGE ON CORTEX SEARCH SERVICE NEWS_SEARCH               TO ROLE AGENT_NEWS_ROLE;
GRANT USAGE ON CORTEX SEARCH SERVICE NEWS_SEARCH               TO ROLE OPS_GLOBAL;
GRANT USAGE ON CORTEX SEARCH SERVICE NEWS_SEARCH               TO ROLE OPS_EMEA;
GRANT USAGE ON CORTEX SEARCH SERVICE SUPPLIER_DOCS_SEARCH      TO ROLE AGENT_CONTRACTS_ROLE;
GRANT USAGE ON CORTEX SEARCH SERVICE SUPPLIER_DOCS_SEARCH      TO ROLE OPS_GLOBAL;
GRANT USAGE ON CORTEX SEARCH SERVICE SUPPLIER_DOCS_SEARCH_EMEA TO ROLE AGENT_CONTRACTS_ROLE;
GRANT USAGE ON CORTEX SEARCH SERVICE SUPPLIER_DOCS_SEARCH_EMEA TO ROLE OPS_EMEA;
REVOKE USAGE ON CORTEX SEARCH SERVICE SUPPLIER_DOCS_SEARCH     FROM ROLE OPS_EMEA;   -- safety: EMEA never gets the full index

-- Check: expect 3 services (NEWS_SEARCH, SUPPLIER_DOCS_SEARCH, SUPPLIER_DOCS_SEARCH_EMEA)
SHOW CORTEX SEARCH SERVICES IN SCHEMA WAR_ROOM.OPS;

-- ================== TESTS ==================
-- Run each test block on its own: select the whole block, then Ctrl+Enter.
-- Run All stops at T3 (an expected error), so do not use Run All for the tests.

-- T0. Session check as EMEA. Expect: OPS_EMEA, empty secondary, FALSE, 0
USE SECONDARY ROLES NONE;
USE ROLE OPS_EMEA;
SELECT CURRENT_ROLE()                       AS role_now,
       CURRENT_SECONDARY_ROLES()            AS secondary,
       IS_ROLE_IN_SESSION('WAR_ROOM_ADMIN') AS admin_active,
       (SELECT COUNT(*) FROM WAR_ROOM.OPS.shipments WHERE region = 'TW-SOUTH') AS tw_shipments;

-- T1. As EMEA. Expect: tw_shipments 0, docs D03,D06,D07,D09,D10, tw_exposure 0, tw_news 3
USE SECONDARY ROLES NONE;
USE ROLE OPS_EMEA;
SELECT (SELECT COUNT(*) FROM WAR_ROOM.OPS.shipments  WHERE region = 'TW-SOUTH') AS tw_shipments,
       (SELECT LISTAGG(doc_id, ',') WITHIN GROUP (ORDER BY doc_id) FROM WAR_ROOM.OPS.supplier_documents) AS docs,
       (SELECT COUNT(*) FROM WAR_ROOM.OPS.v_exposure WHERE region = 'TW-SOUTH') AS tw_exposure,
       (SELECT COUNT(*) FROM WAR_ROOM.OPS.news_feed  WHERE region = 'TW-SOUTH') AS tw_news;

-- T2. As GLOBAL. Expect: 6, 3
USE SECONDARY ROLES NONE;
USE ROLE OPS_GLOBAL;
SELECT (SELECT COUNT(*) FROM WAR_ROOM.OPS.shipments  WHERE region = 'TW-SOUTH') AS tw_shipments,
       (SELECT COUNT(*) FROM WAR_ROOM.OPS.v_exposure WHERE region = 'TW-SOUTH') AS tw_exposure;

-- T3. Contracts agent cannot read tables. Expect: ERROR (that is the pass)
USE SECONDARY ROLES NONE;
USE ROLE AGENT_CONTRACTS_ROLE;
SELECT COUNT(*) FROM WAR_ROOM.OPS.shipments;

-- T4a. News agent reads news. Expect: 20
USE SECONDARY ROLES NONE;
USE ROLE AGENT_NEWS_ROLE;
SELECT COUNT(*) AS news FROM WAR_ROOM.OPS.news_feed;

-- T4b. News agent cannot read inventory. Expect: ERROR (that is the pass)
USE SECONDARY ROLES NONE;
USE ROLE AGENT_NEWS_ROLE;
SELECT COUNT(*) FROM WAR_ROOM.OPS.inventory;

-- T5. EMEA cannot use the full document search. Expect: ERROR "does not exist or access is not authorized"
USE SECONDARY ROLES NONE;
USE ROLE OPS_EMEA;
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW('WAR_ROOM.OPS.SUPPLIER_DOCS_SEARCH',
  '{"query": "expedited shipping during typhoon", "columns": ["doc_id","region"], "limit": 3}');

-- T5b. EMEA uses its own document search. Expect: only PL-GDANSK / DE-NRW documents, no TW-SOUTH or MY-PENANG
USE SECONDARY ROLES NONE;
USE ROLE OPS_EMEA;
SELECT r.index + 1 AS rank, r.value:doc_id::STRING AS doc_id, r.value:region::STRING AS region
FROM TABLE(FLATTEN(INPUT => PARSE_JSON(SNOWFLAKE.CORTEX.SEARCH_PREVIEW('WAR_ROOM.OPS.SUPPLIER_DOCS_SEARCH_EMEA',
  '{"query": "late delivery penalty", "columns": ["doc_id","region"], "limit": 5}')):results)) r;

-- T6. Full docs search finds clause 7.2. Expect: D01 at rank 1
USE ROLE WAR_ROOM_ADMIN;
SELECT r.index + 1 AS rank, r.value:doc_id::STRING AS doc_id, r.value:file_name::STRING AS file_name
FROM TABLE(FLATTEN(INPUT => PARSE_JSON(SNOWFLAKE.CORTEX.SEARCH_PREVIEW('WAR_ROOM.OPS.SUPPLIER_DOCS_SEARCH',
  '{"query": "expedited shipping at buyer cost", "columns": ["doc_id","file_name"], "limit": 3}')):results)) r;

-- T7. Full docs search finds the Penang quote. Expect: D08 at rank 1
USE ROLE WAR_ROOM_ADMIN;
SELECT r.index + 1 AS rank, r.value:doc_id::STRING AS doc_id, r.value:file_name::STRING AS file_name
FROM TABLE(FLATTEN(INPUT => PARSE_JSON(SNOWFLAKE.CORTEX.SEARCH_PREVIEW('WAR_ROOM.OPS.SUPPLIER_DOCS_SEARCH',
  '{"query": "alternative supplier capacity lead time unit cost", "columns": ["doc_id","file_name"], "limit": 3}')):results)) r;

-- T8. News search. Expect: A01, A02, A03 (HIGH, TW-SOUTH) in the top 3
USE ROLE WAR_ROOM_ADMIN;
SELECT r.index + 1 AS rank, r.value:alert_id::STRING AS alert_id, r.value:severity::STRING AS severity, r.value:region::STRING AS region
FROM TABLE(FLATTEN(INPUT => PARSE_JSON(SNOWFLAKE.CORTEX.SEARCH_PREVIEW('WAR_ROOM.OPS.NEWS_SEARCH',
  '{"query": "typhoon Kaohsiung port closure", "columns": ["alert_id","severity","region"], "limit": 5}')):results)) r;

-- Back to normal
USE ROLE ACCOUNTADMIN;
USE SECONDARY ROLES ALL;


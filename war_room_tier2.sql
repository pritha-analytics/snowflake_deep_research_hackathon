-- War Room: Tier 2 (RISK_HISTORIAN, OPS_APAC, audit). Run after war_room_agents.sql.
-- Agent spec edits (WAR_ROOM_LEAD 4th toolset, INVENTORY_ANALYST trimmed, CONTRACT_ANALYST + APAC/EMEA search)
-- were saved and published with the agent-studio CLI; see each agent's live version.

-- ============ A. Roles (ACCOUNTADMIN) ============
USE ROLE ACCOUNTADMIN;
CREATE ROLE IF NOT EXISTS AGENT_HISTORIAN_ROLE COMMENT = 'Sub-agent RISK_HISTORIAN: lessons and risk calendar only';
CREATE ROLE IF NOT EXISTS OPS_APAC COMMENT = 'Viewer: sees APAC regions only (TW-SOUTH, MY-PENANG, CN-SOUTH)';
GRANT ROLE AGENT_HISTORIAN_ROLE, OPS_APAC TO ROLE SYSADMIN;
SET my_user = CURRENT_USER();
GRANT ROLE AGENT_HISTORIAN_ROLE TO USER IDENTIFIER($my_user);
GRANT ROLE OPS_APAC             TO USER IDENTIFIER($my_user);
GRANT USAGE ON WAREHOUSE WAR_ROOM_WH TO ROLE AGENT_HISTORIAN_ROLE;
GRANT USAGE ON WAREHOUSE WAR_ROOM_WH TO ROLE OPS_APAC;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE AGENT_HISTORIAN_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE OPS_APAC;

-- ============ B. RISK_HISTORIAN (WAR_ROOM_ADMIN) ============
USE ROLE WAR_ROOM_ADMIN;
USE WAREHOUSE WAR_ROOM_WH;
USE SCHEMA WAR_ROOM.OPS;

CREATE OR REPLACE SEMANTIC VIEW SV_HISTORY
  TABLES (
    lessons AS WAR_ROOM.OPS.V_LESSONS
      PRIMARY KEY (event_id)
      WITH SYNONYMS = ('past disruptions', 'lessons learned', 'history')
      COMMENT = 'Our past disruptions and lessons learned. Cite event_id. Simulated.',
    risk_calendar AS WAR_ROOM.OPS.V_RISK_CALENDAR
      PRIMARY KEY (region, month_no)
      WITH SYNONYMS = ('risk calendar', 'typhoon season', 'risk month')
      COMMENT = 'Simulated typhoon history by region and month'
  )
  FACTS (
    lessons.cost_eur AS cost_eur COMMENT = 'Cost of the disruption, EUR',
    lessons.port_closed_days AS port_closed_days,
    lessons.shipments_delayed AS shipments_delayed,
    risk_calendar.warnings AS warnings,
    risk_calendar.closure_days AS closure_days,
    risk_calendar.avg_closure_days AS avg_closure_days_per_year
  )
  DIMENSIONS (
    lessons.event_id AS event_id COMMENT = 'Lesson id to cite, e.g. D-006',
    lessons.event_date AS event_date,
    lessons.event_type AS event_type,
    lessons.lesson_region AS region COMMENT = 'Region code, e.g. TW-SOUTH',
    lessons.lesson AS lesson,
    risk_calendar.calendar_region AS region COMMENT = 'Region code, e.g. TW-SOUTH',
    risk_calendar.month_no AS month_no,
    risk_calendar.month_name AS month_name,
    risk_calendar.historical_risk AS historical_risk COMMENT = 'HIGH, MEDIUM or LOW',
    risk_calendar.data_source AS data_source COMMENT = 'SIMULATED: say so when quoting history'
  )
  METRICS (
    lessons.total_disruption_cost AS SUM(lessons.cost_eur),
    lessons.disruption_count AS COUNT(lessons.event_id),
    risk_calendar.total_closure_days AS SUM(risk_calendar.closure_days)
  )
  COMMENT = 'War Room history only: past disruptions, lessons and the typhoon risk calendar. Simulated data.';

-- Historian: only the two history views
GRANT USAGE ON DATABASE WAR_ROOM TO ROLE AGENT_HISTORIAN_ROLE;
GRANT USAGE ON SCHEMA WAR_ROOM.OPS TO ROLE AGENT_HISTORIAN_ROLE;
GRANT SELECT ON VIEW v_lessons       TO ROLE AGENT_HISTORIAN_ROLE;
GRANT SELECT ON VIEW v_risk_calendar TO ROLE AGENT_HISTORIAN_ROLE;
GRANT SELECT ON SEMANTIC VIEW SV_HISTORY TO ROLE AGENT_HISTORIAN_ROLE;
GRANT SELECT ON SEMANTIC VIEW SV_HISTORY TO ROLE OPS_GLOBAL;
GRANT SELECT ON SEMANTIC VIEW SV_HISTORY TO ROLE OPS_EMEA;

CREATE OR REPLACE AGENT WAR_ROOM.OPS.RISK_HISTORIAN
  COMMENT = 'War Room sub-agent: past disruptions, lessons learned and the typhoon risk calendar only'
  PROFILE = '{"display_name": "Risk Historian"}'
  FROM SPECIFICATION
$$
models:
  orchestration: auto
instructions:
  response: |
    You are the risk historian in the war room for Nordlys Electronics AB, a fictional company.
    - You receive one or more region codes, for example TW-SOUTH. Always filter on those codes.
    - Report: lessons from past disruptions in that region (event id, date, closure days, cost in EUR, lesson); the historical risk for this month (October) and the riskiest months of the year.
    - Quote the source for each claim, for example [lesson D-006] or [risk calendar TW-SOUTH Oct].
    - History is simulated. Say so.
    - You cannot see stock, shipments or contracts. Do not comment on them.
    - If a query returns no rows, say so. Never invent numbers.
  sample_questions:
    - question: "Which lessons and risk months apply to TW-SOUTH?"
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: SV_HISTORY
      description: "History only. Past disruptions with event id, date, port closure days, cost and lesson learned, and the simulated typhoon risk calendar by region and month. Use for lessons and risk-month questions."
tool_resources:
  SV_HISTORY:
    semantic_view: WAR_ROOM.OPS.SV_HISTORY
    execution_environment:
      type: warehouse
      warehouse: WAR_ROOM_WH
$$;
GRANT USAGE ON AGENT WAR_ROOM.OPS.RISK_HISTORIAN TO ROLE AGENT_HISTORIAN_ROLE;
GRANT USAGE ON AGENT WAR_ROOM.OPS.RISK_HISTORIAN TO ROLE OPS_GLOBAL;
GRANT USAGE ON AGENT WAR_ROOM.OPS.RISK_HISTORIAN TO ROLE OPS_EMEA;

-- ============ C. OPS_APAC viewer ============
DELETE FROM viewer_region_access WHERE role_name = 'OPS_APAC';
INSERT INTO viewer_region_access (role_name, region) VALUES ('OPS_APAC','TW-SOUTH'),('OPS_APAC','MY-PENANG'),('OPS_APAC','CN-SOUTH');

-- Cortex Search ignores the row policy, so APAC gets its own index (same pattern as EMEA)
CREATE OR REPLACE CORTEX SEARCH SERVICE SUPPLIER_DOCS_SEARCH_APAC
  ON content
  ATTRIBUTES supplier_id, region, doc_type
  WAREHOUSE = WAR_ROOM_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'APAC supplier documents only (TW-SOUTH, MY-PENANG, CN-SOUTH)'
  AS (
    SELECT doc_id, supplier_id, region, doc_type, file_name, TO_VARCHAR(doc_date) AS doc_date, content
    FROM WAR_ROOM.OPS.supplier_documents
    WHERE region IN ('TW-SOUTH', 'MY-PENANG', 'CN-SOUTH')
  );

GRANT USAGE ON DATABASE WAR_ROOM TO ROLE OPS_APAC;
GRANT USAGE ON SCHEMA WAR_ROOM.OPS TO ROLE OPS_APAC;
GRANT SELECT ON ALL TABLES IN SCHEMA WAR_ROOM.OPS TO ROLE OPS_APAC;
GRANT SELECT ON ALL VIEWS  IN SCHEMA WAR_ROOM.OPS TO ROLE OPS_APAC;
REVOKE SELECT ON TABLE viewer_region_access FROM ROLE OPS_APAC;
GRANT SELECT ON SEMANTIC VIEW SV_OPERATIONS TO ROLE OPS_APAC;
GRANT SELECT ON SEMANTIC VIEW SV_HISTORY    TO ROLE OPS_APAC;
GRANT USAGE ON CORTEX SEARCH SERVICE NEWS_SEARCH               TO ROLE OPS_APAC;
GRANT USAGE ON CORTEX SEARCH SERVICE SUPPLIER_DOCS_SEARCH_APAC TO ROLE OPS_APAC;
GRANT USAGE ON CORTEX SEARCH SERVICE SUPPLIER_DOCS_SEARCH_APAC TO ROLE AGENT_CONTRACTS_ROLE;
REVOKE USAGE ON CORTEX SEARCH SERVICE SUPPLIER_DOCS_SEARCH     FROM ROLE OPS_APAC;   -- safety: APAC never gets the full index
GRANT USAGE ON AGENT WAR_ROOM.OPS.WAR_ROOM_LEAD     TO ROLE OPS_APAC;
GRANT USAGE ON AGENT WAR_ROOM.OPS.NEWS_SCOUT        TO ROLE OPS_APAC;
GRANT USAGE ON AGENT WAR_ROOM.OPS.INVENTORY_ANALYST TO ROLE OPS_APAC;
GRANT USAGE ON AGENT WAR_ROOM.OPS.CONTRACT_ANALYST  TO ROLE OPS_APAC;
GRANT USAGE ON AGENT WAR_ROOM.OPS.RISK_HISTORIAN    TO ROLE OPS_APAC;

-- ============ D. Audit (chain of custody) ============
-- Source: Cortex Agent observability events. Viewer role is joined from the request span via thread_id.
CREATE OR REPLACE VIEW V_AGENT_AUDIT
  COMMENT = 'Chain of custody: every tool call by a War Room agent, with the viewer role, sub-agent, tool and object touched. Source: SNOWFLAKE.LOCAL AI observability events.'
AS
WITH ev AS (
  SELECT * FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_OBSERVABILITY_EVENTS('WAR_ROOM','OPS','WAR_ROOM_LEAD','CORTEX AGENT'))
  UNION ALL SELECT * FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_OBSERVABILITY_EVENTS('WAR_ROOM','OPS','NEWS_SCOUT','CORTEX AGENT'))
  UNION ALL SELECT * FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_OBSERVABILITY_EVENTS('WAR_ROOM','OPS','INVENTORY_ANALYST','CORTEX AGENT'))
  UNION ALL SELECT * FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_OBSERVABILITY_EVENTS('WAR_ROOM','OPS','CONTRACT_ANALYST','CORTEX AGENT'))
  UNION ALL SELECT * FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_OBSERVABILITY_EVENTS('WAR_ROOM','OPS','RISK_HISTORIAN','CORTEX AGENT'))
),
req AS (
  SELECT record_attributes:"snow.ai.observability.agent.thread_id"::STRING thread_id,
         ANY_VALUE(record_attributes:"snow.ai.observability.role.name"::STRING) viewer_role,
         ANY_VALUE(record_attributes:"snow.ai.observability.user.name"::STRING) user_name
  FROM ev WHERE record:name::STRING = 'CORTEX_AGENT_REQUEST' GROUP BY 1
),
calls AS (
  SELECT CONVERT_TIMEZONE('UTC','Europe/Stockholm', timestamp::TIMESTAMP_NTZ) event_time,
         trace:trace_id::STRING trace_id,
         record_attributes:"snow.ai.observability.agent.thread_id"::STRING thread_id,
         record_attributes:"snow.ai.observability.object.name"::STRING called_agent,
         IFF(record:name::STRING LIKE 'CortexSearchService_%', 'Cortex Search', 'Cortex Analyst') tool_type,
         COALESCE(SPLIT_PART(record_attributes:"snow.ai.observability.agent.tool.cortex_search.name"::STRING, '.', 3),
                  record_attributes:"snow.ai.observability.agent.tool.sql_execution.analyst_tool_name"::STRING) tool,
         record_attributes:"snow.ai.observability.agent.tool.sql_execution.final_sql"::STRING final_sql
  FROM ev
  WHERE record:name::STRING LIKE 'CortexSearchService_%' OR record:name::STRING = 'SystemExecuteSQLTool_system_execute_sql'
)
SELECT c.event_time, c.trace_id, c.thread_id, r.viewer_role, r.user_name, c.called_agent,
       CASE WHEN c.tool = 'NEWS_SEARCH' THEN 'NEWS_SCOUT'
            WHEN c.tool LIKE 'SUPPLIER_DOCS_SEARCH%' THEN 'CONTRACT_ANALYST'
            WHEN c.tool = 'SV_OPERATIONS' THEN 'INVENTORY_ANALYST'
            WHEN c.tool = 'SV_HISTORY' THEN 'RISK_HISTORIAN' ELSE c.called_agent END AS sub_agent,
       c.tool_type, c.tool,
       COALESCE(UPPER(t.value::STRING), c.tool) AS object_touched
FROM calls c
LEFT JOIN req r ON r.thread_id = c.thread_id,
LATERAL FLATTEN(INPUT => COALESCE(REGEXP_SUBSTR_ALL(c.final_sql, 'WAR_ROOM[.]OPS[.]([A-Za-z_]+)', 1, 1, 'ie', 1), ARRAY_CONSTRUCT()), OUTER => TRUE) t;

-- Fallback for the demo if observability events arrive late: refresh after each rehearsal run
CREATE OR REPLACE TABLE AGENT_AUDIT_SNAPSHOT AS SELECT CURRENT_TIMESTAMP() snapshot_at, * FROM V_AGENT_AUDIT;

-- Check: each sub-agent only touched its own sources (expect CONTRACT_ANALYST only on SUPPLIER_DOCS_SEARCH*)
SELECT sub_agent, tool, object_touched, COUNT(*) AS calls, LISTAGG(DISTINCT viewer_role, ',') AS viewer_roles
FROM V_AGENT_AUDIT GROUP BY 1, 2, 3 ORDER BY 1, 3;

-- Showcase tables: GOVERNANCE_TEST_RESULTS (per-role tests, secondary roles off) and BRIEF_RUNS (one brief per viewer)
-- were filled by running the tests and WAR_ROOM_LEAD as OPS_GLOBAL / OPS_EMEA / OPS_APAC.

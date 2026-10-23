You are running unattended in a Snowflake AGENT TASK; complete the task autonomously and do NOT ask clarifying questions. You are read-only: only run SELECT statements. Do not create, alter, insert, update or delete anything.

Task: write the daily War Room morning alert for Nordlys Electronics AB (fictional). It tells the supply chain team whether a typhoon or any other disruption is coming or already affecting the business, and what to do first.

Step 1. Run exactly this query with the SQL tool (warehouse WAR_ROOM_WH; run USE WAREHOUSE WAR_ROOM_WH first if no warehouse is active):

WITH exp AS (
  SELECT region, COUNT(*) skus, MIN(days_of_cover) min_cover, SUM(at_port_value_eur) at_port_eur,
         SUM(in_transit_value_eur) at_sea_eur,
         LISTAGG(IFF(days_of_cover < 20, sku_id, NULL), ', ') WITHIN GROUP (ORDER BY sku_id) below_20,
         LISTAGG(IFF(at_port_status LIKE 'TIGHT%' OR at_port_status LIKE 'LATE%', sku_id, NULL), ', ') tight
  FROM WAR_ROOM.OPS.V_EXPOSURE GROUP BY 1),
risk AS (SELECT region, historical_risk FROM WAR_ROOM.OPS.V_RISK_CALENDAR WHERE month_no = MONTH(CURRENT_DATE()))
SELECT CASE WHEN n.severity='HIGH' AND COALESCE(e.skus,0)>0 THEN 'ACT NOW'
            WHEN COALESCE(e.min_cover,999) < 20 THEN 'ACT NOW'
            WHEN n.severity='MEDIUM' AND COALESCE(e.skus,0)>0 THEN 'WATCH' ELSE 'FYI' END lvl,
  n.alert_id, n.severity, n.region, n.event_type, n.headline, n.published_at,
  IFF(n.published_at >= DATEADD(hour,-24,CURRENT_TIMESTAMP()), 'NEW','') is_new,
  e.skus, e.min_cover, e.at_port_eur, e.at_sea_eur, e.below_20, e.tight, r.historical_risk oct_risk,
  (SELECT LISTAGG(role_name, ',') FROM WAR_ROOM.OPS.VIEWER_REGION_ACCESS v WHERE v.region = n.region) viewers
FROM WAR_ROOM.OPS.NEWS_FEED n LEFT JOIN exp e ON e.region=n.region LEFT JOIN risk r ON r.region=n.region
ORDER BY DECODE(lvl,'ACT NOW',1,'WATCH',2,3), DECODE(n.severity,'HIGH',1,'MEDIUM',2,3), n.published_at DESC;

Step 2. Write the report from the query result only. Never invent numbers, dates or alerts. Every alert line carries its alert id in square brackets, for example [A02]. Money in EUR with thousands separators.

Report format (plain text email, short lines):

Subject line: "War Room <day Mon>: <n> ACT NOW, <n> WATCH, <n> FYI" and, if there is any ACT NOW, add " - <region> <event type>" for the first ACT NOW alert. Example: "War Room 22 Oct: 3 ACT NOW, 3 WATCH, 14 FYI - TW-SOUTH typhoon".

Section "Headline": one or two sentences saying whether a typhoon or other natural disaster (event types WEATHER, PORT closures caused by weather) is coming or affecting us, which region, and the money and stock at risk. If nothing is ACT NOW, say "No disruption needs action today."

Section "ACT NOW": one block per region (merge alerts of the same region). For each: the alert ids and headlines; SKUs affected; lowest days of cover; EUR waiting at port and EUR at sea; SKUs below the 20-day rule (lesson D-006); SKUs whose at-port stock arrives tight or late; this month's historical risk if present. Then up to 3 suggested first actions, based only on these facts: request expedited shipping of stock waiting at port (clause 7.2) the same day (lesson D-008); place bridge orders for SKUs below 20 days; open the War Room brief in CoWork for the full analysis.

Section "WATCH": one line per alert: [id] region - headline - SKUs exposed, lowest cover.

Section "FYI": one line per alert: [id] severity region - headline. Mark NEW alerts with "NEW".

Section "Per viewer": for each viewer role OPS_GLOBAL, OPS_EMEA, OPS_APAC, one line: the role, the count of ACT NOW / WATCH / FYI alerts in its regions (use the viewers column; a row counts for a role only if the role is listed there), and the region codes. Then the line: "Viewer emails are not sent yet: viewers will be added once their email addresses are verified."

Section "Notes": "Alerts come from WAR_ROOM.OPS.NEWS_FEED. Typhoon history and lessons are simulated data."

Step 3. Finish: call gather_email_content with the subject and the full report, then print the status line on its own:
WAR_ROOM_MORNING_ALERT_OK act_now=<n> watch=<n> fyi=<n> top_region=<region or none>
If the query fails, still call gather_email_content with a short report of the error, then print:
WAR_ROOM_MORNING_ALERT_FAILED:<one-line reason>

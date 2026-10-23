# War Room: multi-agent supply chain research on Snowflake

Built at the Snowflake AI Hackathon, Stockholm, 22 October 2026, by a team of five.

**All company data is fictional.** The company (Nordlys Electronics AB), its suppliers, contracts, shipments and news are made up for the demo. Only the storm history is real (NOAA IBTrACS).

## The problem

A typhoon (fictional "Meilin") is about to hit Kaohsiung, Taiwan. The sole supplier of three critical chips is there. A supply chain lead has hours, not days, and the facts are spread over three places: stock and shipment tables, supplier contracts and emails, and a news feed. The question: **what is our exposure, and what should we do first?**

## The idea

One lead agent runs a deep research on the question. It asks three specialist agents and writes a one-page cited brief.

| Agent | Looks at | Snowflake tool |
|---|---|---|
| `NEWS_SCOUT` | News alerts, which regions are affected | Cortex Search (`NEWS_SEARCH`) |
| `INVENTORY_ANALYST` | Stock, days of cover, open shipments, past lessons | Semantic view + Cortex Analyst (`SV_OPERATIONS`) |
| `CONTRACT_ANALYST` | Contract clauses, supplier emails, alternative quotes | Cortex Search (`SUPPLIER_DOCS_SEARCH`) |
| `WAR_ROOM_LEAD` | Asks the three above, cross-checks, writes the brief | Deep Research in Snowflake CoWork |

Governance: row access policy by role, so a viewer without Taiwan access gets "Internal data for Taiwan is not visible with your access", never "no exposure". Each agent only has its own tool, so the audit shows which agent touched which data.

## Data

- **Simulated:** suppliers, inventory, shipments, news feed, supplier documents, past disruptions (`WAR_ROOM.OPS`).
- **Real:** NOAA IBTrACS West Pacific storm tracks, loaded through a stage and a dynamic table.
- **Honest limit:** IBTrACS gives storm positions, not port closures. "Closure" here is a proxy: a tropical storm within 200 km of the port. It is history, not a forecast.

## Snowflake features used

Cortex Search, Semantic Views with Cortex Analyst, Agents (Agent Studio), Deep Research in CoWork, row access policies, dynamic tables, stages and `COPY INTO`, Streamlit in Snowflake, Snowpark.

## Files

| File | What it does |
|---|---|
| `war_room_tables.sql` | Creates the schema, tables and the row access policy. Safe to rerun. |
| `war_room_data.sql` | Inserts the fictional data. Run once only (running twice doubles the rows). |
| `war_room_checks.sql` | Row counts and expected answers to verify the setup. |
| `war_room_analysis.sql` | Views: risk calendar, exposure, lessons. |
| `war_room_real_data_pipeline.sql` | Loads NOAA storm data and builds the history tables. |
| `war_room_ports_plan.sql` | Adds more ports and the planned shipment calendar. |
| `war_room_semantic_view.sql` | Semantic view for the inventory agent. |
| `war_room_tools_2_3.sql` | The two Cortex Search services (news, documents). |
| `war_room_governance.sql` | Roles, access and agent trace queries. |
| `war_room_ml_app.py` | Streamlit page: monthly closure risk model (logistic regression on month, numpy). |
| `war_room_history_map_app.py` | Streamlit app: risk calendar, storm map, shipping lanes, shipment calendar. |

## How to run

1. In a Snowflake account (trial is enough), run `war_room_tables.sql`, then `war_room_data.sql` once, then `war_room_checks.sql`.
2. Run `war_room_analysis.sql`.
3. Download `ibtracs.WP.list.v04r01.csv` from NOAA, upload it to the stage, then run `war_room_real_data_pipeline.sql`.
4. Run `war_room_semantic_view.sql` and `war_room_tools_2_3.sql`.
5. Create the four agents in Agent Studio with the instructions in `war_room_agents_notes.md`.
6. Ask the lead: *"A typhoon is hitting our Taiwan supplier region. What is our exposure, and what are our options?"*

## Expected demo numbers

Formosa Chip Works: SKU-1001 / 1002 / 1003 at 9 / 14 / 21 days of cover. Four open shipments worth EUR 1,200,000 (EUR 615,000 at port, EUR 585,000 at sea). Clause 7.2 (expedite at buyer's cost) and clause 11.3 (typhoon suspends obligations). Alternative supplier +15% price, 21 days lead time plus 18 at sea.

## Not included

No credentials, tokens or real company data. Never commit a Snowflake password or GitHub token.

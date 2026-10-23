
# War Room: draft wording for the day 

## Architecture (one identity per agent)
- **WAR_ROOM_LEAD** (Deep Research in CoWork): calls the three sub-agents and writes the brief.
- **NEWS_SCOUT**: identity AGENT_NEWS_ROLE, tool NEWS_SEARCH.
- **INVENTORY_ANALYST**: identity AGENT_INVENTORY_ROLE, tool SV_OPERATIONS.
- **CONTRACT_ANALYST**: identity AGENT_CONTRACTS_ROLE, tool SUPPLIER_DOCS_SEARCH.
- First question to the organisers: how does Deep Research call separate agents, each with its own Agent Identity?
- Build order: NEWS_SCOUT, INVENTORY_ANALYST, CONTRACT_ANALYST (test each alone), then WAR_ROOM_LEAD.

## Agent instructions (paste into each agent's instructions box)

### 1. WAR_ROOM_LEAD
You lead the supply chain war room research team for Nordlys Electronics AB, a fictional company. When there is a disruption, answer three things: our exposure, our contract options, and our alternatives.
- First ask NEWS_SCOUT which alerts and region codes are affected.
- Then pass those region codes to INVENTORY_ANALYST and CONTRACT_ANALYST. They can work in parallel.
- Cross-check their answers: quote prices against our current unit cost, contract dates against shipment dates.
- Every number, clause and supplier must come from a sub-agent and carry its source (alert id, document and clause, shipment id or lesson id). Never invent anything.
- If a sub-agent says internal data for a region is not visible, write "Internal data for <region> is not visible with your access." Never write "no exposure".
- Show money in EUR and stock as days of cover. Today is 22 October 2026.
- Keep the brief to one page: situation, exposure, contract position, options, recommendation (3 actions with dates), lessons applied, assumptions, sources.

### 2. NEWS_SCOUT
You are the news scout in the war room for Nordlys Electronics AB, a fictional company.
- Search the news alerts for the disruption you are asked about.
- Return a table: alert_id, region, severity, event type, published time, headline.
- End with one line exactly like this: AFFECTED_REGIONS: <region codes of the HIGH severity alerts>
- Ignore LOW severity alerts in other regions unless asked. They are background noise.
- Quote the alert id for each claim, for example [alert A02].
- You cannot see internal data. Do not comment on stock, contracts or suppliers.
- If no alert matches, say so.

### 3. INVENTORY_ANALYST
You are the inventory analyst in the war room for Nordlys Electronics AB, a fictional company.
- You receive one or more region codes, for example TW-SOUTH. Always filter on those codes.
- Report: suppliers in the region and their SKUs; per SKU the days of cover, cover including stock at sea, rule status and at-port status; open shipment value split into at port and at sea, with shipment ids; lessons from past disruptions in that region; historical risk for this month (October).
- The exposure figures assume stock held at port arrives 10 days late (3 days port closure from alert A02, plus up to 5 business days restart under clause 11.3). Say this when you use the at-port figures.
- History and lessons are simulated. Say so.
- Quote the source for each claim, for example [exposure SKU-1003], [shipment SH-004], [lesson D-006].
- If a query returns no rows for a region, say "No internal data visible for <region> with the current access." Never conclude that there is no exposure.
- Never invent numbers.

### 4. CONTRACT_ANALYST
You are the contract analyst in the war room for Nordlys Electronics AB, a fictional company.
- You receive a supplier name or region code, and the affected SKUs if known.
- Find: contract clauses that apply (expedited shipping, force majeure, notice and restart periods); recent emails from the affected supplier; quotes from other suppliers for the affected SKUs (price, percent difference, capacity, lead time, transit time).
- Always give clause number, doc_id and file name, for example [D01 formosa_master_supply_agreement.pdf, clause 7.2].
- Quote clause wording briefly. Do not paraphrase numbers.
- If clauses conflict (for example expediting is allowed but force majeure suspends obligations), say so.
- You cannot see stock or shipment tables. Do not estimate them.
- If nothing is found, say so. Never invent clauses.

## Tool descriptions (one short paragraph each, the agent reads these to choose a tool)
1. **News alerts (Cortex Search NEWS_SEARCH, NEWS_SCOUT only).** Weather, port, logistics and labour alerts by region, severity and event type. Use to find what is happening now and which regions are affected. ID column: alert_id. Title column: headline.
2. **Inventory, shipments and history (semantic view SV_OPERATIONS, INVENTORY_ANALYST only).** Suppliers with their region, stock and days of cover per SKU, open shipments split into at port and at sea, past disruptions with lessons, and the typhoon risk calendar by month. Use for exposure, cost and history questions.
3. **Contracts and quotes (Cortex Search SUPPLIER_DOCS_SEARCH, CONTRACT_ANALYST only).** Contract clauses, supplier emails and quotations. Use for clauses such as expedited shipping (7.2) and force majeure (11.3), and for alternative supplier quotes. ID column: doc_id. Title column: file_name.
4. **Sub-agents (WAR_ROOM_LEAD only).** NEWS_SCOUT for alerts and affected regions, INVENTORY_ANALYST for exposure and history, CONTRACT_ANALYST for clauses and quotes.

## Semantic view notes (already built in war_room_semantic_view.sql)
- Name: WAR_ROOM.OPS.SV_OPERATIONS.
- Tables: suppliers, exposure (view v_exposure, one row per SKU), shipments, lessons (view v_lessons), risk_calendar (view v_risk_calendar).
- Joins: exposure.supplier_id = suppliers.supplier_id. shipments.sku_id = exposure.sku_id. No direct join from shipments to suppliers (two join paths are not allowed; each SKU has one supplier).
- Fact: days_of_cover = units_on_hand / daily_demand, per SKU. Metric: min_days_of_cover = minimum over SKUs.
- Metric: open_shipment_value = sum of value_eur where status is IN_TRANSIT or AT_PORT. Also total_at_port_value and total_in_transit_value.
- Synonyms: "stock" and "cover" = exposure. "supplier" and "vendor" = supplier_name. "open exposure" and "value at risk" = open_shipment_value.
- No hard-coded region: the region code comes from NEWS_SCOUT.

## Cortex Search settings (in war_room_governance.sql, section B5, run on the day)
- SUPPLIER_DOCS_SEARCH: table supplier_documents. Search column: content. Filter columns: supplier_id, region, doc_type.
- NEWS_SEARCH: table news_feed. Search column: headline plus body. Filter columns: region, severity, event_type.
- Both are owned by WAR_ROOM_ADMIN so the index holds every document.

## Test questions (answers are in the war_room_checks.sql scoreboard)
1. Which suppliers are in the typhoon region, and which SKUs do they supply? Expect: Formosa Chip Works, SKU-1001, SKU-1002, SKU-1003.
2. What is the minimum days of cover on those SKUs? Expect: 9 days (SKU-1001). All three: 9, 14, 21.
3. What is the value of open shipments from that supplier? Expect: 4 shipments, EUR 1,200,000 (EUR 615,000 at port, EUR 585,000 at sea).
4. What does the supplier contract say about expedited shipping? Expect: D01 clause 7.2, at buyer's cost. Clause 11.3 suspends obligations during a typhoon.
5. What is the best alternative supplier and what does it cost? Expect: Penang Semicon (D08), 15% higher, 40,000 units a month, 21 days lead time plus 18 days at sea, so a bridge rather than a rescue.
6. (History) Which months have been riskiest for Taiwan port closures? Expect: August, July, September. October is medium.
7. (Lessons) What did we learn from the 2024 typhoon, and are we repeating it today? Expect: D-006, keep cover above 20 days. SKU-1001 and SKU-1002 are below it, so yes. D-008: send the 7.2 request the same day.
8. (Hidden risk) Which SKU is closest to running out once the port closes? Expect: SKU-1003, stock at port (SH-004) arrives 10 November, stock runs out 12 November, 2 days margin.
9. (Governance) Ask the typhoon question as OPS_EMEA. Expect: the brief says Taiwan internal data is not visible. News is still shown.
10. (Audit) Which agent touched which data? Expect: NEWS_SCOUT only news, INVENTORY_ANALYST only the semantic view, CONTRACT_ANALYST only the document search.

## The typhoon question for Deep Research
"A typhoon is hitting our Taiwan supplier region. What is our exposure, and what are our options? Use current alerts, our stock and open shipments, our contract with the supplier, the alternative supplier quotes and what we learned from past typhoons."
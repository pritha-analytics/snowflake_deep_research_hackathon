# War Room: Scenario and Data Plan

**Chain of Custody in the War Room: multi-agent orchestration under governance · updated 21 October, evening**

- **Case:** *"A typhoon is hitting our Taiwan supplier region. What is our exposure, and what are our options?"*
- **Users:** supply chain and operations leaders during a disruption
- **Company (fictional):** Nordlys Electronics AB, warehouse in Gothenburg. Every name, event and number is made up.
- **Storm (fictional):** Typhoon Meilin
- **"Today" in the scenario:** 22 October 2026
- **Pitch line:** *"Everyone can build a RAG chatbot. We built a research team that produces a board-ready brief with citations and a chain of custody."*

---

## 1. The idea in one picture

| Layer | What it is | Snowflake feature |
|-------|------------|-------------------|
| **Question** | The supply chain lead asks one question | CoWork |
| **Research team** | A lead agent hands work to specialist sub-agents | Deep Research |
| **Identities** | Each sub-agent has its own identity and least-privilege role | Agent Identity |
| **Sources** | Structured tables, unstructured documents, external news | Cortex Analyst (semantic view), Cortex Search |
| **Audit** | Every tool call is logged under the agent that made it | AI Gateway (`AGENT_TRACE_` tables), query history |
| **Output** | One cited brief that respects the viewer's permissions | CoWork Artifacts + row access policy |

---

## 2. The research team

| Agent | Tier | Identity / role | Tool | Can see | Cannot see |
|-------|------|-----------------|------|---------|------------|
| **WAR_ROOM_LEAD** | 1 | (Deep Research) | The sub-agents | Their answers | Data directly |
| **NEWS_SCOUT** | 1 | AGENT_NEWS_ROLE | NEWS_SEARCH | External alerts | Any internal data |
| **INVENTORY_ANALYST** | 1 | AGENT_INVENTORY_ROLE | SV_OPERATIONS | Suppliers, stock, shipments, lessons, risk calendar | Documents, news |
| **CONTRACT_ANALYST** | 1 | AGENT_CONTRACTS_ROLE | SUPPLIER_DOCS_SEARCH | Contracts, emails, quotes | Stock and shipment tables |
| **RISK_HISTORIAN** | 2 | AGENT_HISTORIAN_ROLE | SV_HISTORY | Lessons, risk calendar | Inventory, shipments, documents |

**How they work together**

1. The lead asks **NEWS_SCOUT** what is happening. It answers with `AFFECTED_REGIONS: TW-SOUTH`.
2. The lead passes that region code to **INVENTORY_ANALYST** and **CONTRACT_ANALYST** (and **RISK_HISTORIAN** in Tier 2).
3. The lead cross-checks their answers and writes the brief.

> No region is hard-coded anywhere. The region always comes from the news.

---

## 3. Data

All data is pre-built and tested. `war_room_data.sql` loads it after `war_room_tables.sql`. **Do not regenerate it with Cortex Code**, because that would break the facts below.

| Source | Table | Rows | Used by | Access |
|--------|-------|------|---------|--------|
| 1. Structured | `suppliers` | 6 | Inventory analyst | Restricted by region |
| 1. Structured | `inventory` | 25 | Inventory analyst | Restricted by region |
| 1. Structured | `shipments` | 60 | Inventory analyst | Restricted by region |
| 2. Unstructured | `supplier_documents` (3 contracts, 4 emails, 3 quotes) | 10 | Contract analyst | Restricted by region |
| 3. External | `news_feed` (3 typhoon alerts, 17 noise) | 20 | News scout | Public |
| History | `typhoon_history` (monthly, 2016–2025, simulated) | 120 | Inventory analyst / risk historian | Public |
| History | `past_disruptions` (our incidents and lessons) | 8 | Inventory analyst / risk historian | Public |
| Map | `ports`, `typhoon_track` | 6 + 6 | Map page (Tier 2) | Public |
| Access | `viewer_region_access` | 9 (12 with OPS_APAC) | Row access policy | Admin only |

**Views built on top** (`war_room_analysis.sql`)

| View | What it adds |
|------|--------------|
| `v_exposure` | Per SKU: cover, at port vs at sea, cover including stock at sea, delayed arrival, margin, rule status, shipment ids |
| `v_risk_calendar` | Average port-closure days per region and month, with HIGH / MEDIUM / LOW |
| `v_lessons` | All past disruptions with event_id for citation |

**One region code everywhere:** `TW-SOUTH`, `TW-NORTH`, `CN-SOUTH`, `MY-PENANG`, `PL-GDANSK`, `DE-NRW`, `SE-GOTHENBURG`, `NL-ROTTERDAM`, `GLOBAL`.

---

## 4. The 9 facts the brief must contain

Check every brief against this list and the scoreboard in `war_room_checks.sql`.

| # | Fact | Source | Scoreboard line |
|---|------|--------|-----------------|
| 1 | Typhoon Meilin hits southern Taiwan on 22 Oct. Kaohsiung port closed 48–72 hours. Air cargo cancelled until 24 Oct | A01, A02, A03 | 24 |
| 2 | Formosa Chip Works (TW-SOUTH) supplies exactly 3 SKUs: SKU-1001, SKU-1002, SKU-1003 | suppliers, exposure | 11 |
| 3 | Days of cover: 9 / 14 / 21 (minimum 9, SKU-1001) | exposure | 12 |
| 4 | 4 open shipments, €1,200,000: **€615,000 held at port** (SH-002, SH-004), **€585,000 at sea** (SH-001, SH-003) | exposure, shipments | 13, 14 |
| 5 | Clause 7.2: expedited shipping on written request, at the buyer's cost. Clause 11.3: obligations suspended during the typhoon, notice within 24 hours, restart within 5 business days | D01 | 15, 16 |
| 6 | Penang Semicon: +15% (€69.00 / €51.75 / €34.50), 40,000 units/month, 21 days lead time + 18 days at sea, so **a bridge, not a rescue** | D08 | 17, 18 |
| 7 | SKU-1001 and SKU-1002 are below the 20-day rule we adopted after 2024, so **we are repeating the 2024 mistake** (that one cost €410,000) | D-006, exposure | 21, 22 |
| 8 | Send the written 7.2 request **today**. Formosa's own email says two orders are still at port | D-008, D04 | 22 |
| 9 | **Hidden risk:** SKU-1003 looks safe (21 days), but its only inbound stock is held at port. It arrives around 10 Nov, stock runs out on 12 Nov: **2 days margin** | exposure SKU-1003 | 23 |

**Supporting facts (good to have in the brief)**

| Fact | Source |
|------|--------|
| August, July and September are the riskiest months. October is MEDIUM (simulated history) | v_risk_calendar |
| SKU-1001 is covered if SH-001 (6,000 units, at sea, ETA 27 Oct) arrives: cover rises to 24 days | exposure SKU-1001 |
| Penang has its own MEDIUM alert (worker shortage) | A17 |
| Lesson D-003: qualify a second supplier outside the region | D-003 |

---

## 5. What a good brief recommends

| # | Action | When | Why | Source |
|---|--------|------|-----|--------|
| 1 | Send the written expedite request under clause 7.2 for SH-002 and SH-004 | **Today, 22 Oct** | Same-day requests saved shipments in 2025. Air cargo only restarts after 24 Oct, so be first in line | D-008, D04, A03 |
| 2 | Track SH-004 (SKU-1003) and SH-001 (SKU-1001) daily. Escalate if Formosa's restart takes longer than 5 business days | From 22 Oct | SKU-1003 has only 2 days margin. SKU-1001 depends on SH-001 arriving | exposure, D01 §11.3 |
| 3 | Order a Penang bridge supply for SKU-1001 and SKU-1002 at +15% | This week | Restores the 20-day rule for the rest of the typhoon season and creates a second source | D08, D-006, D-003 |

---

## 6. Assumptions (the brief must state them)

| Assumption | Where it comes from |
|------------|---------------------|
| Stock held at port arrives **10 days late**: 3 days port closure + up to 5 business days restart | A02 + clause 11.3. Set in `v_exposure` |
| Stock already at sea arrives on its ETA | `v_exposure` |
| Scenario date is 22 October 2026 | Fixed in `v_exposure`, so tests give the same answer on any day |
| Typhoon history and lessons are **simulated** | `data_source = 'SIMULATED'` |

---

## 7. Access (who sees what)

| Role | Type | Tier | Regions | What the brief shows |
|------|------|------|---------|----------------------|
| **WAR_ROOM_ADMIN** | Admin | 1 | All | Everything (owner, runs checks) |
| **OPS_GLOBAL** | Viewer | 1 | All 6 supplier regions | The full brief |
| **OPS_EMEA** | Viewer | 1 | PL-GDANSK, DE-NRW, SE-GOTHENBURG | *"Internal data for TW-SOUTH is not visible with your access."* News is still shown |
| **OPS_APAC** | Viewer | 2 | TW-SOUTH, MY-PENANG, CN-SOUTH | Taiwan and Penang visible, so a different brief from EMEA |

**Rules**

- The row access policy covers **internal** data only: suppliers, inventory, shipments, supplier_documents.
- News, history, lessons and map data are **public**.
- The brief never says "no exposure" when data is hidden. It says the data is not visible.

---

## 8. Team roles

| Role | Responsible for |
|------|-----------------|
| **Data** | Run the SQL files, scoreboard. Tier 2: map page |
| **Unstructured** | Search services, contract analyst. Tier 2: risk historian |
| **Orchestration** | Agents, lead, Deep Research runs |
| **Governance** | Role tests, second viewer, audit query. Tier 2: chain-of-custody page, APAC role |
| **Story** | Pitch, slides, screenshots, backup video. Checks the brief against the 9 facts |

> The day plan, times and fallbacks are in `war_room_build_steps.md`.

---

## 9. Out of scope (pitch "next steps")

| Idea | Why not tomorrow |
|------|------------------|
| Real storm history from NOAA IBTrACS via a dynamic table (`OLD/war_room_real_data_pipeline.sql`) | Replaces the verified history and needs a manual download |
| More disruption types (strikes, floods, lockdowns) as live scenarios | Data exists in past_disruptions, but there's no time to test it |
| Automatic triggers: new HIGH alert, then the brief runs by itself | Needs tasks/alerts, not part of the hackathon features |
# War Room: Build Steps

**Full plan in three tiers · updated 21 October**

- **Hackathon:** Thursday 22 October 2026, Snowflake Stockholm office
- **Pitch:** to an expert panel, winner announced around 17:00
- **Key point:** one lead agent (Deep Research in CoWork) and specialist sub-agents. Each sub-agent has its own Agent Identity, its own role and one tool.
- **Foundation:** the SQL is pre-built and tested (scoreboard 28/28 PASS). On the day we run it, then build the agents.
- **Confirmed by the organisers:** Deep Research in CoWork, Agent Identity, Cortex AI Gateway (`AGENT_TRACE_` tables), CoWork Artifacts, Cortex Search, and Cortex Analyst with semantic views.

---

## 1. How the tiers work

| Tier | Contents | When to start |
|------|----------|---------------|
| **Tier 1: core (must have)** | Research team with 3 identities, cited brief, audit trail, EMEA viewer. **This is the pitch.** | Always first |
| **Tier 2: should have** | Visuals and a fourth specialist | When Tier 1 steps 1–12 are done, or someone is idle |
| **Tier 3: could have** | Extras | Only when Tier 1 is complete and the final run is saved |

> **Cut line:** at 14:30 the final Deep Research run happens no matter what. Anything unfinished at that point is dropped from the demo.

---

## 2. Before the day (done)

- [x] Case agreed: `war_room_scenario.md` is the plan
- [x] SQL files written and tested in a trial account: tables, data, analysis, governance (policy and grants), semantic view, checks
- [x] Agent wording ready: `war_room_agents_notes.md` (paste-ready)
- [x] Pitch script drafted (3 minutes)
- [x] Optional and old files moved to `OLD`. Do not run anything in `OLD` unless a Tier 3 step says so

---

## 3. Run order for the SQL files

Always use **Run All**, never part of a file.

| # | File | Note |
|---|------|------|
| 1 | `war_room_tables.sql` | Creates the role, warehouse and 10 tables |
| 2 | `war_room_data.sql` | Loads the simulated data |
| 3 | `war_room_analysis.sql` | Creates the 3 views |
| 4 | `war_room_governance.sql` | Roles, policy, grants. Section B5 creates the 2 search services (needs the hackathon account) |
| 5 | `war_room_semantic_view.sql` | Creates `SV_OPERATIONS` |
| 6 | `war_room_checks.sql` | One query, every line must say **PASS** |

> **Role tip:** in a Snowsight workspace, a single line run with Ctrl+Enter uses the **role in the selector at the top right**, not a `USE ROLE` line above it. To test as another role, change the selector.

---

## 4. Team lanes

Team of 5. With fewer people, merge lanes: **A = Data + Orchestration**, **B = Governance + Story**.

| Lane | Tier 1 work | Tier 2 work |
|------|-------------|-------------|
| **Data** | SQL files | Map and visuals |
| **Orchestration** | Agents and Deep Research runs | – |
| **Unstructured** | Search services, contract analyst | Risk historian |
| **Governance** | Role tests, second viewer, audit query | Chain-of-custody page, APAC role |
| **Story** | Pitch, slides, screenshots, backup video. Checks every brief against the 9 facts | Opening slide |

---

## 5. Tier 1: core (must have)

| # | Time | Step | Who | Done when |
|---|------|------|-----|-----------|
| 1 | 09:00 | Log in, add the team to one workspace. Ask the organisers: *"How does Deep Research call separate agents, each with its own Agent Identity?"* | Everyone | Answer noted |
| 2 | 09:10 | **New account?** Upload the 6 SQL files and Run All in the run order. **Same trial account?** Only run `war_room_governance.sql` again (for the search services) | Data | Scoreboard 28/28 PASS. `SHOW CORTEX SEARCH SERVICES` lists 2 |
| 3 | 09:30 | Governance tests T1–T8. Role selector: OPS_EMEA (T1), OPS_GLOBAL (T2), AGENT_CONTRACTS_ROLE (T3), AGENT_NEWS_ROLE (T4), OPS_EMEA (T5), WAR_ROOM_ADMIN (T6–T8) | Governance | EMEA sees no Taiwan rows. Agent roles get "insufficient privileges" outside their own source. Search finds D01, D08, A01–A03 |
| 4 | 09:45 | Write down T5: does document search hide D01 from OPS_EMEA? If not, add the region filter rule to CONTRACT_ANALYST | Governance | Result noted |
| 5 | 10:00 | Build **NEWS_SCOUT**: identity AGENT_NEWS_ROLE, tool NEWS_SEARCH | Orchestration | Finds A01, A02, A03. Ends with `AFFECTED_REGIONS: TW-SOUTH` |
| 6 | 10:20 | Build **INVENTORY_ANALYST**: identity AGENT_INVENTORY_ROLE, tool SV_OPERATIONS | Orchestration | Test questions 1, 2, 3, 6, 7, 8 match the agent notes |
| 7 | 10:20 | Build **CONTRACT_ANALYST**: identity AGENT_CONTRACTS_ROLE, tool SUPPLIER_DOCS_SEARCH | Unstructured | Test questions 4 and 5 match, with doc_id and clause cited |
| 8 | 10:20 | **Second viewer:** one teammate's user gets OPS_EMEA as default role, logged in in a separate browser window | Governance | That user sees no Taiwan rows in SV_OPERATIONS |
| 9 | 10:45 | **Audit query** on the `AGENT_TRACE_` tables / agent-attributed query history: agent identity, tool, object, time | Governance | One table showing each sub-agent touched only its own source |
| 10 | 11:10 | Build **WAR_ROOM_LEAD** with the sub-agents as its tools | Orchestration | It calls NEWS_SCOUT first, then the other two |
| 11 | **11:30** | **FIRST Deep Research run:** CoWork → + → Deep Research → typhoon question. Up to 10 minutes. Save as an Artifact | Orchestration | Brief exists. Audit trail starts early (history views can lag) |
| 12 | 12:00 | Check the brief against the 9 facts in the scenario file and the scoreboard | Story + everyone | Every claim cited, nothing invented |
| 13 | 13:00 | Fix agent instructions where the brief was wrong. Run the audit query on the 11:30 run | Orchestration + Governance | Audit shows 3 identities |
| 14 | 13:30 | Open the Artifact as the **OPS_EMEA** user | Governance | Brief says Taiwan internal data is not visible. News still shown |
| 15 | **14:30** | **FINAL Deep Research run** (the one we demo). Save as an Artifact. Screenshot the brief, the audit result and the EMEA view | Orchestration + Story | Final Artifact saved |
| 16 | 15:30 | Record a **backup video** of the full demo. Rehearse the pitch twice with a timer | Story + everyone | 3 minutes without stopping |

---

## 6. Tier 2: should have

Start when Tier 1 steps 1–12 are done, or when someone is idle.

| # | Earliest | Step | Who | Effort | Done when |
|---|----------|------|-----|--------|-----------|
| 2.1 | 11:00 | **Map page** (`WAR_ROOM_MAP`): read `V_EXPOSURE` instead of recalculating, use `get_active_session()`, take regions from news_feed, app owned by WAR_ROOM_ADMIN. Shows the storm path, ports, the red lane to Gothenburg, and SKU-1003 as the tight one | Data | 30–45 min | Map renders. Numbers match the scoreboard (€615k at port, SKU-1003 TIGHT) |
| 2.2 | 13:00 | **Chain-of-custody page:** second Streamlit page on the audit query from step 9. Table and simple diagram: agent identity → tool → object touched → time | Governance + Data | 45–60 min | Shows that CONTRACT_ANALYST never read shipments |
| 2.3 | 11:00 | **Fourth sub-agent RISK_HISTORIAN:** role AGENT_HISTORIAN_ROLE, small semantic view SV_HISTORY over `v_lessons` and `v_risk_calendar` only. The lead asks it for lessons and the risk month | Unstructured | 45 min | Answers test questions 6 and 7. Audit shows it never touched inventory or shipments |
| 2.4 | 13:00 | **APAC viewer:** role OPS_APAC with rows TW-SOUTH, MY-PENANG, CN-SOUTH in `viewer_region_access`, same grants as OPS_EMEA. Gives "two viewers, two different briefs" instead of "one sees nothing" | Governance | 20 min | As OPS_APAC: Taiwan and Penang visible. As OPS_EMEA: neither |
| 2.5 | 13:00 | **Opening slide:** screenshot of the map (2.1) and the architecture (lead + sub-agents + identities) | Story | 20 min | Slide ready |

> SQL for 2.3 and 2.4 (new role, semantic view, grants) is written on the day when the team starts on it.

---

## 7. Tier 3: could have

Start only when Tier 1 is complete and step 15 is saved.

| # | Step | Who | Effort | Done when | Note |
|---|------|-----|--------|-----------|------|
| 3.1 | **Risk model as a source:** run the ML page from `OLD/WAR_ROOM_ML_app` (fix the session line, label AUC as "model quality"), save `MONTH_RISK_PREDICTION`, and grant it to the historian (or inventory analyst) so the brief can cite *"model: October closure probability X%"* | Data | 45 min | Prediction table cited in a brief | Only after 2.3. Check that its October level does not contradict `v_risk_calendar` |
| 3.2 | **Real storm data** (NOAA IBTrACS) via `OLD/war_room_real_data_pipeline.sql` | Data | 60+ min | – | ⚠️ **Do NOT run tomorrow.** It replaces the verified history and breaks scoreboard lines 19–20 and 25–26. Use it as the "next step" line in the pitch instead |
| 3.3 | **Extra verified queries** in SV_OPERATIONS for the 9 test questions | Orchestration | 20 min | Analyst answers come back faster and identical | Nice to have, improves reliability |

---

## 8. Demo order (about 3 minutes)

The full script is in the pitch file. Tier 2 items slot in if built.

| Time | Beat | Tier 2/3 add-on |
|------|------|-----------------|
| 0:00 | **The problem:** Typhoon Meilin is hitting Kaohsiung. Three disconnected sources | Open on the map |
| 0:25 | **The team:** start Deep Research live and show the sub-agents starting, then switch to the final Artifact from 14:30 | – |
| 0:50 | **The brief:** €615k stuck at port, 9 days of cover, clause 7.2 vs 11.3, Penang +15% as a bridge | – |
| 1:25 | **The insight:** repeating the 2024 mistake (20-day rule) and the hidden risk on SKU-1003 (2 days margin) | "Our risk historian found…" |
| 1:55 | **Chain of custody:** each agent identity touched only its own source | Chain-of-custody page instead of the query result |
| 2:25 | **Second viewer:** the same Artifact as OPS_EMEA, Taiwan data not visible | Then as OPS_APAC, Taiwan visible |
| 2:45 | **Close:** *"Everyone can build a RAG chatbot. We built a research team with a chain of custody."* | "Next step: real NOAA storm data through a dynamic table pipeline" |

---

## 9. If something is missing

| Problem | What to do |
|---------|------------|
| **Deep Research cannot call separate agents** | Ask the organisers for their pattern first. Last resort: run the sub-agents one after another in CoWork (each still under its own identity, so the audit trail holds), then ask the lead to combine the answers into one brief |
| **Sub-agents run as their own role**, so the policy filters on the agent instead of the viewer | Run the PLAN B lines in `war_room_governance.sql` (section B1) and rely on Artifact permissions for the viewer filter. Pitch line becomes *"each agent has a least-privilege identity; the Artifact filters per viewer"* |
| **Document search does not hide Taiwan documents from OPS_EMEA** (T5) | Add "only search regions the user may see" to CONTRACT_ANALYST and filter on the region attribute |
| **Audit views empty or slow** | Use the `AGENT_TRACE_` tables from AI Gateway, or the screenshot from the 11:30 run |
| **Deep Research too slow on stage** | Never run it live to the end. Always demo the saved Artifact |
| **Cortex Search fails** | Take the clause text from the scoreboard checks (lines 15–17) and say search was the planned tool |
| **Streamlit map does not render** | Use the screenshot on the opening slide, or drop it |

### Running out of time: cut in this order

1. Tier 3 (all)
2. 2.5 Opening slide
3. 2.2 Chain-of-custody page
4. 2.1 Map page
5. 2.4 APAC viewer
6. 2.3 Risk historian
7. Second fix round of the brief

> **Never cut:** the identities, the audit trail, or the EMEA view.
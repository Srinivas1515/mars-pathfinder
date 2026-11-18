# Mars Pathfinder — Phase 5 Architecture: AI Mission Assistant & Autonomous Decision-Support

## 1. Architectural Overview
Phase 5 introduces an intelligent, scientifically grounded AI Mission Assistant into the Mars Pathfinder ecosystem.
Unlike generic LLM wrappers, the assistant is built on a deterministic decision-support pipeline that ingests live telemetry, spatial tracking, atmospheric hazards, and life-support consumables.

Key functional subsystems:
1. **Mission Context Engine (`processing/assistant/context_engine.py`)**: Continuously aggregates structured mission state, Sol elapsed time, crew headcount, isolated crew members, UHF/orbiter comm status, consumables ($O_2$, potable water, battery storage), and active atmospheric hazards.
2. **Sandboxed Tool Registry (`processing/assistant/tool_registry.py`)**: 12 strictly typed, sandboxed application tools. The assistant has zero access to arbitrary SQL, shell execution, or unrestricted filesystem access.
3. **Multi-Factor Recommendation Engine (`processing/assistant/recommendations.py`)**: Formulates structured 10-point decision recommendations detailing situation, supporting telemetry evidence, data sources, observation timestamps, risk assessments, recommended actions, alternatives, expected consequences, uncertainty scores, and safety classifications.
4. **Non-Destructive What-If Simulation Engine (`processing/assistant/what_if.py`)**: Clones baseline mission state snapshots into isolated simulation branches to project contingency deviations (storm expansions, comm blackouts, rover actuator jams, suit micro-punctures) without mutating active mission state.
5. **Human-in-the-Loop Safety Enforcer**: All consequential actions are governed by strict safety tiers (`INFORMATION_ONLY`, `RECOMMENDATION`, `SIMULATION_ACTION`, `REQUIRES_HUMAN_APPROVAL`, `NOT_AUTHORIZED`).

## 2. Directory Structure
```
processing/assistant/
├── __init__.py                  # Unified exports
├── models.py                    # Schemas for context, recommendations, tools, and what-if
├── context_engine.py            # Live mission context aggregator
├── tool_registry.py             # 12 sandboxed tools with typed input/output validation
├── recommendations.py           # 10-point structured recommendation engine
├── what_if.py                   # Isolated state-branching scenario evaluator
└── engine.py                    # AIAssistantEngine Singleton Coordinator
```

## 3. Sandboxed Tool Catalog (12 Tools)
| Tool Name | Risk Classification | Description |
| :--- | :--- | :--- |
| `GetMissionStatus` | `INFORMATION_ONLY` | Retrieves active Sol, mission name, and operational phase |
| `GetCrewPositions` | `INFORMATION_ONLY` | Returns coordinates, velocities, and separation distances |
| `GetCrewTelemetry` | `INFORMATION_ONLY` | Queries heart rate, suit pressure, and core temperature |
| `GetActiveHazards` | `INFORMATION_ONLY` | Identifies active dust squalls and radiation anomalies |
| `GetTerrainAnalysis` | `INFORMATION_ONLY` | Queries slope, roughness, and traversability score |
| `GetResourceStatus` | `INFORMATION_ONLY` | Evaluates remaining consumables ($O_2$, water, battery) |
| `GetCommunicationStatus` | `INFORMATION_ONLY` | Evaluates orbiter passes and mesh network partitions |
| `CalculateRescueRoute` | `RECOMMENDATION` | Generates waypoint route to isolated crew member |
| `CompareRescuePlans` | `RECOMMENDATION` | Compares shortest-distance vs lowest-hazard paths |
| `GetScientificObservations` | `INFORMATION_ONLY` | Fetches NASA PDS / MEDA / MCS observations |
| `GetModelPrediction` | `INFORMATION_ONLY` | Invokes Phase 4 ML models for hazard risk & traversability |
| `GenerateMissionReport` | `INFORMATION_ONLY` | Compiles structured situation debrief in Markdown/JSON |

## 4. PostgreSQL/PostGIS Schema
Migration file: `backend/migrations/007_ai_assistant.sql`
- `assistant_recommendations`: Stores structured recommendations, risk ratings, human approval timestamps, and audit records.
- `assistant_scenarios`: Stores non-destructive what-if simulation branches and delta calculations.
- `assistant_tool_executions`: Latency and execution telemetry for all tool dispatches.
- `assistant_audit_logs`: Query, intent classification, context snapshots, and safety ratings.

## 5. REST API Endpoints
- `GET /api/v1/assistant/context`
- `GET /api/v1/assistant/tools`
- `POST /api/v1/assistant/query`
- `POST /api/v1/assistant/what-if`
- `POST /api/v1/assistant/approve`
- `POST /api/v1/assistant/tools/execute`

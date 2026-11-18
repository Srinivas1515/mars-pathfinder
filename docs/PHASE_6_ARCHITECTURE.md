# Mars Pathfinder — Phase 6 Architecture: Mars Digital Twin & Advanced Mission Replay

## 1. Architectural Overview
Phase 6 establishes a full virtual representation of a complete Mars surface mission. The Digital Twin unifies spatial terrain, crew members, pressurized rovers, base habitats, orbiter communication relays, life-support consumables, and real-time atmospheric hazards.

Key functional components:
1. **Centralized Simulation Clock (`processing/digital_twin/clock.py`)**:
   - Bridges Earth UTC and Martian Sols (1 Martian Sol = 88775.244 SI seconds).
   - Computes Solar Longitude $L_s$ (0° to 360°) and Local True Solar Time (LTST) in 24 Martian hour notation.
   - Provides time stepping (+1h, +6h, +1 Sol, -1h) and speed multipliers (1x, 2x, 5x, 10x).
2. **Structured Mission State Engine (`processing/digital_twin/state_engine.py`)**:
   - Tracks live component telemetry across 7 primary entities: Ares Base Alpha (habitat), Ares Pressurized Rover, 4 crew members (Chen, Vance, Rostova, Sato), and the MRO UHF Orbiter Relay.
   - Generates deterministic mission state snapshots (`DigitalTwinSnapshot`).
3. **Event-Driven Mission Replay Engine (`processing/digital_twin/replay.py`)**:
   - Manages an append-only, chronologically sorted event stream (`MissionEvent`).
   - Enables non-destructive forward and backward scrubbing across historical mission milestones.
4. **Scenario Comparison Engine (`processing/digital_twin/scenarios.py`)**:
   - Evaluates Scenarios A through F under identical baseline initial conditions, computing quantitative deltas for traverse distance, $O_2$ consumed, hazard exposure scores, and objective completion %.
5. **Mission Performance Analytics (`processing/digital_twin/analytics.py`)**:
   - Computes overall route efficiency %, rescue response times, separation durations, and life-support depletion rates.
6. **Debrief Report Generator (`processing/digital_twin/export.py`)**:
   - Exports formatted mission debrief summaries in Markdown and JSON.

## 2. Directory Structure
```
processing/digital_twin/
├── __init__.py                  # Unified exports
├── models.py                    # Schemas for twin clock, entities, events, and analytics
├── clock.py                     # Centralized Martian Sol / Earth UTC simulation clock
├── state_engine.py              # Structured entity state manager and snapshot generator
├── replay.py                    # Append-only deterministic mission event replay store
├── scenarios.py                 # Multi-branch scenario comparison engine (Scenarios A-F)
├── analytics.py                 # Quantitative performance and efficiency analytics
├── export.py                    # Mission debrief report generator
└── engine.py                    # DigitalTwinEngine Singleton Coordinator
```

## 3. PostgreSQL/PostGIS Schema
Migration file: `backend/migrations/008_digital_twin.sql`
- `digital_twin_instances`: Active twin instances, current Sol, simulation state, time acceleration.
- `mission_state_snapshots`: Serialized entity and consumable states indexed by simulation seconds.
- `mission_events`: Append-only event store with deterministic time tags and data classification.
- `scenario_branches`: Alternative simulation branches and outcome metrics.
- `mission_analytics`: Historical performance metrics and efficiency indicators.

## 4. REST API Endpoints
- `GET /api/v1/digital-twin/state`
- `GET /api/v1/digital-twin/clock`
- `POST /api/v1/digital-twin/clock/control`
- `GET /api/v1/digital-twin/events`
- `POST /api/v1/digital-twin/events/append`
- `GET /api/v1/digital-twin/scenarios`
- `GET /api/v1/digital-twin/analytics`
- `GET /api/v1/digital-twin/export`

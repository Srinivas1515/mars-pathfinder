# Mars Pathfinder â€” Advanced Planetary Exploration & Mission Intelligence Platform

> **Comprehensive Multi-Phase Planetary Operating System for Martian Exploration & Mission Operations**
> Certified Architecture: Phases 1 through 7 + Final Security Release Gate

Mars Pathfinder is a full-stack, enterprise-grade planetary exploration, geospatial intelligence, and mission control operating system for Martian surface operations, astronaut tracking, hazard simulation, digital twin modeling, and autonomous voice decision-support.

---

## ðŸ›ï¸ System Architecture Overview

Mars Pathfinder is structured as a high-performance modular system combining:
1. **Scientific Backend & Data Pipeline (`backend/` & `processing/`)**:
   - High-throughput **Go Fiber v3** & **Python 3.12** microservices on port `8081`.
   - Native **PostgreSQL + PostGIS** spatial geometry engine for Martian equirectangular and IAU 2000 cartographic projections (`EPSG:104905`).
   - Authentic NASA PDS raster altimetry processing (MOLA, HRSC, THEMIS, HiRISE).
   - Multi-tier **Hybrid Cognitive Brain** (`processing/brain/hybrid_brain.py`) providing deterministic astrodynamics solvers, astronomical calculations, live mission telemetry grounding, free Wikipedia scientific RAG, and cloud LLM bridges (Gemini, Groq, OpenRouter).
2. **Interactive Mission Operations Frontend (`frontend/`)**:
   - Modern **React 19 + TypeScript + Vite** operating on port `5180`.
   - Dual synchronized visualization engines: **CesiumJS 3D Planetary Globe** and **OpenLayers 2D Scientific Map**.
   - 13 comprehensive operational modules accessible via a horizontally scrolling HUD tab bar with category filters.
   - **ICARUS Voice Ops Hub** with dynamic 44-band FFT audio equalizer visualizer, browser-native microphone speech capture, hands-free wake-word detection (*"Hey ICARUS, wake up"*), and robotic vocalization.

---

## ðŸ“‚ Repository Directory Layout

```text
c:\mars-pathfinder\
â”œâ”€â”€ backend/                  # Go Fiber & Python API Services (Port 8081)
â”‚   â”œâ”€â”€ cmd/api/              # Go main application entry points
â”‚   â”œâ”€â”€ internal/             # Domain logic (catalog, terrain, spatial, mission)
â”‚   â”œâ”€â”€ migrations/           # PostgreSQL / PostGIS database migrations
â”‚   â”œâ”€â”€ server.py             # Unified Python API & Cognitive Brain Server
â”‚   â””â”€â”€ Dockerfile            # Container configuration
â”‚
â”œâ”€â”€ frontend/                 # React 19 + TypeScript Frontend (Port 5180)
â”‚   â”œâ”€â”€ src/
â”‚   â”‚   â”œâ”€â”€ app/              # App root, HUD header, navigation, Brain modal
â”‚   â”‚   â”œâ”€â”€ features/         # 13 Dedicated Mission Feature Modules:
â”‚   â”‚   â”‚   â”œâ”€â”€ globe3d/      # 1. CesiumJS 3D Mars Planetary Globe
â”‚   â”‚   â”‚   â”œâ”€â”€ map2d/        # 2. OpenLayers 2D Equirectangular Scientific Map
â”‚   â”‚   â”‚   â”œâ”€â”€ catalog/      # 3. NASA PDS Data Catalog Explorer
â”‚   â”‚   â”‚   â”œâ”€â”€ terrain/      # 4. Regional Altimetry, Slopes & Profiles
â”‚   â”‚   â”‚   â”œâ”€â”€ environmental/# 5. Atmospheric Pressure, Dust Opacity & MEDA
â”‚   â”‚   â”‚   â”œâ”€â”€ mission/      # 6. Mission Route & Sol Waypoint Planner
â”‚   â”‚   â”‚   â”œâ”€â”€ survival/     # 7. Astronaut Survival & ECLSS Life Support
â”‚   â”‚   â”‚   â”œâ”€â”€ operations/   # 8. Ares-V Mission Operations & Crew Tracking
â”‚   â”‚   â”‚   â”œâ”€â”€ hazards/      # 9. Hazard Intelligence & Dust Storm Simulator
â”‚   â”‚   â”‚   â”œâ”€â”€ ml/           # 10. Machine Learning Hazard Forecasting
â”‚   â”‚   â”‚   â”œâ”€â”€ assistant/    # 11. AI Mission Assistant & Decision Support
â”‚   â”‚   â”‚   â”œâ”€â”€ digital_twin/ # 12. Ares Digital Twin & Telemetry Stream
â”‚   â”‚   â”‚   â””â”€â”€ icarus/       # 13. ICARUS Voice Assistant & Audio Visualizer
â”‚   â”‚   â””â”€â”€ styles/           # Tailwind CSS & HUD theme definitions
â”‚   â””â”€â”€ package.json          # Node dependencies & Vite configuration
â”‚
â”œâ”€â”€ processing/               # Python Scientific Computing & AI Engine
â”‚   â”œâ”€â”€ acquisition/          # NASA PDS data retrieval adapters
â”‚   â”œâ”€â”€ analysis/             # 97 Automated Unit Tests (100% Passing)
â”‚   â”œâ”€â”€ assistant/            # Natural language mission coordinator & what-if
â”‚   â”œâ”€â”€ brain/                # Hybrid Cognitive Brain & Astronomy Solvers
â”‚   â”œâ”€â”€ crew/                 # Locomotion & physiological tracking models
â”‚   â”œâ”€â”€ digital_twin/         # 10Hz Mission Telemetry Clock & ECLSS twin
â”‚   â”œâ”€â”€ hazards/              # Dust storm baroclinic propagation models
â”‚   â”œâ”€â”€ icarus/               # Robotic identity, memory tiers & safety gate
â”‚   â”œâ”€â”€ ml/                   # Random Forest & Gradient Boosted hazard models
â”‚   â”œâ”€â”€ survival/             # Metabolic consumption equations
â”‚   â””â”€â”€ terrain/              # Horn (1981) 3x3 slope & roughness algorithms
â”‚
â”œâ”€â”€ data/                     # Planetary Data Stores & Persistent State
â”‚   â”œâ”€â”€ crew_missions.json    # Ares Expedition V telemetry records
â”‚   â”œâ”€â”€ hazard_simulations.json # Active simulated dust storm tracks
â”‚   â”œâ”€â”€ icarus_memory.json    # Hierarchical long-term memory store
â”‚   â””â”€â”€ brain_config.json     # Multi-provider LLM bridge configuration
â”‚
â”œâ”€â”€ docs/                     # Authoritative Engineering Documentation
â”‚   â”œâ”€â”€ prompts/              # Phase prompts & historical requirements
â”‚   â”œâ”€â”€ architecture/         # Architectural blueprints
â”‚   â”œâ”€â”€ PHASE_1_ARCHITECTURE.md through PHASE_7_ARCHITECTURE.md
â”‚   â”œâ”€â”€ FINAL_TEST_REPORT.md  # Comprehensive test results
â”‚   â”œâ”€â”€ SECURITY_FINDINGS.md  # Security controls & vulnerability audits
â”‚   â””â”€â”€ README.md             # Master Documentation Index
â”‚
â”œâ”€â”€ infrastructure/           # Docker Compose, Nginx & Deployment Configs
â”œâ”€â”€ docker-compose.yml        # Multi-container orchestration
â”œâ”€â”€ start-dev.bat             # Windows one-click development launcher
â””â”€â”€ start-dev.ps1             # PowerShell development launcher
```

---

## ðŸš€ Key Modules & Capabilities

### 1. ICARUS Voice Ops Hub (Tab 13)
- **Live Soundwave Equalizer**: 44-band FFT audio equalizer visualizer powered by HTML5 `<canvas>` and `requestAnimationFrame`. Animates dynamically when ICARUS speaks, settles into a resting baseline in standby, and pulses softly when capturing audio.
- **Microphone Voice Capture**: Native Web Speech API integration (`SpeechRecognition`) for continuous voice capture without typing.
- **Hands-Free Wake-Word Detection**: Listens continuously for *"Hey ICARUS, wake up"*, *"Hey icrus wake up"*, *"wake up icarus"*, or *"wake up"*. Emits an ascending Web Audio synthesizer chime, vocalizes *"ICARUS online, standing by for directive"*, and listens for spoken directives.
- **Hierarchical Memory**: Stores and retrieves memories across Working, Episodic, Semantic, and Procedural tiers with access-frequency tracking.
- **Controlled Automation Safety Gate**: Strict enforcement of Categories A through E with cryptographic anti-replay verification tokens for sensitive actions (e.g. rover dispatch).

### 2. AI Mission Assistant (Tab 11)
- Powered by the **Hybrid Cognitive Brain**.
- Answers complex astrodynamics inquiries (*"How many light years to travel to Mars?"*, *"What is the distance between Earth and the Sun?"*).
- Grounded in real-time Ares Expedition V telemetry, astronaut positions (including Dr. Elena Rostova's separation coordinates), and habitat life-support reserves.
- Non-destructive **What-If simulation engine** for evaluating storm expansions and contingency plans.

### 3. Hazard Intelligence & Dust Storm Simulator (Tab 9 & 10)
- Configurable baroclinic dust storm propagation engine.
- Multi-layer geographic risk mapping: Slope, Roughness, Optical Depth ($\tau$), Radiation, and Solar Loss.
- Dynamic route re-planning with risk delta comparisons and flight controller approval gates.
- Machine learning hazard forecasting using trained classification and regression pipelines.

### 4. Ares Digital Twin & Telemetry Stream (Tab 12)
- High-fidelity telemetry engine simulating 6 crew members, rover battery depletion, solar irradiance, habitat pressure, and ECLSS oxygen scrubbers.

---

## ðŸ§ª Testing & Verification

The system includes a 97-test automated verification suite:
```bash
# Run complete Python scientific & cognitive test suite:
processing\.venv\Scripts\python.exe -m unittest discover -s processing/analysis -p "test_*.py"
```
**Result**: `Ran 97 tests in 1.929s. OK (skipped=4)`

Frontend production build verification:
```bash
npm.cmd --prefix frontend run build
```
**Result**: `âœ“ 3576 modules transformed. dist/assets/index-DHVtblwe.js (0 TypeScript errors)`.

---

## ðŸ› ï¸ Quickstart

### Starting the Services (Development Mode)
```powershell
# Run the automated launch script:
.\start-dev.ps1
```
Or start manually:
1. **Backend Server**:
   ```bash
   processing\.venv\Scripts\python.exe backend/server.py
   ```
   *Available on [http://localhost:8081](http://localhost:8081)*
2. **Frontend UI**:
   ```bash
   npm.cmd --prefix frontend run dev
   ```
   *Available on [http://localhost:5180](http://localhost:5180)*

---

## ðŸ”’ Security & Deployment Policy

- **MANDATORY POLICY**: **DO NOT DEPLOY PUBLICLY**. The platform is configured and authorized strictly for isolated local mission exploration and test operations.
- **Injection Protection**: Active safety gate intercepts and neutralizes adversarial prompt injection.
- **Boundary Enforcement**: Arbitrary shell execution and unauthorized host commands are strictly prohibited under ICARUS Category E safety boundaries.

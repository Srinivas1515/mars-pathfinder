# Mars Pathfinder — Phase 7 Architecture: ICARUS — Personal Voice Assistant, Voice Identity & Memory

## 1. Architectural Overview
Phase 7 introduces **ICARUS** (Intelligent Conversational Autonomous Robotic User System): a personalized, voice-controlled mission operations assistant equipped with an original masculine robotic voice identity, biometric speaker verification, hierarchical memory, and controlled computer automation boundaries.

Key functional subsystems:
1. **Robotic Voice Identity & Synthesis (`processing/icarus/identity.py`)**:
   - Original masculine synthetic persona characterized by deep vocal depth (0.88), pitch shift (-2.8 semitones), and metallic resonance ($Q = 0.54$, lowpass filter cutoff ~1872 Hz).
   - Generates exact audio DSP parameters for client-side Web Speech and Web Audio APIs.
2. **Speaker Verification & Biometrics Engine (`processing/icarus/speaker_verification.py`)**:
   - Enrolls multi-sample acoustic templates capturing Fundamental Frequency $F_0$, Spectral Centroid, and Formant Dispersion.
   - Computes weighted Euclidean distance with anti-replay passphrase challenges, requiring match confidence $\ge 0.82$ before emitting temporary authorization tokens.
3. **Hierarchical Memory Engine (`processing/icarus/memory.py`)**:
   - Organizes knowledge into 4 distinct cognitive tiers:
     - **Working Memory**: Short-term conversational context.
     - **Episodic Memory**: Past mission events, anomalies, and operational decisions.
     - **Semantic Memory**: Persistent preferences, callsigns, and technical definitions.
     - **Procedural Memory**: Standard operating procedures, rescue routines, and debrief sequences.
   - Enforces strict tenant isolation per user with disk persistence at `data/icarus_memory.json`.
4. **Controlled Automation Safety Gate (`processing/icarus/automation_gate.py`)**:
   - Partitions actions into strict categories:
     - **Category A**: Application Access (Read status, view telemetry, inspect layers).
     - **Category B**: Personal Workspace (Read approved files, save debrief reports).
     - **Category C**: Browser Access (Search authorized documentation, fetch scientific data).
     - **Category D**: Sensitive Actions (Modify mission records, rover dispatch — requires biometric token).
     - **Category E**: Prohibited Actions (OS security bypass, arbitrary shell execution — unconditionally blocked).

## 2. Directory Structure
```
processing/icarus/
├── __init__.py                  # Unified exports
├── models.py                    # Schemas for profile, biometrics, memory, and permissions
├── identity.py                  # Masculine robotic voice persona & DSP parameter calculator
├── speaker_verification.py      # Voice biometrics matching & anti-replay engine
├── memory.py                    # Hierarchical 4-tier memory engine with disk persistence
├── automation_gate.py           # Privilege category (A-E) boundary enforcer
└── engine.py                    # ICARUSEngine Singleton Coordinator
```

## 3. PostgreSQL/PostGIS Schema
Migration file: `backend/migrations/009_icarus_system.sql`
- `icarus_user_profiles`: User preferences, callsigns, voice synthesis configurations.
- `icarus_voice_templates`: Biometric acoustic feature templates ($F_0$, spectral centroid, formant dispersion).
- `icarus_memory_records`: Tiered memory items with access telemetry and confidence metrics.
- `icarus_action_authorizations`: Action authorizations, confirmation tokens, and verification status.
- `icarus_audit_logs`: Query phrases, intents, match scores, and executed actions.

## 4. REST API Endpoints
- `POST /api/v1/icarus/voice/interact`
- `GET /api/v1/icarus/profile`
- `POST /api/v1/icarus/auth/verify-speaker`
- `GET /api/v1/icarus/memory`
- `POST /api/v1/icarus/memory/save`
- `DELETE /api/v1/icarus/memory/:id`
- `POST /api/v1/icarus/actions/authorize`

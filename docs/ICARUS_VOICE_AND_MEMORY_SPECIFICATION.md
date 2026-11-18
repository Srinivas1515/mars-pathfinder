# Mars Pathfinder — ICARUS Voice Identity & Memory Specification

## 1. Persona & Acoustic Engineering
ICARUS (Intelligent Conversational Autonomous Robotic User System) is modeled with an original masculine synthetic vocal identity:
- **Fundamental Pitch**: Tuned to deep baritone/bass registers (Web Speech pitch parameter $0.75 - 0.82$).
- **Speech Rate**: Standardized at $0.95$ for deliberate, analytical clarity under operational stress.
- **Acoustic Formants**: Lowpass cutoff at $\sim 1872$ Hz combined with peaking resonance at 180 Hz ($+4.5$ dB bass boost) and subtle metallic ring ($Q = 0.54$) to produce a cinematic robotic texture.
- **Delivery**: Highly concise, objective, calm, and mission-oriented.

## 2. Speaker Verification & Biometric Boundaries
1. **Enrollment**: Multi-pass acoustic feature vector enrollment capturing Fundamental Frequency ($F_0$), Spectral Centroid, and Formant Dispersion.
2. **Threshold**: Verification confidence score must exceed $0.82$ for token issuance.
3. **Anti-Replay**: Requires dynamic passphrase matching; static or cached audio recordings fail anti-replay inspection.
4. **Convenience vs Security**: Voice verification authorizes convenience actions and stages sensitive commands, but high-impact mission overrides require explicit flight director confirmation tokens.

## 3. Cognitive Memory Hierarchy
| Memory Tier | Retention Scope | Storage Location | Example Key / Content |
| :--- | :--- | :--- | :--- |
| **Working** | Current session context | In-memory session state | Active selected entity, current query intent |
| **Episodic** | Historical mission milestones | `data/icarus_memory.json` | Sol 14.5 Dr. Rostova separation & rescue dispatch |
| **Semantic** | User preferences & terms | `data/icarus_memory.json` | Callsign preference: "Ares Flight", voice settings |
| **Procedural** | Operational protocols | `data/icarus_memory.json` | Ridge Pass Echo rescue sequence priority rule |

## 4. Automation Permission Categories
- **Category A (Application Access)**: Unrestricted inside normal user role (read telemetry, status, map layers).
- **Category B (Personal Workspace)**: Scoped to user workspace (read approved files, export debrief).
- **Category C (Browser Access)**: Scoped to approved NASA/PDS documentation sources.
- **Category D (Sensitive Actions)**: Modifying mission state, staging rover dispatch. Requires biometric verification token.
- **Category E (Prohibited Actions)**: Arbitrary shell execution (`/bin/sh`, `exec`, `sudo`), OS security bypass. Strictly and unconditionally blocked.

# Mars Pathfinder — Development Backlog & Future Optimizations

This document records non-blocking improvements, future optimizations, and post-foundation enhancements identified during the completion and validation of Phases 1 through 7 and the final security audit.

All core functional requirements across Phases 1 through 7 are **100% complete, tested, and operational**.

---

## 1. Post-Release Security & Hardening Roadmap (Required Prior to Public Internet Exposure)

As documented in [SECURITY_FINDINGS.md](file:///c:/mars-pathfinder/docs/SECURITY_FINDINGS.md), the application release decision is currently **DO NOT DEPLOY PUBLICLY**. To authorize future public or cloud deployment, the following hardening steps are scheduled:

1. **Authentication & Role-Based Access Control (RBAC)**:
   - Implement OpenID Connect (OIDC) / OAuth2 authentication for all REST API endpoints (`/api/v1/*`).
   - Introduce granular role-based tokens distinguishing Mission Flight Controllers (`ROLE_FLIGHT_CONTROLLER`), Science Analysts (`ROLE_SCIENTIST`), Field Astronauts (`ROLE_ASTRONAUT`), and Read-Only Observers (`ROLE_PUBLIC`).
2. **Reverse Proxy TLS Termination & Hardened Headers**:
   - Enforce HTTPS across all traffic with TLS 1.3 only, HTTP Strict Transport Security (`HSTS: max-age=63072000; includeSubDomains; preload`).
   - Implement restrictive Content Security Policy (`CSP`), eliminating `'unsafe-inline'` where possible.
3. **Upgrade Pinned Dependencies with Known Advisories**:
   - Upgrade `zod` to `>= 4.6.6` once the downstream schema bindings in the React app are verified for non-breaking API changes.
4. **Rate Limiting & Anti-DDoS**:
   - Deploy token bucket rate limiters (e.g. 100 requests/minute per client IP) on computationally intensive endpoints such as `/api/v1/mission/plan`, `/api/v1/ml/predict/*`, and `/api/v1/icarus/voice/interact`.

---

## 2. Non-Blocking Scientific & Mapping Refinements

- **Interactive Polar Stereographic 2D Pan/Zoom Widget**:
  - *Context*: Official PDS polar stereographic MOLA topography (`MEGT_N_128_1.IMG`, `MEGT_S_128_1.IMG`) is documented and parsed by the scientific processing engine. Real-time dynamic switching between Equirectangular and Polar Stereographic projections in OpenLayers 2D map view is supported via layer toggle.
  - *Plan*: Implement dynamic projection re-binding or a dedicated dual-view polar inset widget for high-latitude exploration ($|\text{lat}| > 80^\circ$).

- **Quantized-Mesh Martian 3D Terrain Provider for Cesium**:
  - *Context*: Cesium currently renders high-resolution NASA WMTS color shaded relief and imagery on the IAU 2000 Mars sphere ($R = 3,396,190\text{ m}$).
  - *Plan*: Pre-generate quantized-mesh 3D terrain tiles directly from MOLA MEGDR 128 ppd DEM for true volumetric 3D vertex elevation extrusion in CesiumJS.

- **Dynamic HiRISE / CTX Local High-Resolution Overlays**:
  - *Context*: MOLA MEGDR provides regional macro-topography (4 ppd to 128 ppd).
  - *Plan*: Ingest NASA Trek local high-resolution HiRISE DTMs (up to $0.25\text{ m/pixel}$) and CTX mosaics ($6\text{ m/pixel}$) for specific landing ellipses (e.g. Jezero crater delta fan).

---

## 3. Advanced AI & Machine Learning Scaling

- **On-Device WebAssembly Inference**:
  - *Context*: ML models (Models 1–6) run on the Python backend with zero temporal leakage and explainable SHAP attributions.
  - *Plan*: Export the lightweight HiRISE patch classifier and traversability models to ONNX / TF.js for sub-millisecond on-device edge evaluation in the astronaut's browser without network latency.

- **Streaming Voice Synthesis (Audio Worklet)**:
  - *Context*: The ICARUS voice assistant generates robotic vocal identity features with biometric template matching.
  - *Plan*: Implement browser-side Web Audio API AudioWorklet processors for streaming real-time voice synthesis and zero-latency pitch/formant robotic rendering.

---

## 4. Performance & Infrastructure Improvements

- **Frontend Code Splitting & Dynamic Imports**:
  - *Context*: Production build compiles Cesium, OpenLayers, and all 13 hub workspaces into an optimized production bundle.
  - *Plan*: Implement `React.lazy()` dynamic chunking for heavy 3D globe assets to further decrease initial page load time on low-bandwidth satellite links.

- **Python Scientific Worker Process Daemon Pool**:
  - *Context*: Go Fiber backend invokes Python processing tasks via fast subprocess invocation.
  - *Plan*: Implement a persistent Unix socket / named pipe worker daemon pool for the scientific worker under high-concurrency production deployments.

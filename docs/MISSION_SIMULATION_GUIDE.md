# Mars Pathfinder — Mission Operations & Simulation User Guide

> **DOCUMENT CLASSIFICATION: OPERATIONAL FLIGHT MANUAL**  
> **MISSION SUITE: MARS MISSION OPERATIONS & CREW SAFETY (PHASE 2)**  
> **OPERATIONAL TARGET: ARES EXPEDITION V / JEZERO CRATER**  

---

## 1. Introduction & Mission Controller Overview

The **Mars Mission Operations Hub** provides planetary flight controllers, mission specialists, and aerospace engineers with a unified console to:
- Monitor astronaut spatial locomotion, velocity, and bearings on the Martian surface.
- Track biometric vitals and spacesuit consumable levels.
- Receive automated separation warnings when squad members exceed safe proximity thresholds.
- Inject simulated Martian environmental and mechanical contingencies (Scenarios A through F).
- Evaluate and authorize six candidate rescue and reunification strategies.
- Maintain human-in-the-loop operational oversight with explainable AI recommendations.

---

## 2. Navigating the Mission Operations Console

Access the console by selecting the **Mission Operations** tab in the main top navigation bar (`http://localhost:5180` / `activeTab === "crew_ops"`).

The console provides **ten dedicated sub-workspaces**:

1. **Mission Overview (`overview`):** Top-level mission status, simulation elapsed time (Sol counter), rover transport class, and quick KPI summary cards.
2. **Crew Management (`roster`):** Complete crew roster table with names, roles, suit IDs, coordinates, and tools to deploy new astronaut candidates.
3. **Locomotion Tracking (`tracking`):** Geodesic coordinates, elevation, velocity vectors, and separation proximity circles.
4. **Crew Health & Suits (`telemetry`):** Physiological biosensors (heart rate, $\text{SpO}_2$, core temperature) and spacesuit telemetry ($\text{O}_2\%$, pressure, battery).
5. **Emergency Scenarios (`scenarios`):** Contingency injection deck covering Scenarios A through F with severity options.
6. **Rescue & Reunification (`rescue`):** Parallel comparison of 6 rescue strategies with distance, time, and terrain risk scores.
7. **Consumables & Margin (`resources`):** Oxygen, water, food, and battery reserves with dynamic depletion projections.
8. **RF Mesh Network (`comms`):** Multi-hop communications topology across suits, rovers, habitat mast, and orbiters.
9. **Timeline & Replay (`timeline`):** Chronological event stream with category filters.
10. **AI Mission Assistant (`assistant`):** Multi-variable decision explanations and flight controller confirmation buttons.

---

## 3. Controlling the Simulation Clock

The simulation clock advances astronaut surface traverse, metabolic life-support consumption, and battery drainage:

- **Run Simulation:** Starts the simulation clock at $1.0\times$ speed.
- **Pause Clock:** Suspends clock advance to permit detailed situational analysis.
- **Step Simulation (+60s, +300s, +900s, +3600s):** Advances the surface clock by a discrete interval, stepping spatial locomotion, vital sign changes, and consumable burn.
- **Reset (Sol 0):** Reverts crew members to their initial landing base positions, restores full $\text{O}_2$ and battery reserves, and clears active contingency scenarios.

---

## 4. Deploying Variable Crew Complements

The platform supports variable crew sizes (e.g. 2, 4, 5, 6, 8, or 12 astronauts):

1. Click **"+ Plan New Expedition"** from the top right bar.
2. Set the **Expedition Title** (e.g., *Ares Expedition VI*).
3. Adjust the **Variable Crew Complement slider** (from 2 to 12 astronauts).
4. Enter the **Landing Latitude** and **Longitude**.
5. Define the **Primary Surface Objective**.
6. Click **"Initialize Mission"** to generate the crew roster and deploy the mission.

To add individual astronaut candidates to an active mission:
1. Navigate to the **Crew Management** tab.
2. Click **"Deploy Astronaut"**.
3. Specify full name, mission role, suit serial number, and assigned scientific equipment.
4. Click **"Deploy Astronaut"** to save to the database.

---

## 5. Injecting Emergency Contingencies (Scenarios A through F)

To test contingency response protocols:

1. Open the **Emergency Scenarios** tab.
2. Select one of the six contingency scenarios:
   - **Scenario A:** Regional Dust Storm & Optical Opacity Spike ($\tau > 3.5$).
   - **Scenario B:** Astronaut Orthopedic Trauma & Tachycardia.
   - **Scenario C:** Topographic Shielding & Direct RF Blackout.
   - **Scenario D:** Critical Suit Envelope Puncture & $\text{O}_2$ Leak.
   - **Scenario E:** Rover Drive Actuator Jamming in Talus.
   - **Scenario F:** Compound Dust Storm, Injury, and Comms Degradation.
3. Choose the **Severity Level** (`MINOR`, `MODERATE`, `CRITICAL`).
4. Select the **Primarily Affected Astronaut**.
5. Click **"Inject Emergency Scenario"**.

Upon injection:
- The affected astronaut's vitals and suit status update immediately.
- Relevant physiological alarms trigger.
- The separation and safety monitors recalculate risk.
- The Rescue Planner automatically generates updated candidates for all 6 strategies.
- The AI Mission Assistant synthesizes explainable decision recommendations.

---

## 6. Evaluating and Authorizing Rescue Strategies

1. Navigate to the **Rescue & Reunification** tab.
2. Review the 6 generated candidate strategies:
   - *Shortest-Distance Traverse*
   - *Lowest-Terrain-Risk Route*
   - *Lowest-Resource Route*
   - *Emergency Medical Sprint*
   - *Centroid Crew Reunification*
   - *Return-to-Base Abort*
3. Compare distance ($\text{km}$), transit time ($\text{hrs}$), terrain risk ($/100$), and required $\text{O}_2$ liters.
4. Click on any strategy card to inspect its full **Waypoint Trajectory Profile** (sequence, elevation, slope, and ETA).
5. In the **AI Mission Assistant** tab, review the algorithmic risk rationale and tradeoffs.
6. Click **"Authorize & Execute Strategy"** to confirm flight controller authorization.

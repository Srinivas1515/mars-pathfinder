# Mars Pathfinder — Mars Digital Twin Specification

## 1. Scope & System Definition
The Mars Digital Twin represents a unified operational mirror of a human Mars surface mission. It integrates high-resolution MOLA topography, rover kinematics, astronaut physiological telemetry, ECLSS atmospheric and consumable inventories, and orbital communications.

## 2. Chronological Standards
1. **Martian Sol Constant**: Defined as strictly $88775.244$ SI seconds ($24\text{h } 39\text{m } 35.244\text{s}$).
2. **Solar Longitude ($L_s$)**: Expressed in degrees ($0^\circ - 360^\circ$) representing Martian seasonal orbital position ($L_s = 0^\circ$ Northern vernal equinox; $L_s = 250^\circ$ perihelion dust storm peak).
3. **Local True Solar Time (LTST)**: Expressed in 24 Martian solar hours where 12:00:00 corresponds to local solar noon at the landing site meridian.
4. **Time Separation Rule**: UTC timestamps are strictly maintained for Earth communication ground tracking, and never conflated with Martian Sol elapsed time.

## 3. Standard Scenario Suite (Controlled Comparisons)
| Scenario | Designation | Perturbation Description | Key Risk Indicator |
| :--- | :--- | :--- | :--- |
| **Scenario A** | Baseline Nominal | Standard 30-Sol exploration plan; moderate weather | Hazard score 14.2 / 100 |
| **Scenario B** | Early Dust Storm | Optical depth spike $\tau > 2.0$ on Sol 14.4; solar recharge down 65% | Hazard score 68.5 / 100 |
| **Scenario C** | MRO Comm Blackout | UHF line-of-sight loss; autonomous rover mesh fallback | Peak separation 6.5 hrs |
| **Scenario D** | Astronaut Injury | AST-03 sprained ankle on boulder field; evacuation required | Walking speed 0.8 km/h |
| **Scenario E** | Battery Degradation | Sub-zero thermal degradation limits rover radius to 25 km | Power depletion risk |
| **Scenario F** | Ridge Pass Detour | Topographically sheltered ridgeline rescue route | Hazard score 11.8 / 100 (Recommended) |

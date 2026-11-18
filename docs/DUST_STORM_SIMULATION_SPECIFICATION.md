# Mars Pathfinder — Dust Storm Simulation Specification

## 1. Scope & Scientific Intent

This document establishes the scientific physics formulation, parameters, and time evolution equations powering the **Mars Dust Storm Simulator** in Mars Pathfinder Phase 3.

The simulator provides deterministic, physically grounded modeling of Martian dust storm genesis, radial expansion, advection, optical opacity ($\tau$), surface solar flux curtailment, RF link attenuation, and atmospheric thermal damping.

---

## 2. Spherical Geodesic Advection Model

The displacement of the dust storm center over time step $\Delta t$ is computed using spherical trigonometry on the mean Martian sphere ($R_{mars} = 3,389.5\text{ km}$):

Given initial center $(\phi_1, \lambda_1)$ in radians, bearing angle $\theta$ (degrees clockwise from True North), and drift speed $v_{drift}\text{ (km/h)}$:
$$d = v_{drift} \cdot \Delta t$$
$$\delta = \frac{d}{R_{mars}}$$
$$\phi_2 = \arcsin\left(\sin\phi_1 \cos\delta + \cos\phi_1 \sin\delta \cos\theta\right)$$
$$\lambda_2 = \lambda_1 + \operatorname{atan2}\left(\sin\theta \sin\delta \cos\phi_1, \; \cos\delta - \sin\phi_1 \sin\phi_2\right)$$
$$\lambda_2 = \operatorname{normalize}_{[-180, +180]}(\lambda_2)$$

---

## 3. Radial Optical Depth Profile $\tau(r)$

The storm envelope is divided into a high-opacity convective core ($r \le R_{core} = 0.35 \cdot R_{outer}$) and a peripheral particulate diffuse zone:

$$\tau(r) = \begin{cases}
\tau_{peak} & r \le R_{core} \\
\tau_{ambient} + (\tau_{peak} - \tau_{ambient}) \cdot \exp\left(-2.2 \cdot \left(\frac{r - R_{core}}{R_{outer} - R_{core}}\right)^2\right) & R_{core} < r \le R_{outer} \\
\tau_{ambient} \approx 0.40 & r > R_{outer}
\end{cases}$$

---

## 4. Radiative Transfer & Power Loss

Surface solar insolation under suspended silicate aerosols follows the Beer-Lambert law:
$$I = I_0 \cdot \exp\left(-\frac{\tau}{\cos\theta_z}\right)$$
Where $\theta_z$ is the solar zenith angle (calibrated at $\cos\theta_z \approx 0.707$ for nominal mid-day Martian insolation).

The photovoltaic power loss percentage is:
$$\Delta P_{loss}\% = \min\left(99.5\%, \; \left(1.0 - \exp\left(-\frac{\tau}{0.707}\right)\right) \times 100\%\right)$$

---

## 5. RF Signal Attenuation Model

Electromagnetic wave propagation through Martian suspended dust particles (UHF and X-band communications):
$$A_{dB} = \min\left(45.0\text{ dB}, \; 1.8 \cdot \tau + 0.15 \cdot \left(\frac{v_{wind}}{10.0}\right)^{1.5}\right)$$

---

## 6. Predefined Benchmark Scenarios

| Scenario Code | Scenario Name | Target Region | Initial Radius | Max Radius | Peak $\tau$ | Peak Wind | Sols | Historical Event / Model |
|---|---|---|---|---|---|---|---|---|
| `MY34_GLOBAL_STORM` | 2018 Planet-Encircling Dust Event | Global Mars (Endeavour/Jezero) | 350 km | 3800 km | 8.5 | 34 m/s | 60 | Martian Year 34 $L_s$ 185-260 (Opportunity Mission Loss) |
| `MY28_GLOBAL_STORM` | 2007 Global Dust Storm | Global Mars (Meridiani/Gusev) | 280 km | 3200 km | 5.2 | 28.5 m/s | 45 | Martian Year 28 $L_s$ 260-310 (Survived by MER Spirit & Opportunity) |
| `JEZERO_REGIONAL_SQUALL` | Jezero Delta Mesoscale Squall | Jezero Crater & Isidis | 75 km | 450 km | 3.8 | 29 m/s | 8 | Perseverance MEDA Sol 210 Event Model |
| `GALE_CRATER_INVERSION` | Mount Sharp Slope Wind Trap | Gale Crater (Aeolis Mons) | 45 km | 180 km | 1.9 | 21 m/s | 5 | Curiosity REMS Microclimate Inversion |
| `HELLAS_DEPRESSION_STORM` | Hellas Deep Basin Dust Engine | Hellas Planitia Basin | 250 km | 1400 km | 4.5 | 32 m/s | 20 | Viking & Mars Express Inflow Observations |

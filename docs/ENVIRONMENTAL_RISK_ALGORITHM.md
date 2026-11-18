# Mars Pathfinder — Environmental Risk Algorithm Specification

## 1. Algorithm Overview

The Environmental Risk Engine calculates an explainable composite risk index $S \in [0.0, 100.0]$ representing overall operational danger to surface assets (human crew and robotic rovers).

The algorithm enforces:
1. Multi-factor normalization into $[0, 100]$.
2. Normalized scientific weighting ($\sum w_i = 1.00$).
3. Full explainability: raw metric, unit, score, weighted contribution, and data source.
4. Composite uncertainty propagation via root sum square.
5. **Strict missing observation safeguards**: missing data never defaults to zero risk.

---

## 2. Risk Layer Formulations

### Layer 1: Atmospheric Opacity & Dynamic Buffeting ($w_1 = 0.22$)
$$s_{atm} = 0.6 \cdot \min\left(100.0, \frac{\tau}{5.0} \times 100\right) + 0.4 \cdot \min\left(100.0, \frac{v_{wind}}{35.0} \times 100\right)$$
- If sensor offline: $s_{atm} = 48.0$ (conservative baseline), uncertainty $\sigma = \pm 38\%$.

### Layer 2: Topographic Slope & Surface Roughness ($w_2 = 0.24$)
$$s_{surf} = 100.0 - T_{trafficability}$$
Where $T_{trafficability} \in [0, 100]$ is the vehicle-specific mobility trafficability score computed from MOLA slope gradient $\theta_{slope}$ and RMS roughness $h_{rms}$.
- If MOLA altimetry missing: $s_{surf} = 55.0$, uncertainty $\sigma = \pm 35\%$.

### Layer 3: Space Radiation & Atmospheric Shielding ($w_3 = 0.18$)
$$s_{rad} = \min\left(100.0, \frac{\dot{D}}{0.050\text{ mSv/h}} \times 100\right)$$
Where surface dose rate $\dot{D} = \frac{0.010}{\sigma_{shield}}$ depends on atmospheric column mass $\sigma_{shield} = \max(0.6, 1.0 - z_{elev}\cdot 0.04)$.
- If dosimeter offline: $s_{rad} = 42.0$, uncertainty $\sigma = \pm 40\%$.

### Layer 4: Solar Photovoltaic Generation Curtailment ($w_4 = 0.16$)
$$s_{solar} = \min(100.0, \Delta P_{loss}\%)$$
- If pyranometer offline: $s_{solar} = 50.0$, uncertainty $\sigma = \pm 30\%$.

### Layer 5: RF Communications Shadow & Attenuation ($w_5 = 0.10$)
$$s_{comms} = \min\left(100.0, \frac{A_{loss,dB}}{30.0\text{ dB}} \times 100\right)$$
Includes $+8.0\text{ dB}$ topographic obstruction penalty if distance to crater rim $< 3.0\text{ km}$.
- If transponder offline: $s_{comms} = 52.0$, uncertainty $\sigma = \pm 35\%$.

### Layer 6: Cryogenic Cold Stress & Life Support Load ($w_6 = 0.10$)
$$s_{op} = \min\left(100.0, \max\left(0.0, \frac{-60^\circ\text{C} - T_{min}}{50^\circ\text{C}}\right) \times 60.0 + (E_{multiplier} - 1.0) \times 20.0\right)$$
- If thermal suite offline: $s_{op} = 45.0$, uncertainty $\sigma = \pm 30\%$.

---

## 3. Composite Uncertainty Formulation

Total composite risk uncertainty $\sigma_{comp}$ is computed using weighted root sum square:
$$\sigma_{comp} = \sqrt{\sum_{i=1}^6 \left(w_i \cdot \frac{\sigma_i}{100.0}\right)^2} \times 100\%$$

When all sensors are nominal, $\sigma_{comp} \approx \pm 4.5\% - \pm 8.0\%$. When sensor streams drop offline, $\sigma_{comp}$ expands to $\pm 18.0\% - \pm 35.0\%$, alerting mission operators to data degradation.

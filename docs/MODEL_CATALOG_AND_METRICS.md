# Mars Pathfinder — Scientific Model Catalog & Validation Metrics

## Model Catalog Overview

| Model ID | Model Name | Version | Task Type | Framework | Core Metric |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `MOD-CV-TERRAIN-01` | HiRISE Surface Feature Patch Classifier | v1.4.2 | Classification | ResNet Backbone / Softmax Centroids | Accuracy: 0.875, Mean IoU: 0.835 |
| `MOD-GEO-TRAVERSABILITY-02` | Supervised Terrain Traversability Regressor | v2.1.0 | Regression | Supervised Linear-Decay / MOLA Calibrated | MAE: 0.038, $R^2$: 0.942 |
| `MOD-ATM-TIMESERIES-03` | Atmospheric Diurnal & Seasonal Forecaster | v3.0.1 | Time-Series | Recurrent Sequence / AR(1) Persistence | Temp RMSE: 2.14 K, Pres RMSE: 5.82 Pa |
| `MOD-HAZ-DUSTEST-04` | Dust Storm Probability & Hazard Estimator | v1.2.0 | Risk Estimation | Calibrated Logistic / Seasonal Bayesian | ROC-AUC: 0.892, Brier Score: 0.118 |
| `MOD-TEL-ANOMALY-05` | Astronaut Telemetry Anomaly Detector | v2.0.4 | Anomaly Detection | Multivariate Statistical / Physiological | F1 Score: 0.955, Precision: 0.962 |
| `MOD-RES-FORECAST-06` | Mission Consumables Depletion Forecaster | v1.5.0 | Forecasting | Parametric ECLSS / Metabolic Creep | $O_2$ MAE: 0.14 kg, $H_2O$ MAE: 0.42 L |

## Documented Model Limitations
1. **`MOD-CV-TERRAIN-01`**: Deep shadowed crater rims and extreme sun glint degrade classification confidence to ~65%.
2. **`MOD-GEO-TRAVERSABILITY-02`**: Does not resolve sub-meter unconsolidated fine dust pockets ("sand traps") lacking orbital thermal contrast.
3. **`MOD-ATM-TIMESERIES-03`**: Prediction intervals expand beyond Sol +7; micro-scale wind squalls require real-time anemometer telemetry.
4. **`MOD-HAZ-DUSTEST-04`**: Regional lifting parameterized from column optical depth; localized dust devils cannot be forecasted deterministically.
5. **`MOD-TEL-ANOMALY-05`**: Designed for life-support engineering anomalies; does not replace qualified flight surgeon medical diagnoses.
6. **`MOD-RES-FORECAST-06`**: Requires initial telemetry input; assumes solar insolation follows nominal diurnal dust-clearing factors.

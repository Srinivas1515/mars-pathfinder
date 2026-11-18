# Mars Pathfinder — Phase 4 Architecture: Machine Learning & Predictive Analytics

## 1. Architectural Overview
Phase 4 introduces an MLOps-governed, scientifically validated machine learning and predictive analytics platform into the Mars Pathfinder ecosystem.
The platform combines 6 specialized planetary models:
1. **Model 1 (`MOD-CV-TERRAIN-01`)**: Computer vision surface feature patch classifier (HiRISE surface features: rocky, sand-covered, crater, boulder field, cliff, slope, flat, geological formation).
2. **Model 2 (`MOD-GEO-TRAVERSABILITY-02`)**: Supervised terrain traversability regressor and risk estimator with feature attribution (slope, roughness, elevation, texture).
3. **Model 3 (`MOD-ATM-TIMESERIES-03`)**: Martian atmospheric diurnal and seasonal time-series forecaster with 95% confidence intervals and autoregressive baseline comparisons.
4. **Model 4 (`MOD-HAZ-DUSTEST-04`)**: Regional dust storm probability and hazard risk estimator.
5. **Model 5 (`MOD-TEL-ANOMALY-05`)**: Multi-variate life-support and astronaut EVA suit anomaly detector.
6. **Model 6 (`MOD-RES-FORECAST-06`)**: Mission consumables depletion forecaster ($O_2, H_2O$, battery storage) with thermodynamic baseline benchmarking.

## 2. Directory Structure
```
processing/ml/
├── __init__.py                  # Unified exports
├── models.py                    # Pydantic schemas, data provenance, request/response models
├── datasets.py                  # Mars dataset loaders and time-aware splitters
├── terrain_classifier.py        # Model 1: Surface Patch Classifier
├── traversability_model.py      # Model 2: Traversability Regressor
├── atmospheric_forecaster.py    # Model 3: Atmospheric Time-Series Forecaster
├── hazard_estimator.py          # Model 4: Dust Hazard Risk Estimator
├── anomaly_detector.py          # Model 5: Telemetry Anomaly Detector
├── resource_forecaster.py       # Model 6: Consumables Forecaster
├── registry.py                  # MLOps Model Registry and Evaluation Reports
└── engine.py                    # MLEngine Singleton Coordinator
```

## 3. Mandatory Scientific Safeguards
- **Zero Temporal Leakage**: Enforced through `MarsDatasetRegistry.time_aware_train_test_split()`, which partitions Sol observations chronologically without cross-temporal shuffle contamination.
- **Data Provenance Classification**: Explicit visual provenance badges distinguish `OBSERVED`, `DERIVED`, `MODELLED`, `PREDICTED`, `SIMULATED`, and `UNAVAILABLE`.
- **Explainability**: Traversability scores include percentage feature attribution breakdowns; hazard estimations expose calibrated 95% confidence bounds.
- **Physical Baseline Comparison**: Consumables forecasts and atmospheric projections explicitly benchmark ML estimations against deterministic thermodynamic baselines.

## 4. PostgreSQL/PostGIS Schema
Migration file: `backend/migrations/006_machine_learning.sql`
- `ml_models`: Model catalog, task types, frameworks, drift status, versioning.
- `ml_datasets`: Source catalogs, sample counts, Sol cutoff horizons.
- `ml_training_runs`: Training run telemetry, hyperparams, validation/test metrics.
- `ml_evaluation_results`: Scientific evaluation benchmarks, metric values, confidence bounds.
- `ml_predictions`: Prediction audit logs, input feature payloads, inferred labels.
- `ml_inference_logs`: Latency metrics, HTTP status codes, error traces.

## 5. REST API Endpoints
- `GET /api/v1/ml/models`
- `GET /api/v1/ml/models/:id`
- `POST /api/v1/ml/predict/terrain`
- `POST /api/v1/ml/predict/traversability`
- `POST /api/v1/ml/predict/atmosphere`
- `POST /api/v1/ml/predict/hazard`
- `POST /api/v1/ml/anomalies/detect`
- `POST /api/v1/ml/forecast/resources`
- `GET /api/v1/ml/evaluations`

-- 006_machine_learning.sql
-- Mars Pathfinder Phase 4: Machine Learning & Predictive Analytics Schema

CREATE TABLE IF NOT EXISTS ml_models (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    version VARCHAR(32) NOT NULL,
    category VARCHAR(64) NOT NULL, -- 'terrain_vision', 'traversability', 'atmosphere_ts', 'hazard_risk', 'anomaly_detection', 'resource_forecast'
    task_type VARCHAR(64) NOT NULL, -- 'classification', 'regression', 'time_series', 'anomaly', 'forecasting'
    framework VARCHAR(64) NOT NULL, -- 'scikit-learn', 'pytorch', 'xgboost', 'statistical_baseline'
    description TEXT,
    input_schema JSONB NOT NULL DEFAULT '{}'::jsonb,
    output_schema JSONB NOT NULL DEFAULT '{}'::jsonb,
    metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
    drift_status VARCHAR(32) NOT NULL DEFAULT 'NOMINAL', -- 'NOMINAL', 'MONITORED', 'DRIFT_DETECTED'
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ml_datasets (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    version VARCHAR(32) NOT NULL,
    source VARCHAR(128) NOT NULL, -- 'NASA_HIRISE', 'MOLA_MEGDR', 'MEDA_REMS', 'SYNTHETIC_TELEMETRY'
    num_samples INTEGER NOT NULL,
    temporal_split_cutoff VARCHAR(64),
    features JSONB NOT NULL DEFAULT '[]'::jsonb,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ml_training_runs (
    id VARCHAR(64) PRIMARY KEY,
    model_id VARCHAR(64) REFERENCES ml_models(id) ON DELETE CASCADE,
    dataset_id VARCHAR(64) REFERENCES ml_datasets(id) ON DELETE CASCADE,
    run_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    epochs INTEGER DEFAULT 100,
    hyperparams JSONB NOT NULL DEFAULT '{}'::jsonb,
    validation_metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
    test_metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
    artifact_uri VARCHAR(256),
    status VARCHAR(32) NOT NULL DEFAULT 'COMPLETED'
);

CREATE TABLE IF NOT EXISTS ml_evaluation_results (
    id VARCHAR(64) PRIMARY KEY,
    model_id VARCHAR(64) REFERENCES ml_models(id) ON DELETE CASCADE,
    run_id VARCHAR(64) REFERENCES ml_training_runs(id) ON DELETE CASCADE,
    metric_name VARCHAR(64) NOT NULL,
    metric_value DOUBLE PRECISION NOT NULL,
    confidence_interval JSONB DEFAULT '{"lower": 0.0, "upper": 1.0}'::jsonb,
    evaluated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ml_predictions (
    id VARCHAR(64) PRIMARY KEY,
    model_id VARCHAR(64) REFERENCES ml_models(id) ON DELETE CASCADE,
    model_version VARCHAR(32) NOT NULL,
    input_features JSONB NOT NULL,
    prediction_result JSONB NOT NULL,
    confidence DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    classification_label VARCHAR(64), -- e.g. 'ROCKY', 'PASSABLE', 'ANOMALY', 'NOMINAL'
    provenance_classification VARCHAR(32) NOT NULL DEFAULT 'PREDICTED', -- 'OBSERVED', 'DERIVED', 'MODELLED', 'PREDICTED', 'SIMULATED'
    inferred_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ml_inference_logs (
    id BIGSERIAL PRIMARY KEY,
    model_id VARCHAR(64) REFERENCES ml_models(id) ON DELETE CASCADE,
    latency_ms DOUBLE PRECISION NOT NULL,
    status_code INTEGER NOT NULL DEFAULT 200,
    error_message TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ml_models_category ON ml_models(category);
CREATE INDEX IF NOT EXISTS idx_ml_predictions_model ON ml_predictions(model_id, inferred_at DESC);
CREATE INDEX IF NOT EXISTS idx_ml_inference_logs_model ON ml_inference_logs(model_id, timestamp DESC);

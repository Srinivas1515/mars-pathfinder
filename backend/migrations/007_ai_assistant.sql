-- 007_ai_assistant.sql
-- Mars Pathfinder Phase 5: AI Mission Assistant & Autonomous Decision-Support Schema

CREATE TABLE IF NOT EXISTS assistant_recommendations (
    id VARCHAR(64) PRIMARY KEY,
    mission_id VARCHAR(64) NOT NULL,
    situation TEXT NOT NULL,
    evidence JSONB NOT NULL DEFAULT '[]'::jsonb,
    data_source VARCHAR(128) NOT NULL,
    observation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    risk_level VARCHAR(32) NOT NULL, -- 'LOW', 'MODERATE', 'HIGH', 'CRITICAL'
    recommended_action TEXT NOT NULL,
    alternative_action TEXT,
    expected_consequences TEXT,
    uncertainty_score DOUBLE PRECISION NOT NULL DEFAULT 0.1,
    safety_tier VARCHAR(32) NOT NULL DEFAULT 'RECOMMENDATION', -- 'INFORMATION_ONLY', 'RECOMMENDATION', 'SIMULATION_ACTION', 'REQUIRES_HUMAN_APPROVAL', 'NOT_AUTHORIZED'
    approved_by_user BOOLEAN DEFAULT NULL,
    approval_timestamp TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS assistant_scenarios (
    id VARCHAR(64) PRIMARY KEY,
    base_mission_id VARCHAR(64) NOT NULL,
    scenario_name VARCHAR(128) NOT NULL,
    parameters JSONB NOT NULL DEFAULT '{}'::jsonb,
    simulated_state JSONB NOT NULL DEFAULT '{}'::jsonb,
    comparison_results JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS assistant_tool_executions (
    id BIGSERIAL PRIMARY KEY,
    tool_name VARCHAR(64) NOT NULL,
    input_parameters JSONB NOT NULL DEFAULT '{}'::jsonb,
    output_summary JSONB NOT NULL DEFAULT '{}'::jsonb,
    executed_by VARCHAR(64) NOT NULL DEFAULT 'AI_ASSISTANT',
    execution_latency_ms DOUBLE PRECISION NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'SUCCESS',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS assistant_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    query TEXT NOT NULL,
    intent VARCHAR(64) NOT NULL,
    context_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
    tools_invoked JSONB NOT NULL DEFAULT '[]'::jsonb,
    response_text TEXT NOT NULL,
    safety_classification VARCHAR(32) NOT NULL DEFAULT 'INFORMATION_ONLY',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_assistant_recommendations_mission ON assistant_recommendations(mission_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_assistant_scenarios_base ON assistant_scenarios(base_mission_id);
CREATE INDEX IF NOT EXISTS idx_assistant_audit_timestamp ON assistant_audit_logs(timestamp DESC);

-- 008_digital_twin.sql
-- Mars Pathfinder Phase 6: Mars Digital Twin & Advanced Mission Replay Schema

CREATE TABLE IF NOT EXISTS digital_twin_instances (
    id VARCHAR(64) PRIMARY KEY,
    mission_id VARCHAR(64) NOT NULL,
    twin_name VARCHAR(128) NOT NULL,
    active_sol DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    earth_utc_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    simulation_state VARCHAR(32) NOT NULL DEFAULT 'PAUSED', -- 'RUNNING', 'PAUSED', 'COMPLETED'
    time_acceleration DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mission_state_snapshots (
    id VARCHAR(64) PRIMARY KEY,
    twin_id VARCHAR(64) REFERENCES digital_twin_instances(id) ON DELETE CASCADE,
    simulation_seconds DOUBLE PRECISION NOT NULL,
    sol DOUBLE PRECISION NOT NULL,
    crew_state JSONB NOT NULL DEFAULT '[]'::jsonb,
    rover_state JSONB NOT NULL DEFAULT '[]'::jsonb,
    habitat_state JSONB NOT NULL DEFAULT '{}'::jsonb,
    resource_state JSONB NOT NULL DEFAULT '{}'::jsonb,
    hazard_state JSONB NOT NULL DEFAULT '[]'::jsonb,
    comm_network_state JSONB NOT NULL DEFAULT '{}'::jsonb,
    snapshot_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mission_events (
    id VARCHAR(64) PRIMARY KEY,
    mission_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(64) NOT NULL, -- 'MISSION_START', 'CREW_DISPATCH', 'SEPARATION_DETECTED', 'HAZARD_ALERT', 'RESCUE_DEPLOYED', 'REUNIFICATION'
    event_timestamp_utc TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    simulation_seconds DOUBLE PRECISION NOT NULL,
    sol DOUBLE PRECISION NOT NULL,
    source VARCHAR(64) NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    data_classification VARCHAR(32) NOT NULL DEFAULT 'SIMULATED'
);

CREATE TABLE IF NOT EXISTS scenario_branches (
    id VARCHAR(64) PRIMARY KEY,
    twin_id VARCHAR(64) REFERENCES digital_twin_instances(id) ON DELETE CASCADE,
    branch_name VARCHAR(128) NOT NULL,
    parent_snapshot_id VARCHAR(64),
    perturbation_parameters JSONB NOT NULL DEFAULT '{}'::jsonb,
    outcome_metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mission_analytics (
    id VARCHAR(64) PRIMARY KEY,
    mission_id VARCHAR(64) NOT NULL,
    duration_sols DOUBLE PRECISION NOT NULL,
    total_distance_km DOUBLE PRECISION NOT NULL,
    o2_consumed_kg DOUBLE PRECISION NOT NULL,
    power_consumed_kwh DOUBLE PRECISION NOT NULL,
    separation_duration_hours DOUBLE PRECISION NOT NULL,
    rescue_response_minutes DOUBLE PRECISION NOT NULL,
    route_efficiency_pct DOUBLE PRECISION NOT NULL,
    hazard_exposure_score DOUBLE PRECISION NOT NULL,
    objective_completion_pct DOUBLE PRECISION NOT NULL,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_twin_snapshots ON mission_state_snapshots(twin_id, simulation_seconds);
CREATE INDEX IF NOT EXISTS idx_mission_events ON mission_events(mission_id, simulation_seconds);
CREATE INDEX IF NOT EXISTS idx_scenario_branches ON scenario_branches(twin_id);

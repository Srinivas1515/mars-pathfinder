-- ====================================================================
-- Mars Pathfinder — Phase 2: Crew Management, Tracking & Emergency Rescue
-- Migration 004: Mission Operations, Crew Telemetry & Emergency Schema
-- ====================================================================

-- 1. Missions Table (Configurable Mars Mission Metadata)
CREATE TABLE IF NOT EXISTS missions (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    objective TEXT,
    landing_lat DOUBLE PRECISION NOT NULL,
    landing_lon DOUBLE PRECISION NOT NULL,
    landing_elevation_m DOUBLE PRECISION DEFAULT -2530.0,
    destination_lat DOUBLE PRECISION NOT NULL,
    destination_lon DOUBLE PRECISION NOT NULL,
    destination_elevation_m DOUBLE PRECISION DEFAULT -2500.0,
    base_location_name VARCHAR(255) DEFAULT 'Ares Base Alpha',
    base_lat DOUBLE PRECISION DEFAULT 18.38,
    base_lon DOUBLE PRECISION DEFAULT 77.58,
    crew_size INTEGER NOT NULL DEFAULT 5,
    rover_type VARCHAR(64) NOT NULL DEFAULT 'HEAVY_PRESSURIZED',
    start_time_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    duration_sols INTEGER NOT NULL DEFAULT 30,
    simulation_state VARCHAR(32) NOT NULL DEFAULT 'STOPPED', -- STOPPED, RUNNING, PAUSED, COMPLETED
    simulation_speed DOUBLE PRECISION NOT NULL DEFAULT 1.0,  -- 1x, 2x, 5x, 10x
    simulation_elapsed_seconds DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    active_scenario VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Crew Members Table (Individual Astronaut Profiles & Status)
CREATE TABLE IF NOT EXISTS crew_members (
    id VARCHAR(64) PRIMARY KEY,
    mission_id VARCHAR(64) NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    display_name VARCHAR(128) NOT NULL,
    role VARCHAR(64) NOT NULL, -- COMMANDER, PILOT, MEDICAL_OFFICER, ENGINEER, SCIENTIST, MISSION_SPECIALIST
    suit_id VARCHAR(64) NOT NULL,
    assigned_equipment TEXT[],
    current_lat DOUBLE PRECISION NOT NULL,
    current_lon DOUBLE PRECISION NOT NULL,
    current_elevation_m DOUBLE PRECISION DEFAULT -2530.0,
    last_known_lat DOUBLE PRECISION NOT NULL,
    last_known_lon DOUBLE PRECISION NOT NULL,
    target_lat DOUBLE PRECISION,
    target_lon DOUBLE PRECISION,
    heading_deg DOUBLE PRECISION DEFAULT 0.0,
    speed_m_s DOUBLE PRECISION DEFAULT 0.8,
    operational_status VARCHAR(32) NOT NULL DEFAULT 'NORMAL', -- NORMAL, WARNING, DISTRESS, COMMUNICATION_LOST, INJURED
    communication_status VARCHAR(32) NOT NULL DEFAULT 'CONNECTED', -- CONNECTED, DEGRADED, INTERRUPTED, LOST
    last_comm_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    data_classification VARCHAR(32) NOT NULL DEFAULT 'SIMULATED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index on mission_id
CREATE INDEX IF NOT EXISTS idx_crew_members_mission ON crew_members(mission_id);

-- 3. Crew Positions History (Spatial Track & Breadcrumbs)
CREATE TABLE IF NOT EXISTS crew_positions (
    id BIGSERIAL PRIMARY KEY,
    crew_id VARCHAR(64) NOT NULL REFERENCES crew_members(id) ON DELETE CASCADE,
    mission_id VARCHAR(64) NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    timestamp_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    simulation_time_seconds DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    elevation_m DOUBLE PRECISION DEFAULT -2530.0,
    speed_m_s DOUBLE PRECISION DEFAULT 0.0,
    heading_deg DOUBLE PRECISION DEFAULT 0.0,
    slope_deg DOUBLE PRECISION DEFAULT 0.0,
    terrain_roughness DOUBLE PRECISION DEFAULT 0.0,
    data_classification VARCHAR(32) NOT NULL DEFAULT 'SIMULATED'
);

CREATE INDEX IF NOT EXISTS idx_crew_positions_crew ON crew_positions(crew_id, timestamp_utc DESC);

-- 4. Crew Life-Support & Health Telemetry
CREATE TABLE IF NOT EXISTS crew_telemetry (
    id BIGSERIAL PRIMARY KEY,
    crew_id VARCHAR(64) NOT NULL REFERENCES crew_members(id) ON DELETE CASCADE,
    mission_id VARCHAR(64) NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    timestamp_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    simulation_time_seconds DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    -- Human Health
    heart_rate_bpm DOUBLE PRECISION NOT NULL DEFAULT 75.0,
    blood_oxygen_pct DOUBLE PRECISION NOT NULL DEFAULT 98.5,
    body_temp_c DOUBLE PRECISION NOT NULL DEFAULT 37.0,
    activity_level VARCHAR(32) NOT NULL DEFAULT 'RESTING', -- RESTING, NOMINAL_EVA, HIGH_STRESS, CRITICAL
    medical_alert_state VARCHAR(32) NOT NULL DEFAULT 'NORMAL',
    -- Spacesuit Telemetry
    suit_oxygen_pct DOUBLE PRECISION NOT NULL DEFAULT 95.0,
    suit_pressure_kpa DOUBLE PRECISION NOT NULL DEFAULT 29.6, -- 4.3 psi
    suit_battery_pct DOUBLE PRECISION NOT NULL DEFAULT 92.0,
    suit_temp_c DOUBLE PRECISION NOT NULL DEFAULT 21.0,
    radiation_dose_rate_msv_h DOUBLE PRECISION NOT NULL DEFAULT 0.025,
    accumulated_radiation_msv DOUBLE PRECISION NOT NULL DEFAULT 0.15,
    data_classification VARCHAR(32) NOT NULL DEFAULT 'SIMULATED',
    quality_status VARCHAR(32) NOT NULL DEFAULT 'VALIDATED'
);

CREATE INDEX IF NOT EXISTS idx_crew_telemetry_crew ON crew_telemetry(crew_id, timestamp_utc DESC);

-- 5. Crew Separation & Proximity Alerts
CREATE TABLE IF NOT EXISTS crew_separation_alerts (
    id VARCHAR(64) PRIMARY KEY,
    mission_id VARCHAR(64) NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    crew_id VARCHAR(64) NOT NULL REFERENCES crew_members(id) ON DELETE CASCADE,
    timestamp_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    simulation_time_seconds DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    alert_type VARCHAR(64) NOT NULL, -- DISTANCE_EXCEEDED, ISOLATED_MEMBER, COMMS_SILENCE, OUT_OF_BOUNDS
    severity VARCHAR(32) NOT NULL,   -- LOW, MODERATE, HIGH, CRITICAL
    separation_distance_m DOUBLE PRECISION NOT NULL,
    max_threshold_m DOUBLE PRECISION NOT NULL,
    nearest_crew_id VARCHAR(64),
    nearest_crew_distance_m DOUBLE PRECISION,
    warning_message TEXT NOT NULL,
    resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at TIMESTAMPTZ
);

-- 6. Emergency Scenarios Table
CREATE TABLE IF NOT EXISTS mission_scenarios (
    id VARCHAR(64) PRIMARY KEY,
    mission_id VARCHAR(64) NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    scenario_type VARCHAR(64) NOT NULL, -- DUST_STORM_SEPARATION, ASTRONAUT_INJURY, COMMS_FAILURE, LOW_OXYGEN, ROVER_BREAKDOWN, MULTIPLE_EMERGENCY
    title VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(32) NOT NULL DEFAULT 'MODERATE', -- LOW, MODERATE, HIGH, CRITICAL
    affected_crew_ids TEXT[],
    epicenter_lat DOUBLE PRECISION,
    epicenter_lon DOUBLE PRECISION,
    radius_km DOUBLE PRECISION,
    environmental_impact JSONB,
    start_time_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Intelligent Rescue & Reunification Plans
CREATE TABLE IF NOT EXISTS rescue_plans (
    id VARCHAR(64) PRIMARY KEY,
    mission_id VARCHAR(64) NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    scenario_id VARCHAR(64) REFERENCES mission_scenarios(id) ON DELETE SET NULL,
    strategy VARCHAR(64) NOT NULL, -- SHORTEST_DISTANCE, LOWEST_TERRAIN_RISK, LOWEST_RESOURCE, EMERGENCY_MEDICAL, CREW_REUNIFICATION, RETURN_TO_BASE
    title VARCHAR(255) NOT NULL,
    description TEXT,
    rescuer_crew_id VARCHAR(64),
    target_crew_id VARCHAR(64),
    start_lat DOUBLE PRECISION NOT NULL,
    start_lon DOUBLE PRECISION NOT NULL,
    destination_lat DOUBLE PRECISION NOT NULL,
    destination_lon DOUBLE PRECISION NOT NULL,
    total_distance_km DOUBLE PRECISION NOT NULL,
    estimated_duration_hours DOUBLE PRECISION NOT NULL,
    terrain_risk_score DOUBLE PRECISION NOT NULL, -- 0 to 100
    environmental_risk_score DOUBLE PRECISION NOT NULL, -- 0 to 100
    resource_consumption_summary JSONB,
    communication_availability VARCHAR(64) NOT NULL DEFAULT 'INTERMITTENT',
    feasibility_status VARCHAR(32) NOT NULL DEFAULT 'FEASIBLE', -- FEASIBLE, HIGH_RISK, CRITICAL_MARGIN, INFEASIBLE
    rejection_rationale TEXT,
    waypoints JSONB,
    recommended BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Mission Consumables & Resource Tracking
CREATE TABLE IF NOT EXISTS mission_resources (
    id VARCHAR(64) PRIMARY KEY,
    mission_id VARCHAR(64) NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    oxygen_liters_total DOUBLE PRECISION NOT NULL DEFAULT 5000.0,
    oxygen_liters_remaining DOUBLE PRECISION NOT NULL DEFAULT 5000.0,
    water_liters_total DOUBLE PRECISION NOT NULL DEFAULT 1200.0,
    water_liters_remaining DOUBLE PRECISION NOT NULL DEFAULT 1200.0,
    food_rations_total INTEGER NOT NULL DEFAULT 450,
    food_rations_remaining INTEGER NOT NULL DEFAULT 450,
    battery_kwh_total DOUBLE PRECISION NOT NULL DEFAULT 150.0,
    battery_kwh_remaining DOUBLE PRECISION NOT NULL DEFAULT 150.0,
    medical_kits_total INTEGER NOT NULL DEFAULT 12,
    medical_kits_remaining INTEGER NOT NULL DEFAULT 12,
    oxygen_burn_rate_l_h DOUBLE PRECISION NOT NULL DEFAULT 25.0,
    water_burn_rate_l_h DOUBLE PRECISION NOT NULL DEFAULT 0.15,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. Communication Network Nodes & Relay Links
CREATE TABLE IF NOT EXISTS communication_nodes (
    id VARCHAR(64) PRIMARY KEY,
    mission_id VARCHAR(64) NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    node_name VARCHAR(128) NOT NULL,
    node_type VARCHAR(64) NOT NULL, -- ASTRONAUT, ROVER, HABITAT, GROUND_RELAY, ORBITER_MRO, ORBITER_ODYSSEY
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    elevation_m DOUBLE PRECISION DEFAULT 0.0,
    effective_range_km DOUBLE PRECISION NOT NULL DEFAULT 5.0,
    status VARCHAR(32) NOT NULL DEFAULT 'CONNECTED'
);

-- 10. Mission Timeline & Chronological Events
CREATE TABLE IF NOT EXISTS mission_timeline_events (
    id BIGSERIAL PRIMARY KEY,
    mission_id VARCHAR(64) NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    timestamp_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    simulation_seconds DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    event_category VARCHAR(64) NOT NULL, -- MISSION, CREW_MOVEMENT, SEPARATION, COMMS, HEALTH, SCENARIO, RESCUE, DECISION
    title VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(32) NOT NULL DEFAULT 'INFO', -- INFO, WARNING, DANGER, CRITICAL
    associated_crew_id VARCHAR(64),
    metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_timeline_events_mission ON mission_timeline_events(mission_id, timestamp_utc DESC);

-- 11. Explainable AI Mission Recommendations
CREATE TABLE IF NOT EXISTS ai_recommendations (
    id VARCHAR(64) PRIMARY KEY,
    mission_id VARCHAR(64) NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    timestamp_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    category VARCHAR(64) NOT NULL, -- RESCUE_STRATEGY, SEPARATION_WARNING, RESOURCE_CONSERVATION, EVACUATION
    title VARCHAR(255) NOT NULL,
    rationale TEXT NOT NULL,
    confidence_score DOUBLE PRECISION NOT NULL DEFAULT 0.95,
    risk_factors TEXT[],
    suggested_actions TEXT[],
    human_override_required BOOLEAN NOT NULL DEFAULT TRUE,
    approved_by_controller BOOLEAN DEFAULT NULL
);

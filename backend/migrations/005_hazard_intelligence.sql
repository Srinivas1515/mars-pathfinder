-- ====================================================================
-- Mars Pathfinder — Phase 3: Advanced Hazard Simulation & Environmental Risk
-- Migration 005: Hazard Intelligence, Dust Storm Simulation & Risk Schema
-- ====================================================================

-- 1. Hazard Types Taxonomy Table
CREATE TABLE IF NOT EXISTS hazard_types (
    id VARCHAR(64) PRIMARY KEY,
    category VARCHAR(32) NOT NULL, -- ATMOSPHERIC, SURFACE, RADIATION, OPERATIONAL
    name VARCHAR(128) NOT NULL,
    description TEXT NOT NULL,
    default_severity VARCHAR(32) NOT NULL DEFAULT 'MODERATE', -- LOW, MODERATE, HIGH, CRITICAL
    primary_metric_name VARCHAR(64) NOT NULL,
    primary_metric_unit VARCHAR(32) NOT NULL,
    default_weight DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    scientific_source VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Hazard Observations (Historical & Real-Time Mars Sensor Observations)
CREATE TABLE IF NOT EXISTS hazard_observations (
    id VARCHAR(64) PRIMARY KEY,
    hazard_type_id VARCHAR(64) NOT NULL REFERENCES hazard_types(id),
    name VARCHAR(255) NOT NULL,
    center_lat DOUBLE PRECISION NOT NULL,
    center_lon DOUBLE PRECISION NOT NULL,
    radius_km DOUBLE PRECISION NOT NULL,
    severity VARCHAR(32) NOT NULL,
    optical_depth_tau DOUBLE PRECISION,
    peak_wind_speed_m_s DOUBLE PRECISION,
    solar_longitude_ls DOUBLE PRECISION,
    martian_year INTEGER,
    sol INTEGER,
    data_classification VARCHAR(32) NOT NULL DEFAULT 'OBSERVED', -- OBSERVED, MODELLED, DERIVED, PREDICTED, SIMULATED
    observation_source VARCHAR(128) NOT NULL,
    observed_at TIMESTAMPTZ,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hazard_obs_type ON hazard_observations(hazard_type_id);
CREATE INDEX IF NOT EXISTS idx_hazard_obs_coords ON hazard_observations(center_lat, center_lon);

-- 3. Predefined Hazard Scenarios (Benchmark Scenarios for Simulations & Training)
CREATE TABLE IF NOT EXISTS hazard_scenarios (
    id VARCHAR(64) PRIMARY KEY,
    scenario_code VARCHAR(64) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(32) NOT NULL,
    description TEXT NOT NULL,
    target_region_name VARCHAR(128) NOT NULL,
    initial_lat DOUBLE PRECISION NOT NULL,
    initial_lon DOUBLE PRECISION NOT NULL,
    initial_radius_km DOUBLE PRECISION NOT NULL,
    max_radius_km DOUBLE PRECISION NOT NULL,
    expansion_rate_km_h DOUBLE PRECISION NOT NULL,
    drift_bearing_deg DOUBLE PRECISION NOT NULL,
    drift_speed_km_h DOUBLE PRECISION NOT NULL,
    peak_optical_depth_tau DOUBLE PRECISION NOT NULL,
    peak_wind_speed_m_s DOUBLE PRECISION NOT NULL,
    solar_flux_reduction_pct DOUBLE PRECISION NOT NULL,
    rf_attenuation_db DOUBLE PRECISION NOT NULL,
    duration_sols INTEGER NOT NULL DEFAULT 15,
    historical_reference VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Active Hazard Simulation Runs
CREATE TABLE IF NOT EXISTS hazard_simulations (
    id VARCHAR(64) PRIMARY KEY,
    scenario_id VARCHAR(64) REFERENCES hazard_scenarios(id),
    name VARCHAR(255) NOT NULL,
    hazard_type VARCHAR(64) NOT NULL DEFAULT 'DUST_STORM',
    current_lat DOUBLE PRECISION NOT NULL,
    current_lon DOUBLE PRECISION NOT NULL,
    current_radius_km DOUBLE PRECISION NOT NULL,
    current_tau DOUBLE PRECISION NOT NULL,
    current_wind_speed_m_s DOUBLE PRECISION NOT NULL,
    solar_power_loss_pct DOUBLE PRECISION NOT NULL,
    comms_attenuation_db DOUBLE PRECISION NOT NULL,
    bearing_deg DOUBLE PRECISION NOT NULL,
    speed_km_h DOUBLE PRECISION NOT NULL,
    elapsed_hours DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    time_step_hours DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    status VARCHAR(32) NOT NULL DEFAULT 'INITIALIZED', -- INITIALIZED, RUNNING, PAUSED, COMPLETED
    phase VARCHAR(32) NOT NULL DEFAULT 'GROWTH', -- GROWTH, PEAK, DECAY, DISSIPATED
    data_classification VARCHAR(32) NOT NULL DEFAULT 'SIMULATED',
    parameters JSONB NOT NULL DEFAULT '{}'::jsonb,
    history JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hazard_sims_status ON hazard_simulations(status);

-- 5. Hazard Geometries & Spatial Envelopes
CREATE TABLE IF NOT EXISTS hazard_geometries (
    id VARCHAR(64) PRIMARY KEY,
    simulation_id VARCHAR(64) NOT NULL REFERENCES hazard_simulations(id) ON DELETE CASCADE,
    step_index INTEGER NOT NULL DEFAULT 0,
    elapsed_hours DOUBLE PRECISION NOT NULL,
    center_lat DOUBLE PRECISION NOT NULL,
    center_lon DOUBLE PRECISION NOT NULL,
    outer_radius_km DOUBLE PRECISION NOT NULL,
    core_radius_km DOUBLE PRECISION NOT NULL,
    polygon_coordinates JSONB NOT NULL, -- GeoJSON Ring [[lon, lat], ...]
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hazard_geom_sim ON hazard_geometries(simulation_id);

-- 6. Route Hazard Intersections & Threat Assessments
CREATE TABLE IF NOT EXISTS route_hazard_intersections (
    id VARCHAR(64) PRIMARY KEY,
    simulation_id VARCHAR(64) REFERENCES hazard_simulations(id) ON DELETE CASCADE,
    route_id VARCHAR(64),
    mission_id VARCHAR(64),
    hazard_name VARCHAR(255) NOT NULL,
    intersection_lat DOUBLE PRECISION NOT NULL,
    intersection_lon DOUBLE PRECISION NOT NULL,
    distance_to_core_km DOUBLE PRECISION NOT NULL,
    time_to_impact_hours DOUBLE PRECISION,
    severity_at_intersection VARCHAR(32) NOT NULL,
    exposure_duration_hours DOUBLE PRECISION,
    recommended_action VARCHAR(64) NOT NULL DEFAULT 'REROUTE', -- HOLD, REROUTE, ACCELERATE, SHELTER
    alternative_waypoints JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Environmental Risk Assessments (Point & Regional Composite Evaluations)
CREATE TABLE IF NOT EXISTS environmental_risk_assessments (
    id VARCHAR(64) PRIMARY KEY,
    target_name VARCHAR(128) NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lon DOUBLE PRECISION NOT NULL,
    composite_risk_score DOUBLE PRECISION NOT NULL, -- 0.0 to 100.0
    risk_level VARCHAR(32) NOT NULL, -- LOW, MODERATE, HIGH, CRITICAL
    atmospheric_risk_score DOUBLE PRECISION NOT NULL,
    surface_risk_score DOUBLE PRECISION NOT NULL,
    radiation_risk_score DOUBLE PRECISION NOT NULL,
    solar_risk_score DOUBLE PRECISION NOT NULL,
    comms_risk_score DOUBLE PRECISION NOT NULL,
    operational_risk_score DOUBLE PRECISION NOT NULL,
    uncertainty_margin_pct DOUBLE PRECISION NOT NULL,
    mobility_profile VARCHAR(64) NOT NULL DEFAULT 'HEAVY_ROVER',
    factor_breakdown JSONB NOT NULL,
    provenance_sources JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_env_risk_coords ON environmental_risk_assessments(lat, lon);

-- Seed Initial Hazard Types
INSERT INTO hazard_types (id, category, name, description, default_severity, primary_metric_name, primary_metric_unit, default_weight, scientific_source)
VALUES
    ('DUST_STORM_GLOBAL', 'ATMOSPHERIC', 'Global Planet-Encircling Dust Event', 'Global opacity spike covering Martian surface with suspended fine silicates', 'CRITICAL', 'optical_depth_tau', 'tau', 1.0, 'NASA MGS TES / MRO MCS / Curiosity MEDA'),
    ('DUST_STORM_REGIONAL', 'ATMOSPHERIC', 'Regional Dust Storm / Front', 'Mesoscale storm front spanning 500-2000 km with localized high winds', 'HIGH', 'optical_depth_tau', 'tau', 0.85, 'NASA MRO MARCI / Viking Orbiter'),
    ('DUST_DEVIL_CONVECTIVE', 'ATMOSPHERIC', 'Convective Dust Devil Vortex Swarm', 'Vigorous localized thermal vortices generating electrostatic discharge and grit abrasion', 'MODERATE', 'vortex_diameter_m', 'meters', 0.5, 'NASA Mars Pathfinder / InSight TWINS / Perseverance MEDA'),
    ('HIGH_SURFACE_WINDS', 'ATMOSPHERIC', 'Severe Surface Winds & Gusts', 'High aerodynamic drag, particulate saltation, and structural buffeting', 'MODERATE', 'wind_speed_m_s', 'm/s', 0.6, 'NASA Viking Lander / Perseverance MEDA'),
    ('SLOPE_INSTABILITY', 'SURFACE', 'Steep Slopes & Scree Instability', 'Slopes exceeding angle of repose (>25 deg) causing wheel slip, rollover, or astronaut fall', 'HIGH', 'slope_angle_deg', 'degrees', 0.9, 'NASA MGS MOLA / MRO HiRISE DTM'),
    ('BOULDER_FIELD', 'SURFACE', 'High Roughness Boulder Field', 'Concentrations of basaltic ejecta rocks exceeding ground clearance', 'MODERATE', 'surface_roughness_m', 'meters', 0.7, 'NASA Viking / MRO HiRISE'),
    ('DUNE_SAND_TRAP', 'SURFACE', 'Active Basaltic Dunes & Sand Traps', 'Low-bearing-capacity bedforms causing vehicle wheel immobilization or sinkage', 'HIGH', 'sinkage_risk_index', 'index_0_100', 0.85, 'NASA Opportunity Purgatory Dune / Curiosity Bagnold'),
    ('ESCARPMENT_CLIFF', 'SURFACE', 'Vertical Escarpment & Crater Rims', 'Vertical or near-vertical drop-offs and canyon scarps', 'CRITICAL', 'vertical_drop_m', 'meters', 0.95, 'NASA MGS MOLA MEGDR'),
    ('SOLAR_PARTICLE_EVENT', 'RADIATION', 'Solar Energetic Particle Flare', 'Coronal mass ejection protons elevating acute radiation dose rate', 'CRITICAL', 'dose_rate_msv_h', 'mSv/h', 1.0, 'NASA MSL RAD / CCMC Space Weather'),
    ('GCR_BACKGROUND', 'RADIATION', 'Galactic Cosmic Radiation Baseline', 'Deep space isotropic heavy ions filtered only by thin Martian atmosphere', 'MODERATE', 'annual_dose_msv', 'mSv/year', 0.55, 'NASA MSL RAD / Odyssey MARIE'),
    ('THERMAL_INVERSION', 'OPERATIONAL', 'Extreme Nocturnal Cryogenic Freeze', 'Rapid radiative cooling dropping surface temperatures below -120 deg C', 'HIGH', 'temperature_kelvin', 'K', 0.75, 'NASA Viking / MEDA / MCS'),
    ('SOLAR_OBSCURATION', 'OPERATIONAL', 'Photovoltaic Array Dust Obscuration', 'Atmospheric opacity and settling dust curtailing solar power generation', 'CRITICAL', 'solar_loss_pct', 'percent', 0.95, 'NASA Opportunity / InSight Solar Telemetry'),
    ('RF_COMMS_SHADOW', 'OPERATIONAL', 'Topographic Line-of-Sight RF Shadow', 'Crater walls and canyon rims obstructing direct-to-base and orbiter relay communications', 'HIGH', 'rf_path_loss_db', 'dB', 0.8, 'NASA DSN / Mars Relay Network')
ON CONFLICT (id) DO NOTHING;

-- Seed Benchmark Hazard Scenarios
INSERT INTO hazard_scenarios (id, scenario_code, title, category, description, target_region_name, initial_lat, initial_lon, initial_radius_km, max_radius_km, expansion_rate_km_h, drift_bearing_deg, drift_speed_km_h, peak_optical_depth_tau, peak_wind_speed_m_s, solar_flux_reduction_pct, rf_attenuation_db, duration_sols, historical_reference)
VALUES
    ('SCN_MY34_GLOBAL', 'MY34_GLOBAL_STORM', 'MY 34 Planet-Encircling Dust Event (2018)', 'ATMOSPHERIC', 'Historical simulation of the 2018 global dust storm that covered the entire Martian planet and ended Opportunity rover operations at Endeavour Crater.', 'Global Mars', 14.0, -16.0, 350.0, 3800.0, 28.5, 85.0, 18.2, 8.5, 34.0, 99.1, 28.4, 60, 'Martian Year 34 Ls 185-260'),
    ('SCN_MY28_GLOBAL', 'MY28_GLOBAL_STORM', 'MY 28 Global Dust Storm (2007)', 'ATMOSPHERIC', 'Historical simulation of the intense 2007 global storm survived by Spirit and Opportunity rovers under extreme low-power hibernation protocols.', 'Global Mars', -22.0, 35.0, 280.0, 3200.0, 22.0, 72.0, 15.0, 5.2, 28.5, 98.2, 22.5, 45, 'Martian Year 28 Ls 260-310'),
    ('SCN_JEZERO_SQUALL', 'JEZERO_REGIONAL_SQUALL', 'Jezero Delta Mesoscale Dust Squall', 'Rapidly developing regional dust front traversing Isidis Planitia toward Jezero Crater delta, bringing severe gust fronts and solar array obscuration.', 'Jezero Crater', 16.5, 82.0, 75.0, 450.0, 14.0, 260.0, 22.5, 3.8, 29.0, 84.5, 14.8, 8, 'Perseverance MEDA Sol 210 Event Model'),
    ('SCN_GALE_INVERSION', 'GALE_CRATER_INVERSION', 'Mount Sharp Slope Wind & Thermal Trap', 'Nocturnal katabatic drainage winds down Aeolis Mons inducing severe thermal inversion and localized particulate entrapment.', 'Gale Crater', -5.4, 137.8, 45.0, 180.0, 5.0, 315.0, 8.5, 1.9, 21.0, 55.0, 6.2, 5, 'Curiosity REMS Long-term Microclimate'),
    ('SCN_SOLAR_PARTICLE', 'SEP_EXTREME_EVENT', 'Extreme Solar Energetic Particle (SEP) Flare', 'Coronal mass ejection shock front impacting Mars without magnetospheric shielding, spiking radiation levels across all unshielded surface assets.', 'Planetary Wide', 0.0, 0.0, 3396.0, 3396.0, 0.0, 0.0, 0.0, 0.5, 0.0, 5.0, 38.0, 3, 'CCMC SEP Bastille-Class Martian Flare Simulation')
ON CONFLICT (id) DO NOTHING;

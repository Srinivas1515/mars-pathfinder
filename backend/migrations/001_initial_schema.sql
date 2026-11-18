CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Planetary regions
CREATE TABLE mars_regions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    description TEXT,
    center_longitude DOUBLE PRECISION,
    center_latitude DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- NASA missions and instruments
CREATE TABLE data_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mission_name VARCHAR(150) NOT NULL,
    instrument_name VARCHAR(150),
    description TEXT,
    source_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Scientific datasets and map layers
CREATE TABLE map_layers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    layer_key VARCHAR(150) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(80) NOT NULL,
    source_id UUID REFERENCES data_sources(id),
    service_type VARCHAR(50),
    service_url TEXT,
    external_layer_id TEXT,
    coordinate_system VARCHAR(100),
    resolution_m DOUBLE PRECISION,
    coverage JSONB,
    metadata JSONB DEFAULT '{}'::jsonb,
    is_global BOOLEAN DEFAULT FALSE,
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Scientific points of interest
CREATE TABLE science_targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    target_type VARCHAR(100),
    longitude DOUBLE PRECISION NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    -- Coordinate values use Mars conventions.
    -- Do not apply Earth-based distance calculations.
    location GEOMETRY(Point, 0),
    source_id UUID REFERENCES data_sources(id),
    confidence DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Mission records (legacy schema)
CREATE TABLE missions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'draft',
    start_longitude DOUBLE PRECISION,
    start_latitude DOUBLE PRECISION,
    destination_longitude DOUBLE PRECISION,
    destination_latitude DOUBLE PRECISION,
    configuration JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Active operational missions table for Mars Pathfinder
CREATE TABLE IF NOT EXISTS mars_missions (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    rover_type VARCHAR(64) NOT NULL,
    routing_mode VARCHAR(64) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    plan JSONB NOT NULL
);

CREATE INDEX idx_science_targets_location ON science_targets USING GIST(location);
CREATE INDEX idx_map_layers_category ON map_layers(category);
CREATE INDEX idx_missions_status ON missions(status);
CREATE INDEX IF NOT EXISTS idx_mars_missions_created_at ON mars_missions(created_at DESC);

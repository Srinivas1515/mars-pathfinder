-- ==============================================================================
-- Mars Pathfinder — Migration 003: Scientific Data Foundation & Intelligence
-- Adds structured catalogs, scientific observations, PostGIS coverage, and provenance.
-- ==============================================================================

-- 1. Enhance existing data_sources table with operational fields
ALTER TABLE data_sources ADD COLUMN IF NOT EXISTS source_key VARCHAR(64) UNIQUE;
ALTER TABLE data_sources ADD COLUMN IF NOT EXISTS provider VARCHAR(150);
ALTER TABLE data_sources ADD COLUMN IF NOT EXISTS data_classification VARCHAR(32) DEFAULT 'HISTORICAL';
ALTER TABLE data_sources ADD COLUMN IF NOT EXISTS update_frequency VARCHAR(64);
ALTER TABLE data_sources ADD COLUMN IF NOT EXISTS spatial_coverage_type VARCHAR(32) DEFAULT 'GLOBAL';
ALTER TABLE data_sources ADD COLUMN IF NOT EXISTS api_endpoint TEXT;
ALTER TABLE data_sources ADD COLUMN IF NOT EXISTS last_retrieved_at TIMESTAMPTZ;
ALTER TABLE data_sources ADD COLUMN IF NOT EXISTS status VARCHAR(32) DEFAULT 'ACTIVE';

-- 2. Scientific Data Products Catalog
CREATE TABLE IF NOT EXISTS data_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id VARCHAR(150) UNIQUE NOT NULL,
    source_key VARCHAR(64) REFERENCES data_sources(source_key) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    processing_level VARCHAR(32) NOT NULL,
    data_classification VARCHAR(32) NOT NULL,
    format VARCHAR(64),
    file_size_bytes BIGINT,
    checksum_sha256 VARCHAR(64),
    observation_start TIMESTAMPTZ,
    observation_end TIMESTAMPTZ,
    publication_date TIMESTAMPTZ,
    source_url TEXT NOT NULL,
    citation TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Core Scientific Observations (PostGIS point geometry, units, provenance)
CREATE TABLE IF NOT EXISTS scientific_observations (
    id VARCHAR(128) PRIMARY KEY,
    source_key VARCHAR(64) NOT NULL,
    product_id VARCHAR(150),
    target_site VARCHAR(150),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location GEOMETRY(Point, 0),
    elevation_m DOUBLE PRECISION,
    observation_time TIMESTAMPTZ NOT NULL,
    mars_sol INTEGER,
    solar_longitude_ls DOUBLE PRECISION,
    data_status VARCHAR(32) NOT NULL,
    quality_flag VARCHAR(32) NOT NULL,
    processing_method TEXT,
    measurements JSONB NOT NULL DEFAULT '{}'::jsonb,
    units JSONB NOT NULL DEFAULT '{}'::jsonb,
    source_url TEXT,
    retrieved_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Data Retrieval & Scheduled Ingestion Jobs
CREATE TABLE IF NOT EXISTS data_retrieval_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_key VARCHAR(64) NOT NULL,
    job_type VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL,
    records_retrieved INTEGER DEFAULT 0,
    bytes_transferred BIGINT DEFAULT 0,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    details JSONB DEFAULT '{}'::jsonb
);

-- 5. Data Quality Reports and Audit Metrics
CREATE TABLE IF NOT EXISTS data_quality_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_key VARCHAR(64) NOT NULL,
    product_id VARCHAR(150),
    validation_timestamp TIMESTAMPTZ DEFAULT NOW(),
    checks_passed INTEGER DEFAULT 0,
    checks_failed INTEGER DEFAULT 0,
    quality_score DOUBLE PRECISION DEFAULT 100.0,
    anomalies JSONB DEFAULT '[]'::jsonb,
    summary TEXT
);

-- 6. Spatial Coverage & Geographic Extents (PostGIS polygon geometry)
CREATE TABLE IF NOT EXISTS data_coverage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_key VARCHAR(64) NOT NULL,
    region_name VARCHAR(150) NOT NULL,
    min_lat DOUBLE PRECISION,
    max_lat DOUBLE PRECISION,
    min_lon DOUBLE PRECISION,
    max_lon DOUBLE PRECISION,
    coverage_geometry GEOMETRY(Polygon, 0),
    resolution_m DOUBLE PRECISION,
    observation_count INTEGER DEFAULT 0,
    has_direct_observations BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Numerical Model Runs & Climatology Audits
CREATE TABLE IF NOT EXISTS model_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name VARCHAR(128) NOT NULL,
    version VARCHAR(32) NOT NULL,
    run_time TIMESTAMPTZ DEFAULT NOW(),
    input_parameters JSONB NOT NULL DEFAULT '{}'::jsonb,
    output_summary JSONB NOT NULL DEFAULT '{}'::jsonb,
    validation_status VARCHAR(32) NOT NULL DEFAULT 'VALIDATED'
);

-- 8. Data Ingestion & Audit Logs
CREATE TABLE IF NOT EXISTS data_ingestion_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_key VARCHAR(64) NOT NULL,
    endpoint_url TEXT NOT NULL,
    status_code INTEGER,
    bytes_transferred BIGINT,
    response_time_ms INTEGER,
    cached BOOLEAN DEFAULT FALSE,
    error TEXT,
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for spatial, temporal, and category performance
CREATE INDEX IF NOT EXISTS idx_scientific_obs_location ON scientific_observations USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_scientific_obs_time ON scientific_observations(observation_time DESC);
CREATE INDEX IF NOT EXISTS idx_scientific_obs_source ON scientific_observations(source_key);
CREATE INDEX IF NOT EXISTS idx_scientific_obs_status ON scientific_observations(data_status);
CREATE INDEX IF NOT EXISTS idx_data_coverage_geom ON data_coverage USING GIST(coverage_geometry);
CREATE INDEX IF NOT EXISTS idx_ingestion_logs_time ON data_ingestion_logs(logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_data_products_source ON data_products(source_key);

-- Seed initial data_sources records
INSERT INTO data_sources (source_key, mission_name, instrument_name, provider, description, primary_url, api_endpoint, data_classification, update_frequency, spatial_coverage_type, status)
VALUES
('nasa-pds-meda', 'Mars 2020', 'MEDA', 'NASA / JPL / CAB', 'Surface meteorological station aboard Perseverance rover in Jezero Crater', 'https://pds-atmospheres.nmsu.edu/data_and_services/atmospheres_data/PERSEVERANCE/meda.html', 'https://pds-atmospheres.nmsu.edu/PDS/data/PDS4/Mars2020/mars2020_meda/', 'RECENTLY_PUBLISHED', 'Periodic PDS Releases (~3-4 months)', 'LOCAL', 'ACTIVE'),
('nasa-pds-mcs', 'Mars Reconnaissance Orbiter', 'MCS', 'NASA / JPL', 'Atmospheric limb sounder profiling temperature, pressure, dust, and water ice', 'https://pds-atmospheres.nmsu.edu/data_and_services/atmospheres_data/MARS/mcs.html', 'https://pds-atmospheres.nmsu.edu/data_and_services/atmospheres_data/MARS/mcs.html', 'HISTORICAL', 'Monthly PDS Archives', 'GLOBAL', 'ACTIVE'),
('nasa-ccmc-spaceweather', 'Integrated Space Weather Analysis', 'WSA-ENLIL', 'NASA / GSFC CCMC', 'Interplanetary space weather, solar wind, and radiation forecasts at Mars orbit', 'https://ccmc.gsfc.nasa.gov/mars/', 'https://api.nasa.gov/DONKI/WSAEnlilSimulations', 'NEAR_REAL_TIME', '2-4 Hour Model Cycles', 'GLOBAL', 'ACTIVE'),
('nasa-mars-trek-wmts', 'Solar System Treks', 'Multi-Mission', 'NASA / JPL Solar System Treks', 'OGC Web Map Tile Service delivering geodetically aligned global and regional mosaics', 'https://trek.nasa.gov/mars/', 'https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_MOLA_ClrShade_merge_global_463m/1.0.0/WMTSCapabilities.xml', 'HISTORICAL', 'Curated Cartographic Releases', 'GLOBAL', 'ACTIVE'),
('nasa-pds-mola', 'Mars Global Surveyor', 'MOLA', 'NASA / GSFC / WUSTL', 'Global precision laser altimetry and topographic relief baseline', 'https://pds-geosciences.wustl.edu/missions/mgs/megdr.html', 'https://pds-geosciences.wustl.edu/mgs/mgs-m-mola-5-megdr-l3-v1/mgsl_300x/meg004/', 'HISTORICAL', 'Archived Peer-Reviewed Dataset', 'GLOBAL', 'ACTIVE'),
('nasa-pds-hirise', 'Mars Reconnaissance Orbiter', 'HiRISE', 'NASA / JPL / University of Arizona', 'Sub-meter stereo digital terrain models (1-2 m/px) for landing corridors', 'https://hirise.lpl.arizona.edu/', 'https://hirise-pds.lpl.arizona.edu/PDS/DTM/', 'HISTORICAL', 'Monthly Scientific Releases', 'REGIONAL', 'ACTIVE'),
('nasa-naif-spice', 'Multi-Mission Ephemeris', 'SPICE Kernels', 'NASA / JPL NAIF', 'Planetary geometry, orbital mechanics, solar longitude Ls, and light travel delays', 'https://naif.jpl.nasa.gov/', 'https://naif.jpl.nasa.gov/pub/naif/generic_kernels/', 'MODELLED', 'Continuous Astrodynamics', 'GLOBAL', 'ACTIVE')
ON CONFLICT (source_key) DO UPDATE SET
    provider = EXCLUDED.provider,
    description = EXCLUDED.description,
    primary_url = EXCLUDED.primary_url,
    api_endpoint = EXCLUDED.api_endpoint,
    data_classification = EXCLUDED.data_classification,
    update_frequency = EXCLUDED.update_frequency,
    spatial_coverage_type = EXCLUDED.spatial_coverage_type,
    status = EXCLUDED.status;

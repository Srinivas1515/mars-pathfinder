-- 009_icarus_system.sql
-- Mars Pathfinder Phase 7: ICARUS — Personal Voice Assistant, Voice Identity & Memory Schema

CREATE TABLE IF NOT EXISTS icarus_user_profiles (
    user_id VARCHAR(64) PRIMARY KEY,
    callsign VARCHAR(64) NOT NULL,
    role VARCHAR(64) NOT NULL DEFAULT 'MISSION_CONTROLLER',
    voice_depth DOUBLE PRECISION NOT NULL DEFAULT 0.85,
    speech_rate DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    pitch_adjustment DOUBLE PRECISION NOT NULL DEFAULT -2.5,
    robotic_cadence DOUBLE PRECISION NOT NULL DEFAULT 0.35,
    memory_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS icarus_voice_templates (
    template_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) REFERENCES icarus_user_profiles(user_id) ON DELETE CASCADE,
    fundamental_frequency_f0 DOUBLE PRECISION NOT NULL,
    spectral_centroid DOUBLE PRECISION NOT NULL,
    formant_dispersion DOUBLE PRECISION NOT NULL,
    sample_count INTEGER NOT NULL DEFAULT 3,
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS icarus_memory_records (
    memory_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) REFERENCES icarus_user_profiles(user_id) ON DELETE CASCADE,
    memory_tier VARCHAR(32) NOT NULL, -- 'WORKING', 'EPISODIC', 'SEMANTIC', 'PROCEDURAL'
    key_concept VARCHAR(128) NOT NULL,
    content TEXT NOT NULL,
    confidence DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    access_count INTEGER NOT NULL DEFAULT 1,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS icarus_action_authorizations (
    auth_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) REFERENCES icarus_user_profiles(user_id) ON DELETE CASCADE,
    action_type VARCHAR(64) NOT NULL,
    permission_category VARCHAR(32) NOT NULL, -- 'CATEGORY_A', 'CATEGORY_B', 'CATEGORY_C', 'CATEGORY_D', 'CATEGORY_E'
    target_resource VARCHAR(256) NOT NULL,
    confirmation_token VARCHAR(64) NOT NULL,
    speaker_verified BOOLEAN NOT NULL DEFAULT FALSE,
    authorized BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    executed_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS icarus_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    spoken_phrase TEXT NOT NULL,
    intent_recognized VARCHAR(64) NOT NULL,
    voice_match_score DOUBLE PRECISION,
    executed_tool VARCHAR(64),
    response_speech_length_sec DOUBLE PRECISION,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_icarus_memory_user ON icarus_memory_records(user_id, memory_tier);
CREATE INDEX IF NOT EXISTS idx_icarus_audit_user ON icarus_audit_logs(user_id, timestamp DESC);

-- =============================================================================
-- RICE UNIVERSITY URL SHORTENER & QR STUDIO: INITIAL DATABASE SCHEMA
-- Compatible with PostgreSQL 14, 15, and 16
-- =============================================================================

-- Enable UUID extension if available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: short_link
CREATE TABLE IF NOT EXISTS short_link (
    id SERIAL PRIMARY KEY,
    link_id VARCHAR(64) UNIQUE NOT NULL,
    user_id VARCHAR(128) NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    short_code VARCHAR(64) UNIQUE NOT NULL,
    destination_url TEXT NOT NULL,
    fallback_url TEXT DEFAULT 'https://rice.edu',
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    click_count BIGINT NOT NULL DEFAULT 0,
    last_clicked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    qr_config_json JSONB
);

-- Optimized B-Tree indexes for ultra-fast link resolution and dashboard queries
CREATE INDEX IF NOT EXISTS idx_short_link_code ON short_link (LOWER(short_code));
CREATE INDEX IF NOT EXISTS idx_short_link_user_id ON short_link (user_id);
CREATE INDEX IF NOT EXISTS idx_short_link_created_at ON short_link (created_at DESC);

-- Table: link_analytics_event
CREATE TABLE IF NOT EXISTS link_analytics_event (
    id BIGSERIAL PRIMARY KEY,
    link_id VARCHAR(64) NOT NULL,
    short_code VARCHAR(64) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_agent TEXT,
    referer TEXT,
    ip_address VARCHAR(45)
);

CREATE INDEX IF NOT EXISTS idx_analytics_short_code ON link_analytics_event (short_code);
CREATE INDEX IF NOT EXISTS idx_analytics_timestamp ON link_analytics_event (timestamp DESC);

-- Seed Initial Demo Data for Rice University
INSERT INTO short_link (
    link_id, user_id, user_email, short_code, destination_url, fallback_url,
    is_active, click_count, created_at, updated_at, qr_config_json
) VALUES (
    'campanile', 'rice_demo_uid_1912', 'sammy.owl@rice.edu', 'campanile',
    'https://rice.edu/about', 'https://rice.edu', TRUE, 142,
    NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days',
    '{"fgColorHex":"#00205B","bgColorHex":"#FFFFFF","style":"square","logoType":"shield"}'
) ON CONFLICT (short_code) DO NOTHING;

INSERT INTO short_link (
    link_id, user_id, user_email, short_code, destination_url, fallback_url,
    expires_at, is_active, click_count, created_at, updated_at, qr_config_json
) VALUES (
    'fest26', 'rice_demo_uid_1912', 'sammy.owl@rice.edu', 'fest26',
    'https://events.rice.edu', 'https://rice.edu',
    NOW() + INTERVAL '5 days', TRUE, 38,
    NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours',
    '{"fgColorHex":"#00205B","bgColorHex":"#FFFFFF","style":"rounded","logoType":"owl"}'
) ON CONFLICT (short_code) DO NOTHING;


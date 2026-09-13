-- ============================================================
-- SHAMBA SMART MOBILE — companion cache tables
-- Run in addition to shamba_smart_supabase_v3_agentic.sql.
-- These back the "pull" side of SyncService (news + weather
-- caches consumed read-only by the mobile app).
-- ============================================================

CREATE TABLE IF NOT EXISTS public.farm_news (
    id          uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    title       text NOT NULL,
    publisher   text,
    time_ago    text,
    category    text,
    content_url text,
    cached_at   timestamptz DEFAULT now()
);
ALTER TABLE public.farm_news ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "farm_news_read_all" ON public.farm_news;
CREATE POLICY "farm_news_read_all" ON public.farm_news FOR SELECT USING (true);

CREATE TABLE IF NOT EXISTS public.weather_cache (
    id           uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    location     text,
    current_temp numeric,
    condition    text,
    humidity     integer,
    wind_speed   numeric,
    updated_at   timestamptz DEFAULT now()
);
ALTER TABLE public.weather_cache ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "weather_cache_read_all" ON public.weather_cache;
CREATE POLICY "weather_cache_read_all" ON public.weather_cache FOR SELECT USING (true);

-- actuator_states: needed by SyncService._pushActuatorStates upsert
CREATE TABLE IF NOT EXISTS public.actuator_states (
    device_id           text PRIMARY KEY,
    user_id             uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    water_pump_enabled  boolean DEFAULT false,
    last_updated        timestamptz DEFAULT now()
);
ALTER TABLE public.actuator_states ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "actuator_states_own" ON public.actuator_states;
CREATE POLICY "actuator_states_own" ON public.actuator_states
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- soil_logs: needed by SyncService._pushSoilLogs upsert
CREATE TABLE IF NOT EXISTS public.soil_logs (
    id              uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id         uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id       text,
    soil_moisture   numeric,
    ph              numeric,
    ec              numeric,
    temperature     numeric,
    humidity        numeric,
    recorded_at     timestamptz,
    created_at      timestamptz DEFAULT now()
);
ALTER TABLE public.soil_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "soil_logs_own" ON public.soil_logs;
CREATE POLICY "soil_logs_own" ON public.soil_logs
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_soil_logs_user_recorded ON public.soil_logs(user_id, recorded_at DESC);

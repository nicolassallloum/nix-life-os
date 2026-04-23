STEP 3 — Database Master Design
Size:1,093,328,896 bytes
DB Size:10119 kB
-- =========================================================
-- NIX LIFE OS
-- Full PostgreSQL Executable Schema Script
-- PostgreSQL 14+
-- =========================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

CREATE SCHEMA IF NOT EXISTS nix_life_os;

SET search_path TO nix_life_os, public;

-- =========================================================
-- FUNCTIONS
-- =========================================================

CREATE OR REPLACE FUNCTION nix_life_os.fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

-- =========================================================
-- CORE TABLES
-- =========================================================

CREATE TABLE nix_life_os.app_user (
    user_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email                CITEXT NOT NULL UNIQUE,
    username             CITEXT UNIQUE,
    password_hash        TEXT NOT NULL,
    full_name            VARCHAR(150) NOT NULL,
    phone_number         VARCHAR(30),
    timezone             VARCHAR(100) NOT NULL DEFAULT 'Asia/Beirut',
    locale               VARCHAR(20) NOT NULL DEFAULT 'en',
    currency_code        CHAR(3) NOT NULL DEFAULT 'USD',
    date_of_birth        DATE,
    gender               VARCHAR(30),
    profile_image_url    TEXT,
    status               VARCHAR(20) NOT NULL DEFAULT 'active'
                         CHECK (status IN ('active', 'inactive', 'locked', 'deleted')),
    email_verified_at    TIMESTAMPTZ,
    last_login_at        TIMESTAMPTZ,
    preferences_json     JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_app_user_status ON nix_life_os.app_user(status);
CREATE INDEX idx_app_user_created_at ON nix_life_os.app_user(created_at);

CREATE TABLE nix_life_os.household (
    household_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id        UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    name                 VARCHAR(150) NOT NULL,
    description          TEXT,
    settings_json        JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_household_owner ON nix_life_os.household(owner_user_id);

CREATE TABLE nix_life_os.household_member (
    household_member_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id         UUID NOT NULL REFERENCES nix_life_os.household(household_id) ON DELETE CASCADE,
    user_id              UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    role                 VARCHAR(30) NOT NULL DEFAULT 'member'
                         CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    joined_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (household_id, user_id)
);

CREATE INDEX idx_household_member_user ON nix_life_os.household_member(user_id);

CREATE TABLE nix_life_os.tag (
    tag_id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    module_name          VARCHAR(30) NOT NULL
                         CHECK (module_name IN ('finance', 'health', 'projects', 'medication', 'diary', 'shared')),
    tag_name             VARCHAR(100) NOT NULL,
    color_hex            VARCHAR(7),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, module_name, tag_name)
);

CREATE INDEX idx_tag_user_module ON nix_life_os.tag(user_id, module_name);

CREATE TABLE nix_life_os.file_asset (
    file_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    storage_provider     VARCHAR(30) NOT NULL DEFAULT 'local'
                         CHECK (storage_provider IN ('local', 's3', 'gcs', 'azure')),
    storage_path         TEXT NOT NULL,
    original_file_name   TEXT NOT NULL,
    mime_type            VARCHAR(200),
    file_size_bytes      BIGINT NOT NULL CHECK (file_size_bytes >= 0),
    checksum_sha256      CHAR(64),
    metadata_json        JSONB NOT NULL DEFAULT '{}'::JSONB,
    uploaded_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_file_asset_user ON nix_life_os.file_asset(user_id);
CREATE INDEX idx_file_asset_uploaded_at ON nix_life_os.file_asset(uploaded_at);

CREATE TABLE nix_life_os.audit_log (
    audit_id             BIGSERIAL PRIMARY KEY,
    user_id              UUID REFERENCES nix_life_os.app_user(user_id) ON DELETE SET NULL,
    module_name          VARCHAR(30) NOT NULL,
    entity_name          VARCHAR(100) NOT NULL,
    entity_id            UUID,
    action_name          VARCHAR(30) NOT NULL
                         CHECK (action_name IN ('create', 'update', 'delete', 'login', 'logout', 'export', 'view')),
    old_data_json        JSONB,
    new_data_json        JSONB,
    request_id           UUID,
    ip_address           INET,
    user_agent           TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_log_user_created ON nix_life_os.audit_log(user_id, created_at DESC);
CREATE INDEX idx_audit_log_module_entity ON nix_life_os.audit_log(module_name, entity_name, created_at DESC);
CREATE INDEX idx_audit_log_created_at ON nix_life_os.audit_log(created_at DESC);

-- =========================================================
-- FINANCE MODULE
-- =========================================================

CREATE TABLE nix_life_os.finance_account_type (
    account_type_id      SMALLSERIAL PRIMARY KEY,
    code                 VARCHAR(30) NOT NULL UNIQUE,
    name                 VARCHAR(100) NOT NULL
);

CREATE TABLE nix_life_os.finance_category (
    category_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    parent_category_id   UUID REFERENCES nix_life_os.finance_category(category_id) ON DELETE SET NULL,
    category_type        VARCHAR(20) NOT NULL
                         CHECK (category_type IN ('income', 'expense', 'transfer')),
    name                 VARCHAR(120) NOT NULL,
    icon_name            VARCHAR(100),
    color_hex            VARCHAR(7),
    sort_order           INTEGER NOT NULL DEFAULT 0,
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (user_id, category_type, name)
);

CREATE INDEX idx_finance_category_user_type ON nix_life_os.finance_category(user_id, category_type, is_active);
CREATE INDEX idx_finance_category_parent ON nix_life_os.finance_category(parent_category_id);

CREATE TABLE nix_life_os.finance_account (
    account_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    account_type_id       SMALLINT NOT NULL REFERENCES nix_life_os.finance_account_type(account_type_id),
    name                  VARCHAR(120) NOT NULL,
    institution_name      VARCHAR(150),
    account_number_masked VARCHAR(50),
    currency_code         CHAR(3) NOT NULL,
    opening_balance       NUMERIC(18,2) NOT NULL DEFAULT 0,
    current_balance       NUMERIC(18,2) NOT NULL DEFAULT 0,
    credit_limit          NUMERIC(18,2),
    is_archived           BOOLEAN NOT NULL DEFAULT FALSE,
    metadata_json         JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, name)
);

CREATE INDEX idx_finance_account_user ON nix_life_os.finance_account(user_id, is_archived);
CREATE INDEX idx_finance_account_type ON nix_life_os.finance_account(account_type_id);
CREATE INDEX idx_finance_account_currency ON nix_life_os.finance_account(currency_code);

CREATE TABLE nix_life_os.finance_transaction (
    transaction_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    account_id             UUID NOT NULL REFERENCES nix_life_os.finance_account(account_id) ON DELETE RESTRICT,
    category_id            UUID REFERENCES nix_life_os.finance_category(category_id) ON DELETE SET NULL,
    related_transfer_txn_id UUID REFERENCES nix_life_os.finance_transaction(transaction_id) ON DELETE SET NULL,
    transaction_type       VARCHAR(20) NOT NULL
                           CHECK (transaction_type IN ('income', 'expense', 'transfer_in', 'transfer_out', 'adjustment')),
    amount                 NUMERIC(18,2) NOT NULL CHECK (amount >= 0),
    currency_code          CHAR(3) NOT NULL,
    transaction_date       DATE NOT NULL,
    merchant_name          VARCHAR(150),
    note                   TEXT,
    payment_method         VARCHAR(50),
    external_reference     VARCHAR(100),
    location_json          JSONB,
    receipt_snapshot_json  JSONB,
    metadata_json          JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_finance_txn_user_date ON nix_life_os.finance_transaction(user_id, transaction_date DESC);
CREATE INDEX idx_finance_txn_account_date ON nix_life_os.finance_transaction(account_id, transaction_date DESC);
CREATE INDEX idx_finance_txn_category_date ON nix_life_os.finance_transaction(category_id, transaction_date DESC);
CREATE INDEX idx_finance_txn_type_date ON nix_life_os.finance_transaction(transaction_type, transaction_date DESC);
CREATE INDEX idx_finance_txn_created_at ON nix_life_os.finance_transaction(created_at DESC);
CREATE INDEX idx_finance_txn_metadata_gin ON nix_life_os.finance_transaction USING GIN (metadata_json);

CREATE TABLE nix_life_os.finance_transaction_tag (
    transaction_id         UUID NOT NULL REFERENCES nix_life_os.finance_transaction(transaction_id) ON DELETE CASCADE,
    tag_id                 UUID NOT NULL REFERENCES nix_life_os.tag(tag_id) ON DELETE CASCADE,
    PRIMARY KEY (transaction_id, tag_id)
);

CREATE TABLE nix_life_os.finance_budget (
    budget_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    category_id            UUID NOT NULL REFERENCES nix_life_os.finance_category(category_id) ON DELETE CASCADE,
    budget_name            VARCHAR(120) NOT NULL,
    period_type            VARCHAR(20) NOT NULL
                           CHECK (period_type IN ('weekly', 'monthly', 'quarterly', 'yearly')),
    amount_limit           NUMERIC(18,2) NOT NULL CHECK (amount_limit > 0),
    start_date             DATE NOT NULL,
    end_date               DATE,
    alert_threshold_pct    NUMERIC(5,2) DEFAULT 80 CHECK (alert_threshold_pct BETWEEN 0 AND 100),
    is_active              BOOLEAN NOT NULL DEFAULT TRUE,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_finance_budget_user_active ON nix_life_os.finance_budget(user_id, is_active);
CREATE INDEX idx_finance_budget_category ON nix_life_os.finance_budget(category_id);

CREATE TABLE nix_life_os.finance_savings_goal (
    goal_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    account_id             UUID REFERENCES nix_life_os.finance_account(account_id) ON DELETE SET NULL,
    goal_name              VARCHAR(150) NOT NULL,
    target_amount          NUMERIC(18,2) NOT NULL CHECK (target_amount > 0),
    current_amount         NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    target_date            DATE,
    priority_level         SMALLINT NOT NULL DEFAULT 3 CHECK (priority_level BETWEEN 1 AND 5),
    status                 VARCHAR(20) NOT NULL DEFAULT 'active'
                           CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),
    notes                  TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_savings_goal_user_status ON nix_life_os.finance_savings_goal(user_id, status);

CREATE TABLE nix_life_os.finance_recurring_entry (
    recurring_entry_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    account_id             UUID NOT NULL REFERENCES nix_life_os.finance_account(account_id) ON DELETE CASCADE,
    category_id            UUID REFERENCES nix_life_os.finance_category(category_id) ON DELETE SET NULL,
    transaction_type       VARCHAR(20) NOT NULL
                           CHECK (transaction_type IN ('income', 'expense')),
    amount                 NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    currency_code          CHAR(3) NOT NULL,
    description            VARCHAR(200),
    recurrence_rule        VARCHAR(200) NOT NULL,
    next_run_at            TIMESTAMPTZ NOT NULL,
    last_run_at            TIMESTAMPTZ,
    is_active              BOOLEAN NOT NULL DEFAULT TRUE,
    metadata_json          JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recurring_entry_next_run ON nix_life_os.finance_recurring_entry(is_active, next_run_at);
CREATE INDEX idx_recurring_entry_user ON nix_life_os.finance_recurring_entry(user_id, is_active);

-- =========================================================
-- HEALTH MODULE
-- =========================================================

CREATE TABLE nix_life_os.health_profile (
    health_profile_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL UNIQUE REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    height_cm              NUMERIC(5,2),
    target_weight_kg       NUMERIC(6,2),
    blood_type             VARCHAR(5),
    activity_level         VARCHAR(20)
                           CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')),
    diet_preferences_json  JSONB NOT NULL DEFAULT '{}'::JSONB,
    conditions_json        JSONB NOT NULL DEFAULT '[]'::JSONB,
    allergies_json         JSONB NOT NULL DEFAULT '[]'::JSONB,
    emergency_contact_json JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_health_profile_conditions_gin ON nix_life_os.health_profile USING GIN (conditions_json);
CREATE INDEX idx_health_profile_allergies_gin ON nix_life_os.health_profile USING GIN (allergies_json);

CREATE TABLE nix_life_os.health_weight_log (
    weight_log_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    measured_at            TIMESTAMPTZ NOT NULL,
    weight_kg              NUMERIC(6,2) NOT NULL CHECK (weight_kg > 0),
    body_fat_pct           NUMERIC(5,2),
    bmi                    NUMERIC(5,2),
    source                 VARCHAR(30) DEFAULT 'manual',
    notes                  TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_weight_log_user_measured ON nix_life_os.health_weight_log(user_id, measured_at DESC);

CREATE TABLE nix_life_os.health_vitals_log (
    vitals_log_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    measured_at            TIMESTAMPTZ NOT NULL,
    systolic_bp            SMALLINT CHECK (systolic_bp > 0),
    diastolic_bp           SMALLINT CHECK (diastolic_bp > 0),
    heart_rate_bpm         SMALLINT CHECK (heart_rate_bpm > 0),
    blood_glucose_mg_dl    NUMERIC(7,2),
    oxygen_saturation_pct  NUMERIC(5,2),
    temperature_c          NUMERIC(4,2),
    source                 VARCHAR(30) DEFAULT 'manual',
    notes                  TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vitals_log_user_measured ON nix_life_os.health_vitals_log(user_id, measured_at DESC);

CREATE TABLE nix_life_os.health_step_log (
    step_log_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    log_date               DATE NOT NULL,
    steps_count            INTEGER NOT NULL CHECK (steps_count >= 0),
    distance_km            NUMERIC(8,3),
    calories_burned        NUMERIC(8,2),
    source                 VARCHAR(30) DEFAULT 'manual',
    source_payload_json    JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, log_date, source)
);

CREATE INDEX idx_step_log_user_date ON nix_life_os.health_step_log(user_id, log_date DESC);
CREATE INDEX idx_step_log_payload_gin ON nix_life_os.health_step_log USING GIN (source_payload_json);

CREATE TABLE nix_life_os.health_exercise_log (
    exercise_log_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    started_at             TIMESTAMPTZ NOT NULL,
    ended_at               TIMESTAMPTZ,
    activity_type          VARCHAR(50) NOT NULL,
    duration_minutes       INTEGER CHECK (duration_minutes >= 0),
    calories_burned        NUMERIC(8,2),
    distance_km            NUMERIC(8,3),
    intensity_level        VARCHAR(20)
                           CHECK (intensity_level IN ('low', 'moderate', 'high')),
    notes                  TEXT,
    metrics_json           JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_exercise_log_user_started ON nix_life_os.health_exercise_log(user_id, started_at DESC);
CREATE INDEX idx_exercise_log_activity_type ON nix_life_os.health_exercise_log(activity_type);
CREATE INDEX idx_exercise_log_metrics_gin ON nix_life_os.health_exercise_log USING GIN (metrics_json);

CREATE TABLE nix_life_os.health_food_item (
    food_item_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    food_name              VARCHAR(200) NOT NULL,
    serving_size           VARCHAR(100),
    calories               NUMERIC(8,2),
    protein_g              NUMERIC(8,2),
    carbs_g                NUMERIC(8,2),
    fat_g                  NUMERIC(8,2),
    fiber_g                NUMERIC(8,2),
    sodium_mg              NUMERIC(10,2),
    potassium_mg           NUMERIC(10,2),
    phosphorus_mg          NUMERIC(10,2),
    sugar_g                NUMERIC(8,2),
    source                 VARCHAR(20) NOT NULL DEFAULT 'custom'
                           CHECK (source IN ('system', 'custom', 'api')),
    metadata_json          JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_food_item_name ON nix_life_os.health_food_item(food_name);
CREATE INDEX idx_food_item_user ON nix_life_os.health_food_item(user_id);
CREATE INDEX idx_food_item_metadata_gin ON nix_life_os.health_food_item USING GIN (metadata_json);

CREATE TABLE nix_life_os.health_meal_log (
    meal_log_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    meal_type              VARCHAR(20) NOT NULL
                           CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'other')),
    consumed_at            TIMESTAMPTZ NOT NULL,
    notes                  TEXT,
    total_calories         NUMERIC(10,2),
    totals_json            JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_meal_log_user_consumed ON nix_life_os.health_meal_log(user_id, consumed_at DESC);
CREATE INDEX idx_meal_log_totals_gin ON nix_life_os.health_meal_log USING GIN (totals_json);

CREATE TABLE nix_life_os.health_meal_item (
    meal_item_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_log_id            UUID NOT NULL REFERENCES nix_life_os.health_meal_log(meal_log_id) ON DELETE CASCADE,
    food_item_id           UUID REFERENCES nix_life_os.health_food_item(food_item_id) ON DELETE SET NULL,
    item_name_snapshot     VARCHAR(200) NOT NULL,
    quantity               NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    unit                   VARCHAR(50),
    calories               NUMERIC(8,2),
    protein_g              NUMERIC(8,2),
    carbs_g                NUMERIC(8,2),
    fat_g                  NUMERIC(8,2),
    fiber_g                NUMERIC(8,2),
    sodium_mg              NUMERIC(10,2),
    potassium_mg           NUMERIC(10,2),
    phosphorus_mg          NUMERIC(10,2),
    sugar_g                NUMERIC(8,2),
    metadata_json          JSONB NOT NULL DEFAULT '{}'::JSONB
);

CREATE INDEX idx_meal_item_meal_log ON nix_life_os.health_meal_item(meal_log_id);
CREATE INDEX idx_meal_item_food_item ON nix_life_os.health_meal_item(food_item_id);

CREATE TABLE nix_life_os.health_sleep_log (
    sleep_log_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    sleep_start_at         TIMESTAMPTZ NOT NULL,
    sleep_end_at           TIMESTAMPTZ NOT NULL,
    duration_minutes       INTEGER GENERATED ALWAYS AS (
                               GREATEST(0, FLOOR(EXTRACT(EPOCH FROM (sleep_end_at - sleep_start_at)) / 60))::INTEGER
                           ) STORED,
    sleep_quality          SMALLINT CHECK (sleep_quality BETWEEN 1 AND 10),
    source                 VARCHAR(30) DEFAULT 'manual',
    stages_json            JSONB NOT NULL DEFAULT '{}'::JSONB,
    notes                  TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (sleep_end_at > sleep_start_at)
);

CREATE INDEX idx_sleep_log_user_start ON nix_life_os.health_sleep_log(user_id, sleep_start_at DESC);
CREATE INDEX idx_sleep_log_stages_gin ON nix_life_os.health_sleep_log USING GIN (stages_json);

CREATE TABLE nix_life_os.health_symptom_log (
    symptom_log_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    logged_at              TIMESTAMPTZ NOT NULL,
    symptom_name           VARCHAR(150) NOT NULL,
    severity_level         SMALLINT CHECK (severity_level BETWEEN 1 AND 10),
    duration_minutes       INTEGER CHECK (duration_minutes >= 0),
    body_area              VARCHAR(100),
    notes                  TEXT,
    metadata_json          JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_symptom_log_user_logged ON nix_life_os.health_symptom_log(user_id, logged_at DESC);
CREATE INDEX idx_symptom_log_name ON nix_life_os.health_symptom_log(symptom_name);
CREATE INDEX idx_symptom_log_metadata_gin ON nix_life_os.health_symptom_log USING GIN (metadata_json);

-- =========================================================
-- MEDICATION MODULE
-- =========================================================

CREATE TABLE nix_life_os.medication_item (
    medication_item_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    medication_name        VARCHAR(200) NOT NULL,
    generic_name           VARCHAR(200),
    form                   VARCHAR(50),
    strength               VARCHAR(50),
    manufacturer           VARCHAR(150),
    is_prescription        BOOLEAN NOT NULL DEFAULT FALSE,
    instructions           TEXT,
    metadata_json          JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_medication_item_user_name_strength
ON nix_life_os.medication_item (
    user_id,
    medication_name,
    COALESCE(strength, '')
);

CREATE INDEX idx_medication_item_user ON nix_life_os.medication_item(user_id);
CREATE INDEX idx_medication_item_name ON nix_life_os.medication_item(medication_name);
CREATE INDEX idx_medication_item_metadata_gin ON nix_life_os.medication_item USING GIN (metadata_json);

CREATE TABLE nix_life_os.medication_schedule (
    medication_schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    medication_item_id     UUID NOT NULL REFERENCES nix_life_os.medication_item(medication_item_id) ON DELETE CASCADE,
    dosage_amount          NUMERIC(10,2) NOT NULL CHECK (dosage_amount > 0),
    dosage_unit            VARCHAR(30) NOT NULL,
    route                  VARCHAR(50),
    frequency_type         VARCHAR(30) NOT NULL
                           CHECK (frequency_type IN ('daily', 'weekly', 'interval', 'as_needed', 'custom')),
    recurrence_rule        VARCHAR(200),
    start_date             DATE NOT NULL,
    end_date               DATE,
    scheduled_times_json   JSONB NOT NULL DEFAULT '[]'::JSONB,
    indication             TEXT,
    prescriber_name        VARCHAR(150),
    pharmacy_name          VARCHAR(150),
    instructions           TEXT,
    is_active              BOOLEAN NOT NULL DEFAULT TRUE,
    metadata_json          JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_med_schedule_user_active ON nix_life_os.medication_schedule(user_id, is_active);
CREATE INDEX idx_med_schedule_item ON nix_life_os.medication_schedule(medication_item_id);
CREATE INDEX idx_med_schedule_start_end ON nix_life_os.medication_schedule(start_date, end_date);
CREATE INDEX idx_med_schedule_times_gin ON nix_life_os.medication_schedule USING GIN (scheduled_times_json);

CREATE TABLE nix_life_os.medication_intake_log (
    intake_log_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    medication_schedule_id UUID REFERENCES nix_life_os.medication_schedule(medication_schedule_id) ON DELETE SET NULL,
    medication_item_id     UUID NOT NULL REFERENCES nix_life_os.medication_item(medication_item_id) ON DELETE RESTRICT,
    scheduled_at           TIMESTAMPTZ,
    taken_at               TIMESTAMPTZ,
    dosage_amount          NUMERIC(10,2) NOT NULL CHECK (dosage_amount > 0),
    dosage_unit            VARCHAR(30) NOT NULL,
    status                 VARCHAR(20) NOT NULL
                           CHECK (status IN ('taken', 'missed', 'skipped', 'delayed')),
    notes                  TEXT,
    side_effects_json      JSONB NOT NULL DEFAULT '[]'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_med_intake_user_taken ON nix_life_os.medication_intake_log(user_id, taken_at DESC);
CREATE INDEX idx_med_intake_schedule ON nix_life_os.medication_intake_log(medication_schedule_id);
CREATE INDEX idx_med_intake_item ON nix_life_os.medication_intake_log(medication_item_id);
CREATE INDEX idx_med_intake_status ON nix_life_os.medication_intake_log(status);
CREATE INDEX idx_med_intake_sideeffects_gin ON nix_life_os.medication_intake_log USING GIN (side_effects_json);

CREATE TABLE nix_life_os.medication_refill (
    refill_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    medication_item_id     UUID NOT NULL REFERENCES nix_life_os.medication_item(medication_item_id) ON DELETE CASCADE,
    refill_date            DATE NOT NULL,
    quantity               NUMERIC(10,2) CHECK (quantity >= 0),
    unit                   VARCHAR(30),
    pharmacy_name          VARCHAR(150),
    cost_amount            NUMERIC(18,2),
    currency_code          CHAR(3),
    notes                  TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_med_refill_user_date ON nix_life_os.medication_refill(user_id, refill_date DESC);
CREATE INDEX idx_med_refill_item ON nix_life_os.medication_refill(medication_item_id);

-- =========================================================
-- PROJECTS MODULE
-- =========================================================

CREATE TABLE nix_life_os.project (
    project_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id          UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    household_id           UUID REFERENCES nix_life_os.household(household_id) ON DELETE SET NULL,
    name                   VARCHAR(200) NOT NULL,
    description            TEXT,
    status                 VARCHAR(20) NOT NULL DEFAULT 'planned'
                           CHECK (status IN ('planned', 'active', 'on_hold', 'completed', 'cancelled')),
    priority_level         SMALLINT NOT NULL DEFAULT 3 CHECK (priority_level BETWEEN 1 AND 5),
    start_date             DATE,
    due_date               DATE,
    completed_at           TIMESTAMPTZ,
    progress_pct           NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (progress_pct BETWEEN 0 AND 100),
    settings_json          JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_project_owner_status ON nix_life_os.project(owner_user_id, status);
CREATE INDEX idx_project_household ON nix_life_os.project(household_id);
CREATE INDEX idx_project_due_date ON nix_life_os.project(due_date);
CREATE INDEX idx_project_settings_gin ON nix_life_os.project USING GIN (settings_json);

CREATE TABLE nix_life_os.project_member (
    project_member_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id             UUID NOT NULL REFERENCES nix_life_os.project(project_id) ON DELETE CASCADE,
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    role                   VARCHAR(30) NOT NULL DEFAULT 'member'
                           CHECK (role IN ('owner', 'manager', 'member', 'viewer')),
    joined_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (project_id, user_id)
);

CREATE INDEX idx_project_member_user ON nix_life_os.project_member(user_id);

CREATE TABLE nix_life_os.project_milestone (
    milestone_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id             UUID NOT NULL REFERENCES nix_life_os.project(project_id) ON DELETE CASCADE,
    name                   VARCHAR(200) NOT NULL,
    description            TEXT,
    due_date               DATE,
    status                 VARCHAR(20) NOT NULL DEFAULT 'pending'
                           CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    sort_order             INTEGER NOT NULL DEFAULT 0,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_project_milestone_project ON nix_life_os.project_milestone(project_id, due_date);

CREATE TABLE nix_life_os.project_task (
    task_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id             UUID NOT NULL REFERENCES nix_life_os.project(project_id) ON DELETE CASCADE,
    milestone_id           UUID REFERENCES nix_life_os.project_milestone(milestone_id) ON DELETE SET NULL,
    parent_task_id         UUID REFERENCES nix_life_os.project_task(task_id) ON DELETE CASCADE,
    created_by_user_id     UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE RESTRICT,
    assigned_to_user_id    UUID REFERENCES nix_life_os.app_user(user_id) ON DELETE SET NULL,
    title                  VARCHAR(250) NOT NULL,
    description            TEXT,
    status                 VARCHAR(20) NOT NULL DEFAULT 'todo'
                           CHECK (status IN ('todo', 'in_progress', 'blocked', 'done', 'cancelled')),
    priority_level         SMALLINT NOT NULL DEFAULT 3 CHECK (priority_level BETWEEN 1 AND 5),
    start_at               TIMESTAMPTZ,
    due_at                 TIMESTAMPTZ,
    completed_at           TIMESTAMPTZ,
    estimated_minutes      INTEGER CHECK (estimated_minutes >= 0),
    actual_minutes         INTEGER CHECK (actual_minutes >= 0),
    position_no            INTEGER NOT NULL DEFAULT 0,
    extra_json             JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_project_task_project_status ON nix_life_os.project_task(project_id, status);
CREATE INDEX idx_project_task_assigned_due ON nix_life_os.project_task(assigned_to_user_id, due_at);
CREATE INDEX idx_project_task_milestone ON nix_life_os.project_task(milestone_id);
CREATE INDEX idx_project_task_parent ON nix_life_os.project_task(parent_task_id);
CREATE INDEX idx_project_task_created_at ON nix_life_os.project_task(created_at DESC);
CREATE INDEX idx_project_task_extra_gin ON nix_life_os.project_task USING GIN (extra_json);

CREATE TABLE nix_life_os.project_task_comment (
    comment_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id                UUID NOT NULL REFERENCES nix_life_os.project_task(task_id) ON DELETE CASCADE,
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    comment_text           TEXT NOT NULL,
    metadata_json          JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_task_comment_task_created ON nix_life_os.project_task_comment(task_id, created_at DESC);

CREATE TABLE nix_life_os.project_time_entry (
    time_entry_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id                UUID REFERENCES nix_life_os.project_task(task_id) ON DELETE SET NULL,
    project_id             UUID NOT NULL REFERENCES nix_life_os.project(project_id) ON DELETE CASCADE,
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    started_at             TIMESTAMPTZ NOT NULL,
    ended_at               TIMESTAMPTZ,
    duration_minutes       INTEGER CHECK (duration_minutes >= 0),
    note                   TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_time_entry_project_user ON nix_life_os.project_time_entry(project_id, user_id, started_at DESC);
CREATE INDEX idx_time_entry_task ON nix_life_os.project_time_entry(task_id);

CREATE TABLE nix_life_os.project_tag_link (
    project_id             UUID NOT NULL REFERENCES nix_life_os.project(project_id) ON DELETE CASCADE,
    tag_id                 UUID NOT NULL REFERENCES nix_life_os.tag(tag_id) ON DELETE CASCADE,
    PRIMARY KEY (project_id, tag_id)
);

-- =========================================================
-- DIARY MODULE
-- =========================================================

CREATE TABLE nix_life_os.diary_mood (
    mood_id                SMALLSERIAL PRIMARY KEY,
    mood_code              VARCHAR(30) NOT NULL UNIQUE,
    mood_label             VARCHAR(50) NOT NULL
);

CREATE TABLE nix_life_os.diary_entry (
    diary_entry_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    mood_id                SMALLINT REFERENCES nix_life_os.diary_mood(mood_id) ON DELETE SET NULL,
    title                  VARCHAR(200),
    entry_text             TEXT NOT NULL,
    entry_date             DATE NOT NULL,
    is_private             BOOLEAN NOT NULL DEFAULT TRUE,
    weather_snapshot_json  JSONB,
    ai_summary_json        JSONB,
    metadata_json          JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_diary_entry_user_date ON nix_life_os.diary_entry(user_id, entry_date DESC);
CREATE INDEX idx_diary_entry_mood ON nix_life_os.diary_entry(mood_id);
CREATE INDEX idx_diary_entry_metadata_gin ON nix_life_os.diary_entry USING GIN (metadata_json);
CREATE INDEX idx_diary_entry_ai_summary_gin ON nix_life_os.diary_entry USING GIN (ai_summary_json);

CREATE TABLE nix_life_os.diary_entry_tag (
    diary_entry_id         UUID NOT NULL REFERENCES nix_life_os.diary_entry(diary_entry_id) ON DELETE CASCADE,
    tag_id                 UUID NOT NULL REFERENCES nix_life_os.tag(tag_id) ON DELETE CASCADE,
    PRIMARY KEY (diary_entry_id, tag_id)
);

CREATE TABLE nix_life_os.diary_entry_file (
    diary_entry_id         UUID NOT NULL REFERENCES nix_life_os.diary_entry(diary_entry_id) ON DELETE CASCADE,
    file_id                UUID NOT NULL REFERENCES nix_life_os.file_asset(file_id) ON DELETE CASCADE,
    PRIMARY KEY (diary_entry_id, file_id)
);

-- =========================================================
-- REMINDERS / NOTIFICATIONS
-- =========================================================

CREATE TABLE nix_life_os.reminder (
    reminder_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    module_name            VARCHAR(30) NOT NULL
                           CHECK (module_name IN ('finance', 'health', 'projects', 'medication', 'diary', 'shared')),
    entity_name            VARCHAR(100),
    entity_id              UUID,
    title                  VARCHAR(200) NOT NULL,
    reminder_text          TEXT,
    remind_at              TIMESTAMPTZ NOT NULL,
    recurrence_rule        VARCHAR(200),
    status                 VARCHAR(20) NOT NULL DEFAULT 'scheduled'
                           CHECK (status IN ('scheduled', 'sent', 'dismissed', 'cancelled')),
    delivery_channels_json JSONB NOT NULL DEFAULT '[]'::JSONB,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reminder_user_remind_at ON nix_life_os.reminder(user_id, remind_at);
CREATE INDEX idx_reminder_status_remind_at ON nix_life_os.reminder(status, remind_at);
CREATE INDEX idx_reminder_channels_gin ON nix_life_os.reminder USING GIN (delivery_channels_json);

-- =========================================================
-- AI INSIGHTS
-- =========================================================

CREATE TABLE nix_life_os.ai_insight (
    insight_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    module_name            VARCHAR(30) NOT NULL
                           CHECK (module_name IN ('finance', 'health', 'projects', 'medication', 'diary', 'cross_module')),
    source_entity_name     VARCHAR(100),
    source_entity_id       UUID,
    insight_type           VARCHAR(100) NOT NULL,
    insight_payload        JSONB NOT NULL,
    valid_from             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_to               TIMESTAMPTZ,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_insight_user_module ON nix_life_os.ai_insight(user_id, module_name, created_at DESC);
CREATE INDEX idx_ai_insight_payload_gin ON nix_life_os.ai_insight USING GIN (insight_payload);

-- =========================================================
-- SEED DATA
-- =========================================================

INSERT INTO nix_life_os.finance_account_type (code, name) VALUES
('cash', 'Cash'),
('bank', 'Bank Account'),
('credit_card', 'Credit Card'),
('loan', 'Loan'),
('investment', 'Investment'),
('wallet', 'Digital Wallet')
ON CONFLICT (code) DO NOTHING;

INSERT INTO nix_life_os.diary_mood (mood_code, mood_label) VALUES
('great', 'Great'),
('good', 'Good'),
('neutral', 'Neutral'),
('bad', 'Bad'),
('awful', 'Awful')
ON CONFLICT (mood_code) DO NOTHING;

-- =========================================================
-- TRIGGERS
-- =========================================================

CREATE TRIGGER trg_app_user_updated_at
BEFORE UPDATE ON nix_life_os.app_user
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_household_updated_at
BEFORE UPDATE ON nix_life_os.household
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_finance_account_updated_at
BEFORE UPDATE ON nix_life_os.finance_account
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_finance_transaction_updated_at
BEFORE UPDATE ON nix_life_os.finance_transaction
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_finance_budget_updated_at
BEFORE UPDATE ON nix_life_os.finance_budget
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_finance_savings_goal_updated_at
BEFORE UPDATE ON nix_life_os.finance_savings_goal
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_finance_recurring_entry_updated_at
BEFORE UPDATE ON nix_life_os.finance_recurring_entry
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_health_profile_updated_at
BEFORE UPDATE ON nix_life_os.health_profile
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_medication_item_updated_at
BEFORE UPDATE ON nix_life_os.medication_item
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_medication_schedule_updated_at
BEFORE UPDATE ON nix_life_os.medication_schedule
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_project_updated_at
BEFORE UPDATE ON nix_life_os.project
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_project_milestone_updated_at
BEFORE UPDATE ON nix_life_os.project_milestone
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_project_task_updated_at
BEFORE UPDATE ON nix_life_os.project_task
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_diary_entry_updated_at
BEFORE UPDATE ON nix_life_os.diary_entry
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

CREATE TRIGGER trg_reminder_updated_at
BEFORE UPDATE ON nix_life_os.reminder
FOR EACH ROW EXECUTE FUNCTION nix_life_os.fn_set_updated_at();

COMMIT;
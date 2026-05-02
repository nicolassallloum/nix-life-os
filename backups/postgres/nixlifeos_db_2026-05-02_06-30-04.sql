--
-- PostgreSQL database dump
--

\restrict 5Qlbmnf9w0v8cMmI9Fwrrx00cviIltEc24IwoDcYzVl98lcVmPNNzMxS38cmJwf

-- Dumped from database version 18.3 (Debian 18.3-1.pgdg13+1)
-- Dumped by pg_dump version 18.3 (Debian 18.3-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ai; Type: SCHEMA; Schema: -; Owner: nixlifeos_user
--

CREATE SCHEMA ai;


ALTER SCHEMA ai OWNER TO nixlifeos_user;

--
-- Name: automation; Type: SCHEMA; Schema: -; Owner: nixlifeos_user
--

CREATE SCHEMA automation;


ALTER SCHEMA automation OWNER TO nixlifeos_user;

--
-- Name: finance; Type: SCHEMA; Schema: -; Owner: nixlifeos_user
--

CREATE SCHEMA finance;


ALTER SCHEMA finance OWNER TO nixlifeos_user;

--
-- Name: health; Type: SCHEMA; Schema: -; Owner: nixlifeos_user
--

CREATE SCHEMA health;


ALTER SCHEMA health OWNER TO nixlifeos_user;

--
-- Name: monitoring; Type: SCHEMA; Schema: -; Owner: nixlifeos_user
--

CREATE SCHEMA monitoring;


ALTER SCHEMA monitoring OWNER TO nixlifeos_user;

--
-- Name: nix_life_os; Type: SCHEMA; Schema: -; Owner: nixlifeos_user
--

CREATE SCHEMA nix_life_os;


ALTER SCHEMA nix_life_os OWNER TO nixlifeos_user;

--
-- Name: projects; Type: SCHEMA; Schema: -; Owner: nixlifeos_user
--

CREATE SCHEMA projects;


ALTER SCHEMA projects OWNER TO nixlifeos_user;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_alerts; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.ai_alerts (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    alert_type character varying(80) NOT NULL,
    module character varying(50) NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    severity character varying(30) DEFAULT 'warning'::character varying NOT NULL,
    risk_score numeric(8,2),
    trigger_data jsonb,
    alert_date date NOT NULL,
    is_resolved boolean DEFAULT false NOT NULL,
    resolved_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.ai_alerts OWNER TO nixlifeos_user;

--
-- Name: ai_insights; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.ai_insights (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    insight_type character varying(50) NOT NULL,
    category character varying(100),
    title character varying(255) NOT NULL,
    message text NOT NULL,
    severity character varying(30) DEFAULT 'info'::character varying NOT NULL,
    score numeric(8,2),
    metadata jsonb,
    insight_date date NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    is_archived boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.ai_insights OWNER TO nixlifeos_user;

--
-- Name: ai_predictions; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.ai_predictions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    prediction_type character varying(255) NOT NULL,
    prediction_date date NOT NULL,
    target_date date,
    current_value numeric(14,2),
    predicted_value numeric(14,2),
    change_value numeric(14,2),
    change_percentage numeric(8,2),
    input_summary jsonb,
    prediction_payload jsonb,
    confidence_level character varying(255) DEFAULT 'medium'::character varying NOT NULL,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.ai_predictions OWNER TO nixlifeos_user;

--
-- Name: ai_reports; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.ai_reports (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    report_type character varying(50) NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    title character varying(255) NOT NULL,
    summary text,
    finance_summary jsonb,
    health_summary jsonb,
    project_summary jsonb,
    recommendations jsonb,
    raw_metrics jsonb,
    overall_score numeric(8,2),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.ai_reports OWNER TO nixlifeos_user;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    module character varying(255),
    action character varying(255) NOT NULL,
    entity_type character varying(255),
    entity_id uuid,
    old_values jsonb,
    new_values jsonb,
    metadata jsonb,
    ip_address character varying(255),
    user_agent character varying(255),
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.audit_logs OWNER TO nixlifeos_user;

--
-- Name: automation_rules; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.automation_rules (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    rule_name character varying(255) NOT NULL,
    module character varying(255) NOT NULL,
    trigger_type character varying(255) NOT NULL,
    conditions jsonb,
    action_type character varying(255) DEFAULT 'create_notification'::character varying NOT NULL,
    action_payload jsonb,
    is_active boolean DEFAULT true NOT NULL,
    last_triggered_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.automation_rules OWNER TO nixlifeos_user;

--
-- Name: automation_trigger_logs; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.automation_trigger_logs (
    id uuid NOT NULL,
    automation_rule_id uuid NOT NULL,
    user_id uuid NOT NULL,
    status character varying(255) DEFAULT 'triggered'::character varying NOT NULL,
    evaluated_data jsonb,
    message text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.automation_trigger_logs OWNER TO nixlifeos_user;

--
-- Name: cache; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration bigint NOT NULL
);


ALTER TABLE public.cache OWNER TO nixlifeos_user;

--
-- Name: cache_locks; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration bigint NOT NULL
);


ALTER TABLE public.cache_locks OWNER TO nixlifeos_user;

--
-- Name: calorie_entries; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.calorie_entries (
    id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.calorie_entries OWNER TO nixlifeos_user;

--
-- Name: calorie_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.calorie_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.calorie_entries_id_seq OWNER TO nixlifeos_user;

--
-- Name: calorie_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.calorie_entries_id_seq OWNED BY public.calorie_entries.id;


--
-- Name: error_logs; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.error_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    level character varying(255) DEFAULT 'error'::character varying NOT NULL,
    module character varying(255),
    exception_class character varying(255),
    message text NOT NULL,
    file text,
    line integer,
    request_method character varying(255),
    request_url text,
    request_payload jsonb,
    trace text,
    metadata jsonb,
    ip_address character varying(255),
    user_agent character varying(255),
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.error_logs OWNER TO nixlifeos_user;

--
-- Name: expenses; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.expenses (
    id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.expenses OWNER TO nixlifeos_user;

--
-- Name: expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.expenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expenses_id_seq OWNER TO nixlifeos_user;

--
-- Name: expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.expenses_id_seq OWNED BY public.expenses.id;


--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.failed_jobs OWNER TO nixlifeos_user;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.failed_jobs_id_seq OWNER TO nixlifeos_user;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: health_food_items; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.health_food_items (
    id uuid NOT NULL,
    user_id uuid,
    food_name character varying(255) NOT NULL,
    brand_name character varying(255),
    category character varying(255),
    calories_per_100g numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    protein_per_100g numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    carbs_per_100g numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    fat_per_100g numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    sodium_per_100g_mg numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    potassium_per_100g_mg numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    phosphorus_per_100g_mg numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    is_ckd_friendly boolean DEFAULT false NOT NULL,
    is_custom boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.health_food_items OWNER TO nixlifeos_user;

--
-- Name: health_hydration_logs; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.health_hydration_logs (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    log_date date NOT NULL,
    log_time time(0) without time zone,
    drink_type character varying(50) DEFAULT 'water'::character varying NOT NULL,
    amount_ml numeric(8,2) NOT NULL,
    is_ckd_safe boolean DEFAULT true NOT NULL,
    source character varying(50) DEFAULT 'manual'::character varying NOT NULL,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.health_hydration_logs OWNER TO nixlifeos_user;

--
-- Name: health_meal_log_items; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.health_meal_log_items (
    id uuid NOT NULL,
    meal_log_id uuid NOT NULL,
    food_item_id uuid NOT NULL,
    quantity_g numeric(10,2) NOT NULL,
    calories numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    protein_g numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    carbs_g numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    fat_g numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    sodium_mg numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    potassium_mg numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    phosphorus_mg numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.health_meal_log_items OWNER TO nixlifeos_user;

--
-- Name: health_meal_logs; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.health_meal_logs (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    meal_date date NOT NULL,
    meal_type character varying(255) NOT NULL,
    meal_name character varying(255),
    notes text,
    total_calories numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    total_protein_g numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    total_carbs_g numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    total_fat_g numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    total_sodium_mg numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    total_potassium_mg numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    total_phosphorus_mg numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.health_meal_logs OWNER TO nixlifeos_user;

--
-- Name: health_nutrition_profiles; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.health_nutrition_profiles (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    profile_name character varying(255) DEFAULT 'CKD Daily Nutrition Profile'::character varying NOT NULL,
    daily_calories_min integer,
    daily_calories_max integer,
    daily_protein_max_g numeric(8,2),
    daily_carbs_max_g numeric(8,2),
    daily_fat_max_g numeric(8,2),
    daily_sodium_max_mg numeric(8,2),
    daily_potassium_max_mg numeric(8,2),
    daily_phosphorus_max_mg numeric(8,2),
    is_ckd_safe_mode boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.health_nutrition_profiles OWNER TO nixlifeos_user;

--
-- Name: health_profile; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.health_profile (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    daily_steps_goal integer DEFAULT 8000 NOT NULL,
    stride_length_cm numeric(6,2) DEFAULT '75'::numeric NOT NULL,
    distance_unit character varying(10) DEFAULT 'km'::character varying NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.health_profile OWNER TO nixlifeos_user;

--
-- Name: health_step_log; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.health_step_log (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    log_date date NOT NULL,
    steps_count integer DEFAULT 0 NOT NULL,
    distance_km numeric(10,3) DEFAULT '0'::numeric NOT NULL,
    goal_steps integer DEFAULT 8000 NOT NULL,
    goal_percentage numeric(6,2) DEFAULT '0'::numeric NOT NULL,
    goal_completed boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.health_step_log OWNER TO nixlifeos_user;

--
-- Name: health_weight_logs; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.health_weight_logs (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    log_date date NOT NULL,
    weight_kg numeric(6,2) NOT NULL,
    body_fat_percentage numeric(5,2),
    muscle_mass_kg numeric(6,2),
    bmi numeric(5,2),
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.health_weight_logs OWNER TO nixlifeos_user;

--
-- Name: health_weight_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.health_weight_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.health_weight_logs_id_seq OWNER TO nixlifeos_user;

--
-- Name: health_weight_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.health_weight_logs_id_seq OWNED BY public.health_weight_logs.id;


--
-- Name: incomes; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.incomes (
    id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.incomes OWNER TO nixlifeos_user;

--
-- Name: incomes_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.incomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.incomes_id_seq OWNER TO nixlifeos_user;

--
-- Name: incomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.incomes_id_seq OWNED BY public.incomes.id;


--
-- Name: job_batches; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


ALTER TABLE public.job_batches OWNER TO nixlifeos_user;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


ALTER TABLE public.jobs OWNER TO nixlifeos_user;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jobs_id_seq OWNER TO nixlifeos_user;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: life_balance_scores; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.life_balance_scores (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    target_date date NOT NULL,
    finance_score smallint DEFAULT '0'::smallint NOT NULL,
    health_score smallint DEFAULT '0'::smallint NOT NULL,
    productivity_score smallint DEFAULT '0'::smallint NOT NULL,
    overall_score smallint DEFAULT '0'::smallint NOT NULL,
    status character varying(255) DEFAULT 'unknown'::character varying NOT NULL,
    finance_breakdown jsonb,
    health_breakdown jsonb,
    productivity_breakdown jsonb,
    recommendations jsonb,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.life_balance_scores OWNER TO nixlifeos_user;

--
-- Name: life_notifications; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.life_notifications (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    notification_type character varying(80) NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    severity character varying(30) DEFAULT 'info'::character varying NOT NULL,
    source_module character varying(80),
    metadata jsonb,
    is_read boolean DEFAULT false NOT NULL,
    read_at timestamp(0) without time zone,
    scheduled_for timestamp(0) without time zone,
    triggered_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.life_notifications OWNER TO nixlifeos_user;

--
-- Name: migrations; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO nixlifeos_user;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO nixlifeos_user;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: model_has_permissions; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.model_has_permissions (
    permission_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id uuid NOT NULL
);


ALTER TABLE public.model_has_permissions OWNER TO nixlifeos_user;

--
-- Name: model_has_roles; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.model_has_roles (
    role_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id uuid NOT NULL
);


ALTER TABLE public.model_has_roles OWNER TO nixlifeos_user;

--
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.notification_preferences (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    meal_reminders_enabled boolean DEFAULT true NOT NULL,
    breakfast_time time(0) without time zone,
    lunch_time time(0) without time zone,
    dinner_time time(0) without time zone,
    weight_reminders_enabled boolean DEFAULT true NOT NULL,
    weight_reminder_time time(0) without time zone,
    expense_reminders_enabled boolean DEFAULT true NOT NULL,
    expense_reminder_time time(0) without time zone,
    finance_alerts_enabled boolean DEFAULT true NOT NULL,
    health_alerts_enabled boolean DEFAULT true NOT NULL,
    life_balance_alerts_enabled boolean DEFAULT true NOT NULL,
    daily_expense_warning_limit integer,
    life_balance_warning_score integer DEFAULT 60 NOT NULL,
    metadata jsonb,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.notification_preferences OWNER TO nixlifeos_user;

--
-- Name: permissions; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.permissions (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    guard_name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.permissions OWNER TO nixlifeos_user;

--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.permissions_id_seq OWNER TO nixlifeos_user;

--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.personal_access_tokens (
    id bigint NOT NULL,
    tokenable_type character varying(255) NOT NULL,
    tokenable_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    token character varying(64) NOT NULL,
    abilities text,
    last_used_at timestamp(0) without time zone,
    expires_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.personal_access_tokens OWNER TO nixlifeos_user;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personal_access_tokens_id_seq OWNER TO nixlifeos_user;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;


--
-- Name: plans; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.plans (
    id uuid NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    monthly_price numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    yearly_price numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    max_finance_accounts integer DEFAULT 3 NOT NULL,
    max_projects integer DEFAULT 3 NOT NULL,
    max_ai_insights_per_month integer DEFAULT 30 NOT NULL,
    max_notifications_per_month integer DEFAULT 100 NOT NULL,
    finance_module_enabled boolean DEFAULT true NOT NULL,
    health_module_enabled boolean DEFAULT true NOT NULL,
    projects_module_enabled boolean DEFAULT true NOT NULL,
    ai_module_enabled boolean DEFAULT false NOT NULL,
    automation_module_enabled boolean DEFAULT false NOT NULL,
    monitoring_module_enabled boolean DEFAULT false NOT NULL,
    features jsonb,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.plans OWNER TO nixlifeos_user;

--
-- Name: project_milestones; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.project_milestones (
    id uuid NOT NULL,
    project_id uuid NOT NULL,
    milestone_name character varying(255) NOT NULL,
    description text,
    target_date date,
    completed_date date,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    progress_percentage smallint DEFAULT '0'::smallint NOT NULL,
    weight numeric(8,2) DEFAULT '1'::numeric NOT NULL,
    metadata jsonb,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    CONSTRAINT project_milestones_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'blocked'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.project_milestones OWNER TO nixlifeos_user;

--
-- Name: project_status_updates; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.project_status_updates (
    id uuid NOT NULL,
    project_id uuid NOT NULL,
    task_id uuid,
    milestone_id uuid,
    update_title character varying(255) NOT NULL,
    update_description text,
    old_status character varying(255),
    new_status character varying(255),
    old_progress_percentage smallint,
    new_progress_percentage smallint,
    update_type character varying(255) DEFAULT 'manual'::character varying NOT NULL,
    metadata jsonb,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    CONSTRAINT project_status_updates_update_type_check CHECK (((update_type)::text = ANY ((ARRAY['manual'::character varying, 'task_progress'::character varying, 'milestone_progress'::character varying, 'auto_calculation'::character varying, 'status_change'::character varying])::text[])))
);


ALTER TABLE public.project_status_updates OWNER TO nixlifeos_user;

--
-- Name: project_tasks; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.project_tasks (
    id uuid NOT NULL,
    project_id uuid NOT NULL,
    user_id uuid NOT NULL,
    task_title character varying(255) NOT NULL,
    task_description text,
    status character varying(255) DEFAULT 'todo'::character varying NOT NULL,
    priority character varying(255) DEFAULT 'medium'::character varying NOT NULL,
    task_order integer DEFAULT 1 NOT NULL,
    start_date date,
    due_date date,
    completed_date date,
    progress_percentage numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    metadata jsonb,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    weight numeric(8,2) DEFAULT '1'::numeric NOT NULL,
    completed_at timestamp(0) without time zone
);


ALTER TABLE public.project_tasks OWNER TO nixlifeos_user;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.projects (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    project_name character varying(255) NOT NULL,
    project_code character varying(255),
    description text,
    status character varying(255) DEFAULT 'not_started'::character varying NOT NULL,
    priority character varying(255) DEFAULT 'medium'::character varying NOT NULL,
    start_date date,
    target_end_date date,
    actual_end_date date,
    progress_percentage numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    metadata jsonb,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.projects OWNER TO nixlifeos_user;

--
-- Name: role_has_permissions; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.role_has_permissions (
    permission_id bigint NOT NULL,
    role_id bigint NOT NULL
);


ALTER TABLE public.role_has_permissions OWNER TO nixlifeos_user;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    guard_name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.roles OWNER TO nixlifeos_user;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO nixlifeos_user;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: step_entries; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.step_entries (
    id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.step_entries OWNER TO nixlifeos_user;

--
-- Name: step_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.step_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.step_entries_id_seq OWNER TO nixlifeos_user;

--
-- Name: step_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.step_entries_id_seq OWNED BY public.step_entries.id;


--
-- Name: subscription_usage; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.subscription_usage (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    subscription_id uuid NOT NULL,
    finance_accounts_count integer DEFAULT 0 NOT NULL,
    projects_count integer DEFAULT 0 NOT NULL,
    ai_insights_used integer DEFAULT 0 NOT NULL,
    notifications_sent integer DEFAULT 0 NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.subscription_usage OWNER TO nixlifeos_user;

--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.subscriptions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    plan_id uuid NOT NULL,
    status character varying(255) DEFAULT 'active'::character varying NOT NULL,
    billing_cycle character varying(255) DEFAULT 'monthly'::character varying NOT NULL,
    started_at timestamp(0) without time zone,
    trial_ends_at timestamp(0) without time zone,
    current_period_starts_at timestamp(0) without time zone,
    current_period_ends_at timestamp(0) without time zone,
    cancelled_at timestamp(0) without time zone,
    payment_provider character varying(255),
    payment_customer_id character varying(255),
    payment_subscription_id character varying(255),
    metadata jsonb,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.subscriptions OWNER TO nixlifeos_user;

--
-- Name: system_monitoring_logs; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.system_monitoring_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    service_name character varying(255) NOT NULL,
    status character varying(255) DEFAULT 'healthy'::character varying NOT NULL,
    response_time_ms integer,
    metrics jsonb,
    message text,
    checked_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.system_monitoring_logs OWNER TO nixlifeos_user;

--
-- Name: tasks; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.tasks (
    id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.tasks OWNER TO nixlifeos_user;

--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tasks_id_seq OWNER TO nixlifeos_user;

--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    name character varying(150) NOT NULL,
    email character varying(190) NOT NULL,
    email_verified_at timestamp(0) without time zone,
    password character varying(255) NOT NULL,
    role character varying(50) DEFAULT 'user'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_login_at timestamp(0) without time zone,
    remember_token character varying(100),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.users OWNER TO nixlifeos_user;

--
-- Name: weight_entries; Type: TABLE; Schema: public; Owner: nixlifeos_user
--

CREATE TABLE public.weight_entries (
    id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.weight_entries OWNER TO nixlifeos_user;

--
-- Name: weight_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: nixlifeos_user
--

CREATE SEQUENCE public.weight_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.weight_entries_id_seq OWNER TO nixlifeos_user;

--
-- Name: weight_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nixlifeos_user
--

ALTER SEQUENCE public.weight_entries_id_seq OWNED BY public.weight_entries.id;


--
-- Name: calorie_entries id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.calorie_entries ALTER COLUMN id SET DEFAULT nextval('public.calorie_entries_id_seq'::regclass);


--
-- Name: expenses id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.expenses ALTER COLUMN id SET DEFAULT nextval('public.expenses_id_seq'::regclass);


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: health_weight_logs id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_weight_logs ALTER COLUMN id SET DEFAULT nextval('public.health_weight_logs_id_seq'::regclass);


--
-- Name: incomes id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.incomes ALTER COLUMN id SET DEFAULT nextval('public.incomes_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: personal_access_tokens id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: step_entries id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.step_entries ALTER COLUMN id SET DEFAULT nextval('public.step_entries_id_seq'::regclass);


--
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- Name: weight_entries id; Type: DEFAULT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.weight_entries ALTER COLUMN id SET DEFAULT nextval('public.weight_entries_id_seq'::regclass);


--
-- Data for Name: ai_alerts; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.ai_alerts (id, user_id, alert_type, module, title, message, severity, risk_score, trigger_data, alert_date, is_resolved, resolved_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: ai_insights; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.ai_insights (id, user_id, insight_type, category, title, message, severity, score, metadata, insight_date, is_read, is_archived, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: ai_predictions; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.ai_predictions (id, user_id, prediction_type, prediction_date, target_date, current_value, predicted_value, change_value, change_percentage, input_summary, prediction_payload, confidence_level, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: ai_reports; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.ai_reports (id, user_id, report_type, period_start, period_end, title, summary, finance_summary, health_summary, project_summary, recommendations, raw_metrics, overall_score, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.audit_logs (id, user_id, module, action, entity_type, entity_id, old_values, new_values, metadata, ip_address, user_agent, created_at) FROM stdin;
\.


--
-- Data for Name: automation_rules; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.automation_rules (id, user_id, rule_name, module, trigger_type, conditions, action_type, action_payload, is_active, last_triggered_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: automation_trigger_logs; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.automation_trigger_logs (id, automation_rule_id, user_id, status, evaluated_data, message, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: cache; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.cache (key, value, expiration) FROM stdin;
\.


--
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.cache_locks (key, owner, expiration) FROM stdin;
\.


--
-- Data for Name: calorie_entries; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.calorie_entries (id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: error_logs; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.error_logs (id, user_id, level, module, exception_class, message, file, line, request_method, request_url, request_payload, trace, metadata, ip_address, user_agent, created_at) FROM stdin;
019de645-1c2c-7201-a03e-a7ca9f4854bb	\N	error	global_exception_handler	Illuminate\\Database\\QueryException	SQLSTATE[42804]: Datatype mismatch: 7 ERROR:  foreign key constraint "subscriptions_user_id_foreign" cannot be implemented\nDETAIL:  Key columns "user_id" of the referencing table and "id" of the referenced table are of incompatible types: bigint and uuid. (Connection: pgsql, Host: 127.0.0.1, Port: 5445, Database: nixlifeos_db, SQL: alter table "subscriptions" add constraint "subscriptions_user_id_foreign" foreign key ("user_id") references "users" ("id") on delete cascade)	/u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Connection.php	841	GET	http://localhost	[]	#0 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Connection.php(797): Illuminate\\Database\\Connection->runQueryCallback()\n#1 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Connection.php(576): Illuminate\\Database\\Connection->run()\n#2 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Schema/Blueprint.php(121): Illuminate\\Database\\Connection->statement()\n#3 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Schema/Builder.php(690): Illuminate\\Database\\Schema\\Blueprint->build()\n#4 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Schema/Builder.php(508): Illuminate\\Database\\Schema\\Builder->build()\n#5 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Support/Facades/Facade.php(363): Illuminate\\Database\\Schema\\Builder->create()\n#6 /u01/nix-life-os/backend/database/migrations/2026_05_01_221333_create_subscriptions_table.php(11): Illuminate\\Support\\Facades\\Facade::__callStatic()\n#7 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(517): Illuminate\\Database\\Migrations\\Migration@anonymous->up()\n#8 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(442): Illuminate\\Database\\Migrations\\Migrator->runMethod()\n#9 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Concerns/ManagesTransactions.php(35): Illuminate\\Database\\Migrations\\Migrator->Illuminate\\Database\\Migrations\\{closure}()\n#10 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(450): Illuminate\\Database\\Connection->transaction()\n#11 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(253): Illuminate\\Database\\Migrations\\Migrator->runMigration()\n#12 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Console/View/Components/Task.php(43): Illuminate\\Database\\Migrations\\Migrator->Illuminate\\Database\\Migrations\\{closure}()\n#13 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(814): Illuminate\\Console\\View\\Components\\Task->render()\n#14 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(253): Illuminate\\Database\\Migrations\\Migrator->write()\n#15 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(211): Illuminate\\Database\\Migrations\\Migrator->runUp()\n#16 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(138): Illuminate\\Database\\Migrations\\Migrator->runPending()\n#17 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Console/Migrations/MigrateCommand.php(118): Illuminate\\Database\\Migrations\\Migrator->run()\n#18 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(671): Illuminate\\Database\\Console\\Migrations\\MigrateCommand->Illuminate\\Database\\Console\\Migrations\\{closure}()\n#19 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Console/Migrations/MigrateCommand.php(111): Illuminate\\Database\\Migrations\\Migrator->usingConnection()\n#20 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Console/Migrations/MigrateCommand.php(90): Illuminate\\Database\\Console\\Migrations\\MigrateCommand->runMigrations()\n#21 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Container/BoundMethod.php(36): Illuminate\\Database\\Console\\Migrations\\MigrateCommand->handle()\n#22 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Container/Util.php(43): Illuminate\\Container\\BoundMethod::Illuminate\\Container\\{closure}()\n#23 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Container/BoundMethod.php(96): Illuminate\\Container\\Util::unwrapIfClosure()\n#24 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Container/BoundMethod.php(35): Illuminate\\Container\\BoundMethod::callBoundMethod()\n#25 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Container/Container.php(799): Illuminate\\Container\\BoundMethod::call()\n#26 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Console/Command.php(280): Illuminate\\Container\\Container->call()\n#27 /u01/nix-life-os/backend/vendor/symfony/console/Command/Command.php(341): Illuminate\\Console\\Command->execute()\n#28 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Console/Command.php(249): Symfony\\Component\\Console\\Command\\Command->run()\n#29 /u01/nix-life-os/backend/vendor/symfony/console/Application.php(1117): Illuminate\\Console\\Command->run()\n#30 /u01/nix-life-os/backend/vendor/symfony/console/Application.php(356): Symfony\\Component\\Console\\Application->doRunCommand()\n#31 /u01/nix-life-os/backend/vendor/symfony/console/Application.php(195): Symfony\\Component\\Console\\Application->doRun()\n#32 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Foundation/Console/Kernel.php(198): Symfony\\Component\\Console\\Application->run()\n#33 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Foundation/Application.php(1235): Illuminate\\Foundation\\Console\\Kernel->handle()\n#34 /u01/nix-life-os/backend/artisan(16): Illuminate\\Foundation\\Application->handleCommand()\n#35 {main}	\N	127.0.0.1	Symfony	2026-05-02 04:19:42
019de657-7c28-7322-991d-ac6bb2a33b8e	\N	error	global_exception_handler	Illuminate\\Database\\QueryException	SQLSTATE[42804]: Datatype mismatch: 7 ERROR:  foreign key constraint "subscriptions_user_id_foreign" cannot be implemented\nDETAIL:  Key columns "user_id" of the referencing table and "id" of the referenced table are of incompatible types: bigint and uuid. (Connection: pgsql, Host: 127.0.0.1, Port: 5445, Database: nixlifeos_db, SQL: alter table "subscriptions" add constraint "subscriptions_user_id_foreign" foreign key ("user_id") references "users" ("id") on delete cascade)	/u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Connection.php	841	GET	http://localhost	[]	#0 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Connection.php(797): Illuminate\\Database\\Connection->runQueryCallback()\n#1 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Connection.php(576): Illuminate\\Database\\Connection->run()\n#2 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Schema/Blueprint.php(121): Illuminate\\Database\\Connection->statement()\n#3 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Schema/Builder.php(690): Illuminate\\Database\\Schema\\Blueprint->build()\n#4 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Schema/Builder.php(508): Illuminate\\Database\\Schema\\Builder->build()\n#5 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Support/Facades/Facade.php(363): Illuminate\\Database\\Schema\\Builder->create()\n#6 /u01/nix-life-os/backend/database/migrations/2026_05_01_221333_create_subscriptions_table.php(11): Illuminate\\Support\\Facades\\Facade::__callStatic()\n#7 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(517): Illuminate\\Database\\Migrations\\Migration@anonymous->up()\n#8 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(442): Illuminate\\Database\\Migrations\\Migrator->runMethod()\n#9 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Concerns/ManagesTransactions.php(35): Illuminate\\Database\\Migrations\\Migrator->Illuminate\\Database\\Migrations\\{closure}()\n#10 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(450): Illuminate\\Database\\Connection->transaction()\n#11 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(253): Illuminate\\Database\\Migrations\\Migrator->runMigration()\n#12 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Console/View/Components/Task.php(43): Illuminate\\Database\\Migrations\\Migrator->Illuminate\\Database\\Migrations\\{closure}()\n#13 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(814): Illuminate\\Console\\View\\Components\\Task->render()\n#14 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(253): Illuminate\\Database\\Migrations\\Migrator->write()\n#15 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(211): Illuminate\\Database\\Migrations\\Migrator->runUp()\n#16 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(138): Illuminate\\Database\\Migrations\\Migrator->runPending()\n#17 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Console/Migrations/MigrateCommand.php(118): Illuminate\\Database\\Migrations\\Migrator->run()\n#18 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Migrations/Migrator.php(671): Illuminate\\Database\\Console\\Migrations\\MigrateCommand->Illuminate\\Database\\Console\\Migrations\\{closure}()\n#19 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Console/Migrations/MigrateCommand.php(111): Illuminate\\Database\\Migrations\\Migrator->usingConnection()\n#20 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Database/Console/Migrations/MigrateCommand.php(90): Illuminate\\Database\\Console\\Migrations\\MigrateCommand->runMigrations()\n#21 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Container/BoundMethod.php(36): Illuminate\\Database\\Console\\Migrations\\MigrateCommand->handle()\n#22 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Container/Util.php(43): Illuminate\\Container\\BoundMethod::Illuminate\\Container\\{closure}()\n#23 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Container/BoundMethod.php(96): Illuminate\\Container\\Util::unwrapIfClosure()\n#24 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Container/BoundMethod.php(35): Illuminate\\Container\\BoundMethod::callBoundMethod()\n#25 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Container/Container.php(799): Illuminate\\Container\\BoundMethod::call()\n#26 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Console/Command.php(280): Illuminate\\Container\\Container->call()\n#27 /u01/nix-life-os/backend/vendor/symfony/console/Command/Command.php(341): Illuminate\\Console\\Command->execute()\n#28 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Console/Command.php(249): Symfony\\Component\\Console\\Command\\Command->run()\n#29 /u01/nix-life-os/backend/vendor/symfony/console/Application.php(1117): Illuminate\\Console\\Command->run()\n#30 /u01/nix-life-os/backend/vendor/symfony/console/Application.php(356): Symfony\\Component\\Console\\Application->doRunCommand()\n#31 /u01/nix-life-os/backend/vendor/symfony/console/Application.php(195): Symfony\\Component\\Console\\Application->doRun()\n#32 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Foundation/Console/Kernel.php(198): Symfony\\Component\\Console\\Application->run()\n#33 /u01/nix-life-os/backend/vendor/laravel/framework/src/Illuminate/Foundation/Application.php(1235): Illuminate\\Foundation\\Console\\Kernel->handle()\n#34 /u01/nix-life-os/backend/artisan(16): Illuminate\\Foundation\\Application->handleCommand()\n#35 {main}	\N	127.0.0.1	Symfony	2026-05-02 04:39:46
\.


--
-- Data for Name: expenses; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.expenses (id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.failed_jobs (id, uuid, connection, queue, payload, exception, failed_at) FROM stdin;
\.


--
-- Data for Name: health_food_items; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.health_food_items (id, user_id, food_name, brand_name, category, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, sodium_per_100g_mg, potassium_per_100g_mg, phosphorus_per_100g_mg, is_ckd_friendly, is_custom, is_active, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: health_hydration_logs; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.health_hydration_logs (id, user_id, log_date, log_time, drink_type, amount_ml, is_ckd_safe, source, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: health_meal_log_items; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.health_meal_log_items (id, meal_log_id, food_item_id, quantity_g, calories, protein_g, carbs_g, fat_g, sodium_mg, potassium_mg, phosphorus_mg, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: health_meal_logs; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.health_meal_logs (id, user_id, meal_date, meal_type, meal_name, notes, total_calories, total_protein_g, total_carbs_g, total_fat_g, total_sodium_mg, total_potassium_mg, total_phosphorus_mg, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: health_nutrition_profiles; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.health_nutrition_profiles (id, user_id, profile_name, daily_calories_min, daily_calories_max, daily_protein_max_g, daily_carbs_max_g, daily_fat_max_g, daily_sodium_max_mg, daily_potassium_max_mg, daily_phosphorus_max_mg, is_ckd_safe_mode, is_active, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: health_profile; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.health_profile (id, user_id, daily_steps_goal, stride_length_cm, distance_unit, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: health_step_log; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.health_step_log (id, user_id, log_date, steps_count, distance_km, goal_steps, goal_percentage, goal_completed, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: health_weight_logs; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.health_weight_logs (id, user_id, log_date, weight_kg, body_fat_percentage, muscle_mass_kg, bmi, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: incomes; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.incomes (id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: job_batches; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.job_batches (id, name, total_jobs, pending_jobs, failed_jobs, failed_job_ids, options, cancelled_at, created_at, finished_at) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.jobs (id, queue, payload, attempts, reserved_at, available_at, created_at) FROM stdin;
\.


--
-- Data for Name: life_balance_scores; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.life_balance_scores (id, user_id, target_date, finance_score, health_score, productivity_score, overall_score, status, finance_breakdown, health_breakdown, productivity_breakdown, recommendations, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: life_notifications; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.life_notifications (id, user_id, notification_type, title, message, severity, source_module, metadata, is_read, read_at, scheduled_for, triggered_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.migrations (id, migration, batch) FROM stdin;
1	0001_01_01_000001_create_cache_table	1
2	0001_01_01_000002_create_jobs_table	1
3	2026_04_11_031332_create_personal_access_tokens_table	1
4	2026_04_11_031411_create_permission_tables	1
5	2026_04_11_034133_create_expenses_table	1
6	2026_04_11_034134_create_calorie_entries_table	1
7	2026_04_11_034134_create_incomes_table	1
8	2026_04_11_034134_create_step_entries_table	1
9	2026_04_11_034134_create_tasks_table	1
10	2026_04_11_034134_create_weight_entries_table	1
11	2026_04_11_043658_create_users_table	1
12	2026_04_24_081534_create_health_profiles_table	1
13	2026_04_24_081534_create_health_step_logs_table	1
14	2026_04_26_011352_create_health_weight_logs_table	1
15	2026_04_26_015704_create_health_meal_logs_table	1
16	2026_04_26_015705_create_health_food_items_table	1
17	2026_04_26_015705_create_health_meal_log_items_table	1
18	2026_04_26_015705_create_health_nutrition_profiles_table	1
19	2026_04_26_040332_create_health_hydration_logs_table	1
20	2026_04_26_051913_create_projects_table	1
21	2026_04_26_051914_create_project_tasks_table	1
22	2026_04_26_055602_create_project_milestones_table	1
23	2026_04_26_055602_create_project_status_updates_table	1
24	2026_04_26_055613_add_progress_fields_to_project_tasks_table	1
25	2026_04_26_163456_add_dashboard_indexes	1
26	2026_04_27_171355_create_ai_alerts_table	1
27	2026_04_27_171355_create_ai_insights_table	1
28	2026_04_27_171356_create_ai_reports_table	1
29	2026_04_27_181016_create_ai_predictions_table	1
30	2026_04_27_184016_create_life_balance_scores_table	1
31	2026_04_27_195829_create_life_notifications_table	1
32	2026_04_27_195909_create_notification_preferences_table	1
33	2026_04_27_202348_create_automation_rules_table	1
34	2026_04_27_202348_create_automation_trigger_logs_table	1
35	2026_04_29_194522_add_performance_indexes_to_nix_life_os_tables	1
36	2026_04_29_212852_create_audit_logs_table	1
37	2026_04_29_212852_create_error_logs_table	1
38	2026_04_29_212852_create_system_monitoring_logs_table	1
39	2026_05_01_220245_create_plans_table	2
40	2026_05_01_221333_create_subscriptions_table	3
41	2026_05_01_221425_create_subscription_usage_table	3
\.


--
-- Data for Name: model_has_permissions; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.model_has_permissions (permission_id, model_type, model_id) FROM stdin;
\.


--
-- Data for Name: model_has_roles; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.model_has_roles (role_id, model_type, model_id) FROM stdin;
\.


--
-- Data for Name: notification_preferences; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.notification_preferences (id, user_id, meal_reminders_enabled, breakfast_time, lunch_time, dinner_time, weight_reminders_enabled, weight_reminder_time, expense_reminders_enabled, expense_reminder_time, finance_alerts_enabled, health_alerts_enabled, life_balance_alerts_enabled, daily_expense_warning_limit, life_balance_warning_score, metadata, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.permissions (id, name, guard_name, created_at, updated_at) FROM stdin;
1	dashboard.view	web	2026-05-01 14:46:44	2026-05-01 14:46:44
2	finance.view	web	2026-05-01 14:46:44	2026-05-01 14:46:44
3	finance.create	web	2026-05-01 14:46:44	2026-05-01 14:46:44
4	finance.update	web	2026-05-01 14:46:44	2026-05-01 14:46:44
5	finance.delete	web	2026-05-01 14:46:44	2026-05-01 14:46:44
6	health.view	web	2026-05-01 14:46:44	2026-05-01 14:46:44
7	health.create	web	2026-05-01 14:46:44	2026-05-01 14:46:44
8	health.update	web	2026-05-01 14:46:44	2026-05-01 14:46:44
9	health.delete	web	2026-05-01 14:46:44	2026-05-01 14:46:44
10	projects.view	web	2026-05-01 14:46:44	2026-05-01 14:46:44
11	projects.create	web	2026-05-01 14:46:44	2026-05-01 14:46:44
12	projects.update	web	2026-05-01 14:46:44	2026-05-01 14:46:44
13	projects.delete	web	2026-05-01 14:46:44	2026-05-01 14:46:44
14	ai.view	web	2026-05-01 14:46:44	2026-05-01 14:46:44
15	ai.generate	web	2026-05-01 14:46:44	2026-05-01 14:46:44
16	notifications.view	web	2026-05-01 14:46:44	2026-05-01 14:46:44
17	notifications.manage	web	2026-05-01 14:46:44	2026-05-01 14:46:44
18	automation.view	web	2026-05-01 14:46:44	2026-05-01 14:46:44
19	automation.create	web	2026-05-01 14:46:44	2026-05-01 14:46:44
20	automation.update	web	2026-05-01 14:46:44	2026-05-01 14:46:44
21	automation.delete	web	2026-05-01 14:46:44	2026-05-01 14:46:44
22	security.view	web	2026-05-01 14:46:44	2026-05-01 14:46:44
23	security.manage	web	2026-05-01 14:46:44	2026-05-01 14:46:44
24	users.view	web	2026-05-01 14:46:44	2026-05-01 14:46:44
25	users.manage	web	2026-05-01 14:46:44	2026-05-01 14:46:44
26	roles.manage	web	2026-05-01 14:46:44	2026-05-01 14:46:44
\.


--
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, expires_at, created_at, updated_at) FROM stdin;
1	App\\Models\\User	019de69f-930e-7235-93be-3049764d3648	local-dev-token	39a6b15a16c1543eee73760ffa09c988c92858159062ca2841de772cb3d2b563	["*"]	2026-05-02 03:19:06	\N	2026-05-02 02:58:30	2026-05-02 03:19:06
\.


--
-- Data for Name: plans; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.plans (id, code, name, monthly_price, yearly_price, max_finance_accounts, max_projects, max_ai_insights_per_month, max_notifications_per_month, finance_module_enabled, health_module_enabled, projects_module_enabled, ai_module_enabled, automation_module_enabled, monitoring_module_enabled, features, is_active, created_at, updated_at) FROM stdin;
3146b154-a232-449c-aa61-83387733c691	free	Free	0.00	0.00	2	2	5	20	t	t	t	f	f	f	["Basic finance tracking", "Basic health tracking", "Basic project tracking"]	t	2026-05-02 01:19:42	2026-05-02 01:19:42
7211e672-9b91-4996-975c-3834c177fb96	pro	Pro	9.99	99.99	20	50	300	1000	t	t	t	t	t	t	["Advanced finance analytics", "AI insights", "Automation engine", "Monitoring dashboard", "Unlimited dashboards"]	t	2026-05-02 01:19:42	2026-05-02 01:19:42
ee6ee2a7-8ee9-457b-a7a9-9b174c545128	enterprise	Enterprise	49.99	499.99	999999	999999	999999	999999	t	t	t	t	t	t	["Enterprise usage", "Team support ready", "Advanced monitoring", "Priority support", "Custom integrations"]	t	2026-05-02 01:19:42	2026-05-02 01:19:42
\.


--
-- Data for Name: project_milestones; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.project_milestones (id, project_id, milestone_name, description, target_date, completed_date, status, progress_percentage, weight, metadata, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: project_status_updates; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.project_status_updates (id, project_id, task_id, milestone_id, update_title, update_description, old_status, new_status, old_progress_percentage, new_progress_percentage, update_type, metadata, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: project_tasks; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.project_tasks (id, project_id, user_id, task_title, task_description, status, priority, task_order, start_date, due_date, completed_date, progress_percentage, metadata, created_at, updated_at, weight, completed_at) FROM stdin;
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.projects (id, user_id, project_name, project_code, description, status, priority, start_date, target_end_date, actual_end_date, progress_percentage, metadata, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: role_has_permissions; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.role_has_permissions (permission_id, role_id) FROM stdin;
1	1
2	1
3	1
4	1
5	1
6	1
7	1
8	1
9	1
10	1
11	1
12	1
13	1
14	1
15	1
16	1
17	1
18	1
19	1
20	1
21	1
22	1
23	1
24	1
25	1
26	1
1	2
2	2
3	2
4	2
6	2
7	2
8	2
10	2
11	2
12	2
14	2
15	2
16	2
18	2
19	2
20	2
1	3
2	3
6	3
10	3
14	3
16	3
18	3
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.roles (id, name, guard_name, created_at, updated_at) FROM stdin;
1	admin	web	2026-05-01 14:46:44	2026-05-01 14:46:44
2	user	web	2026-05-01 14:46:44	2026-05-01 14:46:44
3	viewer	web	2026-05-01 14:46:44	2026-05-01 14:46:44
\.


--
-- Data for Name: step_entries; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.step_entries (id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: subscription_usage; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.subscription_usage (id, user_id, subscription_id, finance_accounts_count, projects_count, ai_insights_used, notifications_sent, period_start, period_end, created_at, updated_at) FROM stdin;
223d3085-cfb6-4256-81d5-1905e73a7f5f	019de69f-930e-7235-93be-3049764d3648	e4f6d5f6-c39d-4f9b-9082-5eb5f884c33c	0	0	0	0	2026-05-01	2026-05-31	2026-05-02 02:58:30	2026-05-02 02:58:30
\.


--
-- Data for Name: subscriptions; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.subscriptions (id, user_id, plan_id, status, billing_cycle, started_at, trial_ends_at, current_period_starts_at, current_period_ends_at, cancelled_at, payment_provider, payment_customer_id, payment_subscription_id, metadata, created_at, updated_at) FROM stdin;
e4f6d5f6-c39d-4f9b-9082-5eb5f884c33c	019de69f-930e-7235-93be-3049764d3648	3146b154-a232-449c-aa61-83387733c691	active	monthly	2026-05-02 02:58:30	\N	2026-05-01 00:00:00	2026-05-31 23:59:59	\N	\N	\N	\N	{"source": "manual_or_default_registration"}	2026-05-02 02:58:30	2026-05-02 02:58:30
\.


--
-- Data for Name: system_monitoring_logs; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.system_monitoring_logs (id, service_name, status, response_time_ms, metrics, message, checked_at) FROM stdin;
019de64e-9354-70c6-8584-1d01eda673c7	scheduled-health-check	healthy	21	{"database": "healthy", "memory_peak_mb": 26, "memory_usage_mb": 26}	System health check completed successfully	2026-05-02 04:30:02
019de65c-5186-7254-bb87-5b2e100f92d3	scheduled-health-check	healthy	18	{"database": "healthy", "memory_peak_mb": 26, "memory_usage_mb": 26}	System health check completed successfully	2026-05-02 04:45:03
019de66a-0c21-7370-b631-9784b8ced3fc	scheduled-health-check	healthy	18	{"database": "healthy", "memory_peak_mb": 26, "memory_usage_mb": 26}	System health check completed successfully	2026-05-02 05:00:03
019de677-c684-730a-beca-a767d4aac66f	scheduled-health-check	healthy	18	{"database": "healthy", "memory_peak_mb": 26, "memory_usage_mb": 26}	System health check completed successfully	2026-05-02 05:15:03
019de685-8193-7048-ad55-54cc2a05c5cf	scheduled-health-check	healthy	17	{"database": "healthy", "memory_peak_mb": 26, "memory_usage_mb": 26}	System health check completed successfully	2026-05-02 05:30:02
019de693-3c10-712d-bfbc-efe81a770554	scheduled-health-check	healthy	17	{"database": "healthy", "memory_peak_mb": 26, "memory_usage_mb": 26}	System health check completed successfully	2026-05-02 05:45:02
019de6a0-fa8f-73aa-af2b-f52e8786c221	scheduled-health-check	healthy	20	{"database": "healthy", "memory_peak_mb": 26, "memory_usage_mb": 26}	System health check completed successfully	2026-05-02 06:00:03
019de6ae-b433-72a8-a082-75cf52ff52a4	scheduled-health-check	healthy	20	{"database": "healthy", "memory_peak_mb": 26, "memory_usage_mb": 26}	System health check completed successfully	2026-05-02 06:15:02
019de6bc-70a6-7378-9d67-817505af6074	scheduled-health-check	healthy	18	{"database": "healthy", "memory_peak_mb": 26, "memory_usage_mb": 26}	System health check completed successfully	2026-05-02 06:30:03
\.


--
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.tasks (id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.users (id, name, email, email_verified_at, password, role, is_active, last_login_at, remember_token, created_at, updated_at) FROM stdin;
019de69f-930e-7235-93be-3049764d3648	Nix	nix@example.com	\N	$2y$12$2/pJ8eXOX4eNeckdhjStveibZ02BV3Oy9iKRqsvRuqZ3R5oZ4T8a6	user	t	\N	\N	2026-05-02 02:58:30	2026-05-02 02:58:30
\.


--
-- Data for Name: weight_entries; Type: TABLE DATA; Schema: public; Owner: nixlifeos_user
--

COPY public.weight_entries (id, created_at, updated_at) FROM stdin;
\.


--
-- Name: calorie_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.calorie_entries_id_seq', 1, false);


--
-- Name: expenses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.expenses_id_seq', 1, false);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- Name: health_weight_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.health_weight_logs_id_seq', 1, false);


--
-- Name: incomes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.incomes_id_seq', 1, false);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.jobs_id_seq', 1, false);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.migrations_id_seq', 41, true);


--
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.permissions_id_seq', 26, true);


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.personal_access_tokens_id_seq', 1, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.roles_id_seq', 3, true);


--
-- Name: step_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.step_entries_id_seq', 1, false);


--
-- Name: tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.tasks_id_seq', 1, false);


--
-- Name: weight_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nixlifeos_user
--

SELECT pg_catalog.setval('public.weight_entries_id_seq', 1, false);


--
-- Name: ai_alerts ai_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.ai_alerts
    ADD CONSTRAINT ai_alerts_pkey PRIMARY KEY (id);


--
-- Name: ai_insights ai_insights_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.ai_insights
    ADD CONSTRAINT ai_insights_pkey PRIMARY KEY (id);


--
-- Name: ai_predictions ai_predictions_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.ai_predictions
    ADD CONSTRAINT ai_predictions_pkey PRIMARY KEY (id);


--
-- Name: ai_reports ai_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.ai_reports
    ADD CONSTRAINT ai_reports_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: automation_rules automation_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.automation_rules
    ADD CONSTRAINT automation_rules_pkey PRIMARY KEY (id);


--
-- Name: automation_trigger_logs automation_trigger_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.automation_trigger_logs
    ADD CONSTRAINT automation_trigger_logs_pkey PRIMARY KEY (id);


--
-- Name: cache_locks cache_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- Name: cache cache_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- Name: calorie_entries calorie_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.calorie_entries
    ADD CONSTRAINT calorie_entries_pkey PRIMARY KEY (id);


--
-- Name: error_logs error_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.error_logs
    ADD CONSTRAINT error_logs_pkey PRIMARY KEY (id);


--
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- Name: health_food_items health_food_items_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_food_items
    ADD CONSTRAINT health_food_items_pkey PRIMARY KEY (id);


--
-- Name: health_hydration_logs health_hydration_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_hydration_logs
    ADD CONSTRAINT health_hydration_logs_pkey PRIMARY KEY (id);


--
-- Name: health_meal_log_items health_meal_log_items_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_meal_log_items
    ADD CONSTRAINT health_meal_log_items_pkey PRIMARY KEY (id);


--
-- Name: health_meal_logs health_meal_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_meal_logs
    ADD CONSTRAINT health_meal_logs_pkey PRIMARY KEY (id);


--
-- Name: health_nutrition_profiles health_nutrition_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_nutrition_profiles
    ADD CONSTRAINT health_nutrition_profiles_pkey PRIMARY KEY (id);


--
-- Name: health_nutrition_profiles health_nutrition_profiles_user_id_is_active_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_nutrition_profiles
    ADD CONSTRAINT health_nutrition_profiles_user_id_is_active_unique UNIQUE (user_id, is_active);


--
-- Name: health_profile health_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_profile
    ADD CONSTRAINT health_profile_pkey PRIMARY KEY (id);


--
-- Name: health_profile health_profile_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_profile
    ADD CONSTRAINT health_profile_user_id_unique UNIQUE (user_id);


--
-- Name: health_step_log health_step_log_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_step_log
    ADD CONSTRAINT health_step_log_pkey PRIMARY KEY (id);


--
-- Name: health_step_log health_step_log_user_id_log_date_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_step_log
    ADD CONSTRAINT health_step_log_user_id_log_date_unique UNIQUE (user_id, log_date);


--
-- Name: health_weight_logs health_weight_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_weight_logs
    ADD CONSTRAINT health_weight_logs_pkey PRIMARY KEY (id);


--
-- Name: health_weight_logs health_weight_logs_user_id_log_date_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_weight_logs
    ADD CONSTRAINT health_weight_logs_user_id_log_date_unique UNIQUE (user_id, log_date);


--
-- Name: incomes incomes_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.incomes
    ADD CONSTRAINT incomes_pkey PRIMARY KEY (id);


--
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: life_balance_scores life_balance_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.life_balance_scores
    ADD CONSTRAINT life_balance_scores_pkey PRIMARY KEY (id);


--
-- Name: life_balance_scores life_balance_scores_user_id_target_date_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.life_balance_scores
    ADD CONSTRAINT life_balance_scores_user_id_target_date_unique UNIQUE (user_id, target_date);


--
-- Name: life_notifications life_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.life_notifications
    ADD CONSTRAINT life_notifications_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: model_has_permissions model_has_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.model_has_permissions
    ADD CONSTRAINT model_has_permissions_pkey PRIMARY KEY (permission_id, model_id, model_type);


--
-- Name: model_has_roles model_has_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.model_has_roles
    ADD CONSTRAINT model_has_roles_pkey PRIMARY KEY (role_id, model_id, model_type);


--
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences notification_preferences_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_user_id_unique UNIQUE (user_id);


--
-- Name: permissions permissions_name_guard_name_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_name_guard_name_unique UNIQUE (name, guard_name);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- Name: plans plans_code_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_code_unique UNIQUE (code);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: project_milestones project_milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.project_milestones
    ADD CONSTRAINT project_milestones_pkey PRIMARY KEY (id);


--
-- Name: project_status_updates project_status_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.project_status_updates
    ADD CONSTRAINT project_status_updates_pkey PRIMARY KEY (id);


--
-- Name: project_tasks project_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.project_tasks
    ADD CONSTRAINT project_tasks_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: role_has_permissions role_has_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.role_has_permissions
    ADD CONSTRAINT role_has_permissions_pkey PRIMARY KEY (permission_id, role_id);


--
-- Name: roles roles_name_guard_name_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_guard_name_unique UNIQUE (name, guard_name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: step_entries step_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.step_entries
    ADD CONSTRAINT step_entries_pkey PRIMARY KEY (id);


--
-- Name: subscription_usage subscription_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.subscription_usage
    ADD CONSTRAINT subscription_usage_pkey PRIMARY KEY (id);


--
-- Name: subscription_usage subscription_usage_user_id_subscription_id_period_start_period_; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.subscription_usage
    ADD CONSTRAINT subscription_usage_user_id_subscription_id_period_start_period_ UNIQUE (user_id, subscription_id, period_start, period_end);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_user_id_status_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_user_id_status_unique UNIQUE (user_id, status);


--
-- Name: system_monitoring_logs system_monitoring_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.system_monitoring_logs
    ADD CONSTRAINT system_monitoring_logs_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: weight_entries weight_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.weight_entries
    ADD CONSTRAINT weight_entries_pkey PRIMARY KEY (id);


--
-- Name: ai_alerts_alert_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_alerts_alert_date_index ON public.ai_alerts USING btree (alert_date);


--
-- Name: ai_alerts_alert_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_alerts_alert_type_index ON public.ai_alerts USING btree (alert_type);


--
-- Name: ai_alerts_module_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_alerts_module_index ON public.ai_alerts USING btree (module);


--
-- Name: ai_alerts_severity_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_alerts_severity_index ON public.ai_alerts USING btree (severity);


--
-- Name: ai_alerts_user_id_alert_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_alerts_user_id_alert_date_index ON public.ai_alerts USING btree (user_id, alert_date);


--
-- Name: ai_alerts_user_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_alerts_user_id_index ON public.ai_alerts USING btree (user_id);


--
-- Name: ai_alerts_user_id_is_resolved_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_alerts_user_id_is_resolved_index ON public.ai_alerts USING btree (user_id, is_resolved);


--
-- Name: ai_insights_category_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_insights_category_index ON public.ai_insights USING btree (category);


--
-- Name: ai_insights_insight_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_insights_insight_date_index ON public.ai_insights USING btree (insight_date);


--
-- Name: ai_insights_insight_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_insights_insight_type_index ON public.ai_insights USING btree (insight_type);


--
-- Name: ai_insights_severity_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_insights_severity_index ON public.ai_insights USING btree (severity);


--
-- Name: ai_insights_user_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_insights_user_id_index ON public.ai_insights USING btree (user_id);


--
-- Name: ai_insights_user_id_insight_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_insights_user_id_insight_date_index ON public.ai_insights USING btree (user_id, insight_date);


--
-- Name: ai_insights_user_id_severity_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_insights_user_id_severity_index ON public.ai_insights USING btree (user_id, severity);


--
-- Name: ai_predictions_prediction_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_predictions_prediction_date_index ON public.ai_predictions USING btree (prediction_date);


--
-- Name: ai_predictions_target_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_predictions_target_date_index ON public.ai_predictions USING btree (target_date);


--
-- Name: ai_predictions_user_id_prediction_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_predictions_user_id_prediction_type_index ON public.ai_predictions USING btree (user_id, prediction_type);


--
-- Name: ai_reports_period_end_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_reports_period_end_index ON public.ai_reports USING btree (period_end);


--
-- Name: ai_reports_period_start_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_reports_period_start_index ON public.ai_reports USING btree (period_start);


--
-- Name: ai_reports_report_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_reports_report_type_index ON public.ai_reports USING btree (report_type);


--
-- Name: ai_reports_user_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_reports_user_id_index ON public.ai_reports USING btree (user_id);


--
-- Name: ai_reports_user_id_period_start_period_end_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_reports_user_id_period_start_period_end_index ON public.ai_reports USING btree (user_id, period_start, period_end);


--
-- Name: ai_reports_user_id_report_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX ai_reports_user_id_report_type_index ON public.ai_reports USING btree (user_id, report_type);


--
-- Name: audit_logs_action_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX audit_logs_action_index ON public.audit_logs USING btree (action);


--
-- Name: audit_logs_created_at_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX audit_logs_created_at_index ON public.audit_logs USING btree (created_at);


--
-- Name: audit_logs_entity_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX audit_logs_entity_type_index ON public.audit_logs USING btree (entity_type);


--
-- Name: audit_logs_module_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX audit_logs_module_index ON public.audit_logs USING btree (module);


--
-- Name: audit_logs_user_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX audit_logs_user_id_index ON public.audit_logs USING btree (user_id);


--
-- Name: automation_rules_user_id_is_active_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX automation_rules_user_id_is_active_index ON public.automation_rules USING btree (user_id, is_active);


--
-- Name: automation_rules_user_id_module_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX automation_rules_user_id_module_index ON public.automation_rules USING btree (user_id, module);


--
-- Name: automation_rules_user_id_trigger_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX automation_rules_user_id_trigger_type_index ON public.automation_rules USING btree (user_id, trigger_type);


--
-- Name: automation_trigger_logs_automation_rule_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX automation_trigger_logs_automation_rule_id_index ON public.automation_trigger_logs USING btree (automation_rule_id);


--
-- Name: automation_trigger_logs_status_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX automation_trigger_logs_status_index ON public.automation_trigger_logs USING btree (status);


--
-- Name: automation_trigger_logs_user_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX automation_trigger_logs_user_id_index ON public.automation_trigger_logs USING btree (user_id);


--
-- Name: cache_expiration_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX cache_expiration_index ON public.cache USING btree (expiration);


--
-- Name: cache_locks_expiration_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX cache_locks_expiration_index ON public.cache_locks USING btree (expiration);


--
-- Name: error_logs_created_at_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX error_logs_created_at_index ON public.error_logs USING btree (created_at);


--
-- Name: error_logs_exception_class_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX error_logs_exception_class_index ON public.error_logs USING btree (exception_class);


--
-- Name: error_logs_level_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX error_logs_level_index ON public.error_logs USING btree (level);


--
-- Name: error_logs_module_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX error_logs_module_index ON public.error_logs USING btree (module);


--
-- Name: error_logs_user_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX error_logs_user_id_index ON public.error_logs USING btree (user_id);


--
-- Name: health_food_items_category_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_food_items_category_index ON public.health_food_items USING btree (category);


--
-- Name: health_food_items_food_name_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_food_items_food_name_index ON public.health_food_items USING btree (food_name);


--
-- Name: health_food_items_is_ckd_friendly_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_food_items_is_ckd_friendly_index ON public.health_food_items USING btree (is_ckd_friendly);


--
-- Name: health_food_items_user_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_food_items_user_id_index ON public.health_food_items USING btree (user_id);


--
-- Name: health_hydration_logs_user_id_drink_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_hydration_logs_user_id_drink_type_index ON public.health_hydration_logs USING btree (user_id, drink_type);


--
-- Name: health_hydration_logs_user_id_log_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_hydration_logs_user_id_log_date_index ON public.health_hydration_logs USING btree (user_id, log_date);


--
-- Name: health_meal_log_items_food_item_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_meal_log_items_food_item_id_index ON public.health_meal_log_items USING btree (food_item_id);


--
-- Name: health_meal_log_items_meal_log_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_meal_log_items_meal_log_id_index ON public.health_meal_log_items USING btree (meal_log_id);


--
-- Name: health_meal_logs_meal_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_meal_logs_meal_type_index ON public.health_meal_logs USING btree (meal_type);


--
-- Name: health_meal_logs_user_id_meal_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_meal_logs_user_id_meal_date_index ON public.health_meal_logs USING btree (user_id, meal_date);


--
-- Name: health_nutrition_profiles_user_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_nutrition_profiles_user_id_index ON public.health_nutrition_profiles USING btree (user_id);


--
-- Name: health_step_log_user_id_log_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_step_log_user_id_log_date_index ON public.health_step_log USING btree (user_id, log_date);


--
-- Name: health_weight_logs_user_id_log_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_weight_logs_user_id_log_date_index ON public.health_weight_logs USING btree (user_id, log_date);


--
-- Name: health_weight_logs_user_id_weight_kg_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX health_weight_logs_user_id_weight_kg_index ON public.health_weight_logs USING btree (user_id, weight_kg);


--
-- Name: idx_automation_rules_user_active; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_automation_rules_user_active ON public.automation_rules USING btree (user_id, is_active);


--
-- Name: idx_health_hydration_logs_log_date; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_health_hydration_logs_log_date ON public.health_hydration_logs USING btree (log_date);


--
-- Name: idx_health_hydration_logs_user_date; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_health_hydration_logs_user_date ON public.health_hydration_logs USING btree (user_id, log_date);


--
-- Name: idx_health_hydration_logs_user_id; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_health_hydration_logs_user_id ON public.health_hydration_logs USING btree (user_id);


--
-- Name: idx_health_meal_logs_meal_date; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_health_meal_logs_meal_date ON public.health_meal_logs USING btree (meal_date);


--
-- Name: idx_health_meal_logs_user_date; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_health_meal_logs_user_date ON public.health_meal_logs USING btree (user_id, meal_date);


--
-- Name: idx_health_meal_logs_user_id; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_health_meal_logs_user_id ON public.health_meal_logs USING btree (user_id);


--
-- Name: idx_health_weight_logs_log_date; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_health_weight_logs_log_date ON public.health_weight_logs USING btree (log_date);


--
-- Name: idx_health_weight_logs_user_date; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_health_weight_logs_user_date ON public.health_weight_logs USING btree (user_id, log_date);


--
-- Name: idx_health_weight_logs_user_id; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_health_weight_logs_user_id ON public.health_weight_logs USING btree (user_id);


--
-- Name: idx_project_tasks_due_date; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_project_tasks_due_date ON public.project_tasks USING btree (due_date);


--
-- Name: idx_project_tasks_priority; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_project_tasks_priority ON public.project_tasks USING btree (priority);


--
-- Name: idx_project_tasks_project_id; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_project_tasks_project_id ON public.project_tasks USING btree (project_id);


--
-- Name: idx_project_tasks_project_status; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_project_tasks_project_status ON public.project_tasks USING btree (project_id, status);


--
-- Name: idx_project_tasks_status; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_project_tasks_status ON public.project_tasks USING btree (status);


--
-- Name: idx_project_tasks_user_status; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_project_tasks_user_status ON public.project_tasks USING btree (user_id, status);


--
-- Name: idx_projects_priority; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_projects_priority ON public.projects USING btree (priority);


--
-- Name: idx_projects_status; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_projects_status ON public.projects USING btree (status);


--
-- Name: idx_projects_user_id; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_projects_user_id ON public.projects USING btree (user_id);


--
-- Name: idx_projects_user_status; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX idx_projects_user_status ON public.projects USING btree (user_id, status);


--
-- Name: jobs_queue_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX jobs_queue_index ON public.jobs USING btree (queue);


--
-- Name: life_balance_scores_status_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX life_balance_scores_status_index ON public.life_balance_scores USING btree (status);


--
-- Name: life_balance_scores_user_id_overall_score_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX life_balance_scores_user_id_overall_score_index ON public.life_balance_scores USING btree (user_id, overall_score);


--
-- Name: life_balance_scores_user_id_target_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX life_balance_scores_user_id_target_date_index ON public.life_balance_scores USING btree (user_id, target_date);


--
-- Name: life_notifications_is_read_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX life_notifications_is_read_index ON public.life_notifications USING btree (is_read);


--
-- Name: life_notifications_notification_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX life_notifications_notification_type_index ON public.life_notifications USING btree (notification_type);


--
-- Name: life_notifications_scheduled_for_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX life_notifications_scheduled_for_index ON public.life_notifications USING btree (scheduled_for);


--
-- Name: life_notifications_severity_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX life_notifications_severity_index ON public.life_notifications USING btree (severity);


--
-- Name: life_notifications_user_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX life_notifications_user_id_index ON public.life_notifications USING btree (user_id);


--
-- Name: life_notifications_user_id_is_read_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX life_notifications_user_id_is_read_index ON public.life_notifications USING btree (user_id, is_read);


--
-- Name: model_has_permissions_model_id_model_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX model_has_permissions_model_id_model_type_index ON public.model_has_permissions USING btree (model_id, model_type);


--
-- Name: model_has_roles_model_id_model_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX model_has_roles_model_id_model_type_index ON public.model_has_roles USING btree (model_id, model_type);


--
-- Name: notification_preferences_user_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX notification_preferences_user_id_index ON public.notification_preferences USING btree (user_id);


--
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON public.personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- Name: project_milestones_project_id_status_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX project_milestones_project_id_status_index ON public.project_milestones USING btree (project_id, status);


--
-- Name: project_status_updates_project_id_created_at_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX project_status_updates_project_id_created_at_index ON public.project_status_updates USING btree (project_id, created_at);


--
-- Name: project_status_updates_project_id_update_type_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX project_status_updates_project_id_update_type_index ON public.project_status_updates USING btree (project_id, update_type);


--
-- Name: project_tasks_due_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX project_tasks_due_date_index ON public.project_tasks USING btree (due_date);


--
-- Name: project_tasks_priority_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX project_tasks_priority_index ON public.project_tasks USING btree (priority);


--
-- Name: project_tasks_project_id_status_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX project_tasks_project_id_status_index ON public.project_tasks USING btree (project_id, status);


--
-- Name: project_tasks_user_id_status_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX project_tasks_user_id_status_index ON public.project_tasks USING btree (user_id, status);


--
-- Name: projects_start_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX projects_start_date_index ON public.projects USING btree (start_date);


--
-- Name: projects_target_end_date_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX projects_target_end_date_index ON public.projects USING btree (target_end_date);


--
-- Name: projects_user_id_priority_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX projects_user_id_priority_index ON public.projects USING btree (user_id, priority);


--
-- Name: projects_user_id_status_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX projects_user_id_status_index ON public.projects USING btree (user_id, status);


--
-- Name: subscription_usage_subscription_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX subscription_usage_subscription_id_index ON public.subscription_usage USING btree (subscription_id);


--
-- Name: subscription_usage_user_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX subscription_usage_user_id_index ON public.subscription_usage USING btree (user_id);


--
-- Name: subscriptions_plan_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX subscriptions_plan_id_index ON public.subscriptions USING btree (plan_id);


--
-- Name: subscriptions_status_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX subscriptions_status_index ON public.subscriptions USING btree (status);


--
-- Name: subscriptions_user_id_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX subscriptions_user_id_index ON public.subscriptions USING btree (user_id);


--
-- Name: system_monitoring_logs_checked_at_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX system_monitoring_logs_checked_at_index ON public.system_monitoring_logs USING btree (checked_at);


--
-- Name: system_monitoring_logs_service_name_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX system_monitoring_logs_service_name_index ON public.system_monitoring_logs USING btree (service_name);


--
-- Name: system_monitoring_logs_status_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX system_monitoring_logs_status_index ON public.system_monitoring_logs USING btree (status);


--
-- Name: users_role_is_active_index; Type: INDEX; Schema: public; Owner: nixlifeos_user
--

CREATE INDEX users_role_is_active_index ON public.users USING btree (role, is_active);


--
-- Name: ai_alerts ai_alerts_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.ai_alerts
    ADD CONSTRAINT ai_alerts_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: ai_insights ai_insights_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.ai_insights
    ADD CONSTRAINT ai_insights_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: ai_reports ai_reports_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.ai_reports
    ADD CONSTRAINT ai_reports_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: automation_rules automation_rules_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.automation_rules
    ADD CONSTRAINT automation_rules_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: automation_trigger_logs automation_trigger_logs_automation_rule_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.automation_trigger_logs
    ADD CONSTRAINT automation_trigger_logs_automation_rule_id_foreign FOREIGN KEY (automation_rule_id) REFERENCES public.automation_rules(id) ON DELETE CASCADE;


--
-- Name: automation_trigger_logs automation_trigger_logs_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.automation_trigger_logs
    ADD CONSTRAINT automation_trigger_logs_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: health_food_items health_food_items_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_food_items
    ADD CONSTRAINT health_food_items_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: health_hydration_logs health_hydration_logs_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_hydration_logs
    ADD CONSTRAINT health_hydration_logs_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: health_meal_log_items health_meal_log_items_food_item_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_meal_log_items
    ADD CONSTRAINT health_meal_log_items_food_item_id_foreign FOREIGN KEY (food_item_id) REFERENCES public.health_food_items(id) ON DELETE RESTRICT;


--
-- Name: health_meal_log_items health_meal_log_items_meal_log_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_meal_log_items
    ADD CONSTRAINT health_meal_log_items_meal_log_id_foreign FOREIGN KEY (meal_log_id) REFERENCES public.health_meal_logs(id) ON DELETE CASCADE;


--
-- Name: health_meal_logs health_meal_logs_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_meal_logs
    ADD CONSTRAINT health_meal_logs_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: health_nutrition_profiles health_nutrition_profiles_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_nutrition_profiles
    ADD CONSTRAINT health_nutrition_profiles_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: health_profile health_profile_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_profile
    ADD CONSTRAINT health_profile_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: health_step_log health_step_log_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_step_log
    ADD CONSTRAINT health_step_log_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: health_weight_logs health_weight_logs_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.health_weight_logs
    ADD CONSTRAINT health_weight_logs_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: model_has_permissions model_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.model_has_permissions
    ADD CONSTRAINT model_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: model_has_roles model_has_roles_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.model_has_roles
    ADD CONSTRAINT model_has_roles_role_id_foreign FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: project_milestones project_milestones_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.project_milestones
    ADD CONSTRAINT project_milestones_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_status_updates project_status_updates_milestone_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.project_status_updates
    ADD CONSTRAINT project_status_updates_milestone_id_foreign FOREIGN KEY (milestone_id) REFERENCES public.project_milestones(id) ON DELETE SET NULL;


--
-- Name: project_status_updates project_status_updates_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.project_status_updates
    ADD CONSTRAINT project_status_updates_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_status_updates project_status_updates_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.project_status_updates
    ADD CONSTRAINT project_status_updates_task_id_foreign FOREIGN KEY (task_id) REFERENCES public.project_tasks(id) ON DELETE SET NULL;


--
-- Name: project_tasks project_tasks_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.project_tasks
    ADD CONSTRAINT project_tasks_project_id_foreign FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_tasks project_tasks_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.project_tasks
    ADD CONSTRAINT project_tasks_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: projects projects_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: role_has_permissions role_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.role_has_permissions
    ADD CONSTRAINT role_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_has_permissions role_has_permissions_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.role_has_permissions
    ADD CONSTRAINT role_has_permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: subscription_usage subscription_usage_subscription_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.subscription_usage
    ADD CONSTRAINT subscription_usage_subscription_id_foreign FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id) ON DELETE CASCADE;


--
-- Name: subscription_usage subscription_usage_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.subscription_usage
    ADD CONSTRAINT subscription_usage_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_plan_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_plan_id_foreign FOREIGN KEY (plan_id) REFERENCES public.plans(id) ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: nixlifeos_user
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO nixlifeos_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: ai; Owner: nixlifeos_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE nixlifeos_user IN SCHEMA ai GRANT ALL ON TABLES TO nixlifeos_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: automation; Owner: nixlifeos_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE nixlifeos_user IN SCHEMA automation GRANT ALL ON TABLES TO nixlifeos_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: finance; Owner: nixlifeos_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE nixlifeos_user IN SCHEMA finance GRANT ALL ON TABLES TO nixlifeos_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: health; Owner: nixlifeos_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE nixlifeos_user IN SCHEMA health GRANT ALL ON TABLES TO nixlifeos_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: monitoring; Owner: nixlifeos_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE nixlifeos_user IN SCHEMA monitoring GRANT ALL ON TABLES TO nixlifeos_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: nix_life_os; Owner: nixlifeos_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE nixlifeos_user IN SCHEMA nix_life_os GRANT ALL ON TABLES TO nixlifeos_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: projects; Owner: nixlifeos_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE nixlifeos_user IN SCHEMA projects GRANT ALL ON TABLES TO nixlifeos_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: nixlifeos_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE nixlifeos_user IN SCHEMA public GRANT ALL ON SEQUENCES TO nixlifeos_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: nixlifeos_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE nixlifeos_user IN SCHEMA public GRANT ALL ON FUNCTIONS TO nixlifeos_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: nixlifeos_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE nixlifeos_user IN SCHEMA public GRANT ALL ON TABLES TO nixlifeos_user;


--
-- PostgreSQL database dump complete
--

\unrestrict 5Qlbmnf9w0v8cMmI9Fwrrx00cviIltEc24IwoDcYzVl98lcVmPNNzMxS38cmJwf


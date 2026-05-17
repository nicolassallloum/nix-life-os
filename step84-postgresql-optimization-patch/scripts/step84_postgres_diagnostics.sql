-- STEP 84 — PostgreSQL diagnostics
-- Run with: psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f scripts/step84_postgres_diagnostics.sql

\echo '1) Extension status'
SELECT extname, extversion FROM pg_extension ORDER BY extname;

\echo '2) Table sizes'
SELECT relname AS table_name,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
       pg_size_pretty(pg_relation_size(relid)) AS table_size,
       pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS indexes_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

\echo '3) Sequential scans'
SELECT relname AS table_name, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, n_live_tup
FROM pg_stat_user_tables
ORDER BY seq_tup_read DESC
LIMIT 50;

\echo '4) Duplicate exact indexes by definition'
WITH idx AS (
    SELECT schemaname, tablename, indexname,
           regexp_replace(indexdef, 'CREATE (UNIQUE )?INDEX [^ ]+ ', 'CREATE INDEX ', 'g') AS normalized_def
    FROM pg_indexes
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
)
SELECT schemaname, tablename, normalized_def, array_agg(indexname ORDER BY indexname) AS duplicate_indexes, count(*) AS duplicate_count
FROM idx
GROUP BY schemaname, tablename, normalized_def
HAVING count(*) > 1
ORDER BY duplicate_count DESC, tablename;

\echo '5) Low or never used indexes'
SELECT schemaname, relname AS table_name, indexrelname AS index_name, idx_scan,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY idx_scan ASC, pg_relation_size(indexrelid) DESC
LIMIT 100;

\echo '6) Possible table bloat / stale stats'
SELECT schemaname, relname AS table_name, n_live_tup, n_dead_tup, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC, n_live_tup DESC;

\echo '7) pg_stat_statements top queries if extension is enabled'
SELECT query, calls, total_exec_time, mean_exec_time, max_exec_time, rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 50;

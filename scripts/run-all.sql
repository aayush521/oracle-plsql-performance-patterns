-- Run every pattern in order against a fresh demo schema.
-- Connect as a user with CREATE TABLE / CREATE INDEX / CREATE TYPE privileges,
-- then: @scripts/run-all.sql

PROMPT === Step 1: schema ===
@@../schema/sql/01-create-schema.sql
@@../schema/sql/02-load-sample-data.sql

PROMPT === Step 2: pattern 01 — bulk collect / FORALL ===
@@../patterns/01-bulk-collect-forall/sql/demo.sql

PROMPT === Step 3: pattern 02 — partitioning ===
@@../patterns/02-partitioning/sql/demo.sql

PROMPT === Step 4: pattern 03 — indexing ===
@@../patterns/03-indexing/sql/demo.sql

PROMPT === Step 5: pattern 04 — bind variables ===
@@../patterns/04-bind-variables/sql/demo.sql

PROMPT === Step 6: pattern 05 — pipelined functions ===
@@../patterns/05-pipelined-functions/sql/demo.sql

PROMPT === Step 7: pattern 06 — materialized views ===
@@../patterns/06-materialized-views/sql/demo.sql

PROMPT === Step 8: pattern 07 — parallel DML & query hints ===
@@../patterns/07-parallel-dml/sql/demo.sql

PROMPT === Done. To clean up: @schema/sql/99-drop-schema.sql ===

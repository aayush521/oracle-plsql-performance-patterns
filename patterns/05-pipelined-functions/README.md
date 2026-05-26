# Pattern 05 — Pipelined table functions

## Problem

A multi-stage transformation reads rows from one source, transforms them, and writes them to another target. Naive implementations:

1. Read everything into a PL/SQL collection (high PGA, blows up on huge sets).
2. Insert the collection to a staging table (extra IO, redo, undo).
3. Read the staging table back to do the next stage.

Each materialization step doubles the IO cost.

## Pattern

A **pipelined table function** streams rows out as it generates them, so callers can `SELECT FROM TABLE(...)` and consume the stream lazily — without ever materializing the intermediate set.

```plsql
CREATE OR REPLACE TYPE staging_row_t AS OBJECT (
    exposure_id     NUMBER,
    new_stage       NUMBER(1),
    new_ecl_amount  NUMBER(18,2)
);
/
CREATE OR REPLACE TYPE staging_tab_t AS TABLE OF staging_row_t;
/

CREATE OR REPLACE FUNCTION compute_staging
    RETURN staging_tab_t PIPELINED
IS
BEGIN
    FOR rec IN (SELECT exposure_id, days_past_due, outstanding_amount FROM exposures) LOOP
        PIPE ROW (staging_row_t(
            rec.exposure_id,
            CASE WHEN rec.days_past_due >= 90 THEN 3
                 WHEN rec.days_past_due >= 30 THEN 2
                 ELSE 1 END,
            rec.outstanding_amount * 0.02
        ));
    END LOOP;
    RETURN;
END;
/

-- Consume as if it were a table
INSERT INTO exposures_staged (exposure_id, reporting_date, new_stage, new_ecl_amount)
SELECT s.exposure_id, TRUNC(SYSDATE), s.new_stage, s.new_ecl_amount
FROM   TABLE(compute_staging) s;
```

## Run the demo

```sql
@patterns/05-pipelined-functions/sql/demo.sql
```

## Tuning notes

- **Parallel pipelined functions** declare `PARALLEL_ENABLE (PARTITION BY ...)` and Oracle automatically partitions the input stream across slaves. Massive speedup on multi-CPU databases.
- **Don't use pipelined functions for trivial transformations** — they have a setup cost. Set-based SQL is still the first choice. Pipelined wins when the transformation is genuinely procedural.
- **No DML inside a pipelined function.** It's a query construct. If you need to write, do the writing in the caller's `INSERT ... SELECT FROM TABLE(...)`.

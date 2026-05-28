# Pattern 07 — Parallel DML & Query Hints

## Problem

Single-threaded execution leaves modern multi-core servers idle on heavy DML
and large analytic scans. A nightly batch that updates tens of millions of
rows can take hours when it could complete in minutes if Oracle was allowed
to parallelize the work across several slaves.

## Pattern

Two complementary tools:

### 1. Parallel query hints

Tell the optimizer it's allowed to spawn slave processes to scan a table:

```sql
SELECT /*+ PARALLEL(e, 4) */
       product_code, SUM(outstanding_amount)
FROM   exposures e
GROUP BY product_code;
```

`PARALLEL(e, 4)` requests up to 4 slave processes operating on the
`exposures` table. Oracle may use fewer if the system is busy.

### 2. Parallel DML

Parallel DML is **disabled by default** in a session. You must enable it
explicitly before issuing the statement:

```sql
ALTER SESSION ENABLE PARALLEL DML;

UPDATE /*+ PARALLEL(e, 4) */ exposures e
   SET stage = CASE
                  WHEN days_past_due >= 90 THEN 3
                  WHEN days_past_due >= 30 THEN 2
                  ELSE 1
               END;

COMMIT;
```

## Run the demo

```sql
@patterns/07-parallel-dml/sql/demo.sql
```

Expect a 2–4x speedup on a 4-core machine with the demo data volume.
On real production hardware with billions of rows, the gap can be 10x or more.

## Tuning notes

- **Parallel DML and triggers / referential integrity** sometimes don't mix.
  Read the docs for your version before enabling on tables with cascading
  constraints — Oracle may silently downgrade to serial execution.
- **The session must commit or rollback** before issuing another DML on the
  same table inside the same session after parallel DML.
- **Parallel hints are advisory.** The optimizer can ignore them if PGA
  pressure is high, the table is small, or partition pruning has already
  reduced the work to a single segment.
- **Parallel query and parallel DML are licensed separately on some Oracle
  editions.** Check your license before relying on them in production.
- **Don't blindly hint everything.** Parallel adds coordination overhead;
  small statements run faster serially.

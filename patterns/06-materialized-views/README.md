# Pattern 06 — Materialized views

## Problem

A reporting query that aggregates millions of rows runs every time someone refreshes a dashboard. The aggregate result barely changes during the day. The database burns CPU and IO computing the same answer.

## Pattern

A materialized view (MV) **stores the result of an aggregate query as a real table**, refreshed on a schedule or on commit. Subsequent reads hit the precomputed result.

```sql
CREATE MATERIALIZED VIEW mv_exposure_summary
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT  reporting_date,
        product_code,
        stage,
        COUNT(*)              AS exposure_count,
        SUM(outstanding_amount) AS total_outstanding,
        SUM(ecl_amount)         AS total_ecl
FROM    exposures
GROUP BY reporting_date, product_code, stage;
```

A nightly refresh keeps it current:

```sql
BEGIN
    DBMS_MVIEW.REFRESH('MV_EXPOSURE_SUMMARY', 'C');
END;
/
```

For low-latency needs, use `REFRESH FAST ON COMMIT` with materialized view logs — but understand the DML overhead before committing to that mode in production.

## Bonus: query rewrite

Set `QUERY_REWRITE_ENABLED=TRUE` and run the original aggregate query — the optimizer will automatically rewrite it against the MV, even if the application doesn't reference the MV explicitly. Magic, when it works; brittle when it doesn't (constraints have to line up).

## Run the demo

```sql
@patterns/06-materialized-views/sql/demo.sql
```

## Tuning notes

- **Choose refresh mode deliberately.** `COMPLETE ON DEMAND` is simple and cheap to build. `FAST ON COMMIT` is real-time but slows DML on the base table. `REFRESH FORCE` lets Oracle pick fast vs complete.
- **Materialized view logs** are required for fast refresh. Add them on the base tables before creating the MV with fast refresh.
- **Don't materialize what you can't refresh in time.** A 6-hour refresh window for a 5-hour MV build is fragile.
- **Indexes on the MV** are first-class. Add them like you would on any table.

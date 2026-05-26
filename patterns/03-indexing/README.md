# Pattern 03 — Indexing strategy

## Problem

A query that should be a millisecond point lookup turns into a full table scan because:

- The predicate column has no index.
- The predicate is wrapped in a function (e.g. `UPPER(customer_name) = ...`) and the index on `customer_name` becomes unusable.
- The predicate uses two columns and only one is indexed; the optimizer falls back to a scan.

## Pattern

### 1. Composite indexes for AND-predicates

```sql
CREATE INDEX ix_exp_cust_date
    ON exposures (customer_id, reporting_date);
```

A composite covers both single-column lookups on `customer_id` and combined lookups on `(customer_id, reporting_date)`. Order matters — leading column is the one most likely to appear alone in queries.

### 2. Function-based indexes when predicates wrap columns

```sql
CREATE INDEX ix_cust_name_upper
    ON customers (UPPER(customer_name));
```

Now `WHERE UPPER(customer_name) = 'ACME CORP'` is index-driven instead of a scan.

### 3. Skip the index on low-selectivity columns

A column with 3 distinct values across 50M rows shouldn't be indexed for predicate access. Bitmap indexes can help in DSS workloads but are usually wrong on OLTP tables (locking pain).

### 4. Always rebuild stats after structural changes

```sql
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'EXPOSURES');
```

Without fresh stats, the optimizer can pick a worse plan than the unindexed version.

## Run the demo

```sql
@patterns/03-indexing/sql/demo.sql
```

The demo runs the same query before and after creating the index, capturing each plan with `DBMS_XPLAN.DISPLAY_CURSOR`.

## Tuning notes

- **Don't index everything.** Each index slows DML by 5–15% and consumes space. Index for the queries you actually run.
- **`INDEX_FFS` and `INDEX SKIP SCAN`** can sometimes recover from a bad index choice — but they're a hint that the index design is wrong.
- **Invisible indexes** (`INVISIBLE`) let you test an index in production without affecting the optimizer until you flip it visible.
- **Monitor unused indexes** with `V$OBJECT_USAGE` (`ALTER INDEX ... MONITORING USAGE`). Drop indexes that are never used — they're pure overhead.

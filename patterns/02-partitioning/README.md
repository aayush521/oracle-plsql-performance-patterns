# Pattern 02 — Partitioning

## Problem

Massive tables that are queried by date range or by some natural shard key (region, account class, batch ID) suffer **full segment scans** even when the query only needs 1% of the data. Index-only access patterns help, but for huge analytic workloads partitioning is the bigger lever.

## Pattern

Range-partition by reporting date (the most common axis in banking), and let the optimizer prune partitions automatically.

```sql
CREATE TABLE exposures_partitioned (
    exposure_id        NUMBER          NOT NULL,
    customer_id        NUMBER          NOT NULL,
    reporting_date     DATE            NOT NULL,
    product_code       VARCHAR2(10)    NOT NULL,
    outstanding_amount NUMBER(18,2)    NOT NULL,
    days_past_due      NUMBER(5)       NOT NULL,
    stage              NUMBER(1)       NOT NULL
)
PARTITION BY RANGE (reporting_date) INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
    PARTITION p_initial VALUES LESS THAN (DATE '2023-01-01')
);
```

`INTERVAL` partitioning means Oracle creates a new monthly partition automatically the first time data lands in a new month. No DBA ticket required for ongoing maintenance.

Run a query that filters on `reporting_date` and Oracle reads **only the matching partitions**:

```sql
SELECT SUM(outstanding_amount)
FROM   exposures_partitioned
WHERE  reporting_date BETWEEN DATE '2025-01-01' AND DATE '2025-03-31';
```

`EXPLAIN PLAN` will show `PARTITION RANGE ITERATOR` with `Pstart` / `Pstop` — that's partition pruning at work.

## Run the demo

```sql
@patterns/02-partitioning/sql/demo.sql
@patterns/02-partitioning/sql/benchmark.sql
```

The benchmark loads identical data into a partitioned and a non-partitioned table, then runs the same date-range aggregate against each. Expect **~5x** on the demo dataset; in production with multi-billion-row tables the gap can be 20x or more.

## Tuning notes

- **Local indexes follow partitions.** Use them for predicates that include the partition key. Use **global indexes** (carefully) for predicates that don't.
- **List/hash partitioning** are alternatives. Use list when natural categories exist (region, currency); use hash when you need uniform distribution and pruning isn't a goal.
- **Composite partitioning** (range-hash) is common for fact tables: range by date, sub-partition by hash of customer_id.
- **Partition exchange** is the fastest way to load a new partition: load a staging table, then `ALTER TABLE ... EXCHANGE PARTITION` swaps it in atomically.

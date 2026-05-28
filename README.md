# Oracle PL/SQL Performance Patterns

> Battle-tested patterns for writing fast PL/SQL on Oracle 11g/12c/19c. Real techniques used in production banking and ETL workloads, distilled into runnable scripts with before/after benchmarks.

[![Oracle](https://img.shields.io/badge/Oracle-11g%20%7C%2012c%20%7C%2019c-F80000?logo=oracle&logoColor=white)](https://www.oracle.com/database/)
[![PL/SQL](https://img.shields.io/badge/PL%2FSQL-patterns-F80000)](https://docs.oracle.com/en/database/oracle/oracle-database/19/lnpls/index.html)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> Curated by [Aayush Rathod](https://github.com/aayush521) — patterns I used to **reduce ETL batch run times by 40%** on production banking systems handling millions of daily transactions.

---

## Why this repo exists

Most PL/SQL performance content online is fragmented — a tip in a forum thread, a slide in a conference deck, a chapter in an old book. This repo collects the patterns I actually reach for in production banking workloads, with **runnable demos** and **measurable before/after results** for each one.

If you're tuning Oracle batch jobs, this is the playbook I wish I had when I started.

---

## Contents

| # | Pattern | When to use | Typical impact |
|---|---|---|---|
| 1 | [**Bulk Collect & FORALL**](patterns/01-bulk-collect-forall/) | Replacing row-by-row cursors that touch large tables | **~10x** on bulk loads |
| 2 | [**Partitioning**](patterns/02-partitioning/) | Massive tables queried by date / region / hash key | **~5x** on date-range scans |
| 3 | [**Indexing strategy**](patterns/03-indexing/) | Slow predicates, full table scans on selective queries | **10–100x** on point lookups |
| 4 | [**Bind variables**](patterns/04-bind-variables/) | Dynamic SQL flooding the shared pool | **2–5x** under concurrency |
| 5 | [**Pipelined table functions**](patterns/05-pipelined-functions/) | Streaming transformations between stages | **~3x** + lower memory |
| 6 | [**Materialized views**](patterns/06-materialized-views/) | Expensive aggregations re-run by reports | **10–100x** on read |
| 7 | [**Parallel DML & query hints**](patterns/07-parallel-dml/) | CPU-bound DML and analytic queries on large tables | **2–10x** on multi-core servers |

Each folder has its own README with the pattern, a runnable demo, and a benchmark script.

---

## How to run the demos

You need an Oracle 19c (or 21c XE) instance you can connect to with sysdba or a privileged user. Free options:

- **Oracle Database Free 23ai** — `docker run -d -p 1521:1521 -e ORACLE_PWD=YourPwd container-registry.oracle.com/database/free:latest`
- **Oracle Cloud Free Tier** — Always Free Autonomous Database
- **Oracle Database Express Edition (XE)** — local install

Then:

```bash
# Connect (sqlplus, sqlcl, or DBeaver/SQL Developer)
sqlplus system/YourPwd@//localhost:1521/FREEPDB1

# Set up the demo schema
@schema/sql/01-create-schema.sql
@schema/sql/02-load-sample-data.sql

# Run any pattern's demo
@patterns/01-bulk-collect-forall/sql/demo.sql
@patterns/01-bulk-collect-forall/sql/benchmark.sql
```

Every demo is idempotent and self-cleaning. Drop the demo schema at the end with `@schema/sql/99-drop-schema.sql`.

---

## How I used these in production

The `40% ETL improvement` figure on my resume came from a multi-month engagement applying the patterns in this repo to an IFRS 9 / Expected Credit Loss (ECL) batch on a tier-1 bank. Specifically:

1. Replaced row-by-row PL/SQL cursors over a 50M-row exposures table with `BULK COLLECT INTO ... LIMIT 10000` + `FORALL` (pattern 1)
2. Range-partitioned the exposures and stage transitions tables by reporting date (pattern 2)
3. Added function-based and composite indexes on the hot predicates the batch was actually using (pattern 3)
4. Replaced literal-driven dynamic SQL in the rules engine with bind-variable templates (pattern 4)
5. Refactored the cohort-staging step into a pipelined table function (pattern 5)

Combined effect: nightly ECL batch went from **~5h** to **~3h**, with a fraction of the previous redo / undo footprint.

---

## What this repo is **not**

- Not a generic SQL tuning guide. Index-organized tables, hint forests, hash-join tricks — go read Tom Kyte. This is the focused subset I actually keep in my toolbelt.
- Not a substitute for `EXPLAIN PLAN`, `DBMS_XPLAN`, AWR reports, and SQL Monitor. Patterns help; measurement closes the loop.
- Not a recommendation to PL/SQL-everything. Where a single set-based SQL statement works, use that first. PL/SQL bulk patterns are for when the work genuinely needs procedural logic.

---

## License

MIT — see [LICENSE](LICENSE).

---

<sub>If you're a recruiter or hiring manager: happy to walk through a real production tuning case. Reach me via [LinkedIn](https://linkedin.com/in/aayush-rathod11).</sub>

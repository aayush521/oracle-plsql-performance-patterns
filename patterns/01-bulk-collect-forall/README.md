# Pattern 01 — Bulk Collect & FORALL

## Problem

Naive PL/SQL loops process one row at a time, switching between the SQL engine and the PL/SQL engine on every iteration. On large tables this **context switching cost dominates the total runtime**. A 1M-row update can take tens of minutes when it should take under one.

## Pattern

Fetch in batches with `BULK COLLECT INTO ... LIMIT`, then apply with `FORALL`. The whole batch crosses the engine boundary once.

```plsql
DECLARE
    CURSOR c IS SELECT exposure_id, days_past_due FROM exposures;
    TYPE   t_id  IS TABLE OF exposures.exposure_id%TYPE;
    TYPE   t_dpd IS TABLE OF exposures.days_past_due%TYPE;
    l_ids  t_id;
    l_dpds t_dpd;
    c_batch_size CONSTANT PLS_INTEGER := 10000;
BEGIN
    OPEN c;
    LOOP
        FETCH c BULK COLLECT INTO l_ids, l_dpds LIMIT c_batch_size;
        EXIT WHEN l_ids.COUNT = 0;

        FORALL i IN 1 .. l_ids.COUNT
            UPDATE exposures
               SET stage = CASE
                              WHEN l_dpds(i) >= 90 THEN 3
                              WHEN l_dpds(i) >= 30 THEN 2
                              ELSE 1
                           END
             WHERE exposure_id = l_ids(i);
    END LOOP;
    CLOSE c;
    COMMIT;
END;
/
```

## Run the demo

```sql
@patterns/01-bulk-collect-forall/sql/demo.sql
@patterns/01-bulk-collect-forall/sql/benchmark.sql
```

The benchmark runs the same logical update three times — row-by-row, batch=1000, batch=10000 — and prints the elapsed time for each. Expect **~10x speedup** at batch=10000 over the row-by-row baseline on the demo dataset.

## Tuning notes

- **Batch size sweet spot is usually 1,000–10,000.** Bigger means more PGA per session; smaller means more context switches.
- **`SAVE EXCEPTIONS`** on the `FORALL` lets a single bad row not kill the entire batch.
- **Watch undo / redo.** Bigger batches generate bigger undo. Commit every batch on huge volumes if your session is otherwise long-running.
- **Set-based SQL beats this entire pattern** when the logic is expressible as one `UPDATE`. Reach for bulk PL/SQL only when procedural logic is genuinely needed.

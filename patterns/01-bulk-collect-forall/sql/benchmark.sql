-- Pattern 01 — benchmark: row-by-row vs batch=1000 vs batch=10000.

SET SERVEROUTPUT ON SIZE UNLIMITED

CREATE OR REPLACE PROCEDURE bench_row_by_row IS
    l_t0 TIMESTAMP := SYSTIMESTAMP;
BEGIN
    UPDATE exposures SET stage = 1;
    COMMIT;
    FOR rec IN (SELECT exposure_id, days_past_due FROM exposures) LOOP
        UPDATE exposures
           SET stage = CASE
                          WHEN rec.days_past_due >= 90 THEN 3
                          WHEN rec.days_past_due >= 30 THEN 2
                          ELSE 1
                       END
         WHERE exposure_id = rec.exposure_id;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('row-by-row : ' ||
        EXTRACT(SECOND FROM (SYSTIMESTAMP - l_t0)) || ' s');
END;
/

CREATE OR REPLACE PROCEDURE bench_bulk(p_batch IN PLS_INTEGER) IS
    CURSOR c IS SELECT exposure_id, days_past_due FROM exposures;
    TYPE t_id  IS TABLE OF exposures.exposure_id%TYPE;
    TYPE t_dpd IS TABLE OF exposures.days_past_due%TYPE;
    l_ids  t_id;
    l_dpds t_dpd;
    l_t0   TIMESTAMP := SYSTIMESTAMP;
BEGIN
    UPDATE exposures SET stage = 1;
    COMMIT;
    OPEN c;
    LOOP
        FETCH c BULK COLLECT INTO l_ids, l_dpds LIMIT p_batch;
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
    DBMS_OUTPUT.PUT_LINE('bulk batch=' || p_batch || ' : ' ||
        EXTRACT(SECOND FROM (SYSTIMESTAMP - l_t0)) || ' s');
END;
/

PROMPT === Benchmarking (row-by-row will be SLOW; reduce data volume if needed) ===
EXEC bench_row_by_row;
EXEC bench_bulk(1000);
EXEC bench_bulk(10000);

DROP PROCEDURE bench_row_by_row;
DROP PROCEDURE bench_bulk;

-- Pattern 01 — Bulk Collect & FORALL: minimal working demo.
-- Uses the EXPOSURES table from the demo schema.

PROMPT === Resetting stage column for the demo ===
UPDATE exposures SET stage = 1;
COMMIT;

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON

DECLARE
    CURSOR c IS
        SELECT exposure_id, days_past_due FROM exposures;
    TYPE   t_id  IS TABLE OF exposures.exposure_id%TYPE;
    TYPE   t_dpd IS TABLE OF exposures.days_past_due%TYPE;
    l_ids  t_id;
    l_dpds t_dpd;
    c_batch_size CONSTANT PLS_INTEGER := 10000;
    l_total      PLS_INTEGER := 0;
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
        l_total := l_total + l_ids.COUNT;
    END LOOP;
    CLOSE c;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Updated ' || l_total || ' rows in batches of ' || c_batch_size);
END;
/

SET TIMING OFF

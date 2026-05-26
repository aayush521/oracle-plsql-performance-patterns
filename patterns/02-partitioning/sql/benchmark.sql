-- Pattern 02 — benchmark: same date-range aggregate against partitioned vs not.

SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    l_t0  TIMESTAMP;
    l_sum NUMBER;
BEGIN
    -- Warm up
    SELECT SUM(outstanding_amount) INTO l_sum FROM exposures_nopart;
    SELECT SUM(outstanding_amount) INTO l_sum FROM exposures_partitioned;

    -- Non-partitioned
    l_t0 := SYSTIMESTAMP;
    SELECT SUM(outstanding_amount)
      INTO l_sum
      FROM exposures_nopart
     WHERE reporting_date BETWEEN TRUNC(SYSDATE) - 90 AND TRUNC(SYSDATE);
    DBMS_OUTPUT.PUT_LINE('non-partitioned: ' ||
        EXTRACT(SECOND FROM (SYSTIMESTAMP - l_t0)) || ' s, sum=' || l_sum);

    -- Partitioned
    l_t0 := SYSTIMESTAMP;
    SELECT SUM(outstanding_amount)
      INTO l_sum
      FROM exposures_partitioned
     WHERE reporting_date BETWEEN TRUNC(SYSDATE) - 90 AND TRUNC(SYSDATE);
    DBMS_OUTPUT.PUT_LINE('partitioned    : ' ||
        EXTRACT(SECOND FROM (SYSTIMESTAMP - l_t0)) || ' s, sum=' || l_sum);
END;
/

-- Pattern 05 — Pipelined table function for streaming staging.

PROMPT === Drop existing types if present ===
BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION compute_staging';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE staging_tab_t';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE staging_row_t';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TYPE staging_row_t AS OBJECT (
    exposure_id     NUMBER,
    new_stage       NUMBER(1),
    new_ecl_amount  NUMBER(18,2)
);
/

CREATE TYPE staging_tab_t AS TABLE OF staging_row_t;
/

CREATE FUNCTION compute_staging
    RETURN staging_tab_t PIPELINED
IS
BEGIN
    FOR rec IN (
        SELECT exposure_id, days_past_due, outstanding_amount
        FROM   exposures
    ) LOOP
        PIPE ROW (staging_row_t(
            rec.exposure_id,
            CASE
                WHEN rec.days_past_due >= 90 THEN 3
                WHEN rec.days_past_due >= 30 THEN 2
                ELSE                              1
            END,
            ROUND(rec.outstanding_amount * 0.02, 2)
        ));
    END LOOP;
    RETURN;
END;
/

PROMPT === Stream into the staging table ===
TRUNCATE TABLE exposures_staged;

INSERT /*+ APPEND */ INTO exposures_staged (
    exposure_id, reporting_date, new_stage, new_ecl_amount)
SELECT  s.exposure_id, TRUNC(SYSDATE), s.new_stage, s.new_ecl_amount
FROM    TABLE(compute_staging) s;

COMMIT;

SELECT COUNT(*) AS rows_staged FROM exposures_staged;

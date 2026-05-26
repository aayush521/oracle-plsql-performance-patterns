-- Tear down all demo objects.
PROMPT === Dropping demo schema ===

BEGIN
    FOR rec IN (
        SELECT table_name FROM user_tables
        WHERE table_name IN (
            'EXPOSURES','EXPOSURES_STAGED','CUSTOMERS',
            'EXPOSURES_PARTITIONED','EXPOSURES_NOPART'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || rec.table_name || ' CASCADE CONSTRAINTS PURGE';
    END LOOP;

    FOR rec IN (SELECT mview_name FROM user_mviews) LOOP
        EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW ' || rec.mview_name;
    END LOOP;
END;
/

PROMPT === Done ===

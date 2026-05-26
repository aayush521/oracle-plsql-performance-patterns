-- Pattern 04 — Bind variables vs literal concatenation: cursor count.

SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT === Flush the shared pool so we can compare cursors cleanly ===
ALTER SYSTEM FLUSH SHARED_POOL;

PROMPT === BAD: literal concatenation, 100 cursors created ===
DECLARE
    l_sum NUMBER;
BEGIN
    FOR i IN 1 .. 100 LOOP
        EXECUTE IMMEDIATE
            'SELECT SUM(outstanding_amount) FROM exposures WHERE customer_id = ' || i
            INTO l_sum;
    END LOOP;
END;
/

SELECT COUNT(*) AS literal_cursor_count
FROM   v$sql
WHERE  sql_text LIKE 'SELECT SUM(outstanding_amount) FROM exposures WHERE customer_id =%';

ALTER SYSTEM FLUSH SHARED_POOL;

PROMPT === GOOD: bind variable, 1 cursor reused 100 times ===
DECLARE
    l_sum NUMBER;
BEGIN
    FOR i IN 1 .. 100 LOOP
        EXECUTE IMMEDIATE
            'SELECT SUM(outstanding_amount) FROM exposures WHERE customer_id = :id'
            INTO l_sum
            USING i;
    END LOOP;
END;
/

SELECT COUNT(*) AS bind_cursor_count
FROM   v$sql
WHERE  sql_text LIKE 'SELECT SUM(outstanding_amount) FROM exposures WHERE customer_id = :id';

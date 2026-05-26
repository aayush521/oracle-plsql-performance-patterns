# Oracle diagnostic cheat sheet

A short list of queries and commands I keep within reach when tuning. Bookmark, don't memorize.

## Plan inspection

```sql
-- Plan for the last cursor in this session
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'BASIC LAST'));

-- Plan + actual row counts (great for spotting cardinality misestimates)
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- Plan for an arbitrary SQL_ID
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id'));
```

## What's running right now

```sql
SELECT  s.sid, s.serial#, s.username, s.osuser, s.machine, s.program,
        s.event, s.wait_class, s.seconds_in_wait, s.sql_id, q.sql_text
FROM    v$session s
LEFT JOIN v$sql q ON q.sql_id = s.sql_id AND q.child_number = s.sql_child_number
WHERE   s.status = 'ACTIVE'
AND     s.username IS NOT NULL
ORDER BY s.seconds_in_wait DESC;
```

## Top SQL by elapsed time

```sql
SELECT  sql_id, executions, ROUND(elapsed_time/1e6, 2) elapsed_sec,
        ROUND(elapsed_time/GREATEST(executions,1)/1e3, 2) avg_ms,
        SUBSTR(sql_text, 1, 100) sql_preview
FROM    v$sql
WHERE   elapsed_time > 5e6
ORDER BY elapsed_time DESC
FETCH FIRST 20 ROWS ONLY;
```

## Object stats

```sql
SELECT  table_name, num_rows, blocks, last_analyzed
FROM    user_tables
ORDER BY num_rows DESC NULLS LAST;
```

## Find unused indexes

```sql
ALTER INDEX <name> MONITORING USAGE;
-- ... let production traffic run for a few days ...
SELECT  index_name, used
FROM    v$object_usage
WHERE   used = 'NO';
```

## SQL trace + tkprof

```sql
ALTER SESSION SET tracefile_identifier = 'aayush_trace';
ALTER SESSION SET sql_trace = TRUE;
-- run workload
ALTER SESSION SET sql_trace = FALSE;
-- locate the trace file
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
```

Then on the OS:

```bash
tkprof <tracefile> tkprof.out sort=exeela,prsela,fchela explain=app/app
```

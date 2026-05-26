# Pattern 04 — Bind variables

## Problem

Code that builds SQL by concatenating literals — common in legacy reporting tools and naive DAOs — generates a unique cursor for every parameter combination. Symptoms:

- Shared pool fills with near-identical cursors that differ only in literals.
- `ORA-04031` (out of shared memory) starts firing under load.
- AWR reports show **"hard parse"** dominating CPU time.
- Same query at the same parameters runs in 5ms one minute and 2s the next.

## Pattern

Use bind variables in dynamic SQL so the optimizer parses once and reuses the plan.

```plsql
-- BAD: literal concatenation produces N cursors for N customer ids
EXECUTE IMMEDIATE
    'SELECT SUM(outstanding_amount) FROM exposures WHERE customer_id = ' || p_customer_id
    INTO l_amount;

-- GOOD: one cursor, reused by every customer
EXECUTE IMMEDIATE
    'SELECT SUM(outstanding_amount) FROM exposures WHERE customer_id = :id'
    INTO l_amount
    USING p_customer_id;
```

For static SQL inside PL/SQL, Oracle binds variables for you automatically — `WHERE customer_id = p_customer_id` is already safe. The pattern matters specifically for `EXECUTE IMMEDIATE` and any framework that builds SQL from strings.

## Diagnostic: count cursor versions

```sql
SELECT sql_text, executions, parse_calls
FROM   v$sql
WHERE  sql_text LIKE '%exposures%customer_id%'
ORDER  BY parse_calls DESC;
```

If you see hundreds of rows that differ only in a number, you have a literal-concatenation problem.

## Run the demo

```sql
@patterns/04-bind-variables/sql/demo.sql
```

The demo runs 100 lookups two ways — once with literals, once with binds — and shows the cursor count from `V$SQL` for each pattern. Literal-concat creates 100 cursors; bind-variable creates 1.

## Tuning notes

- **`CURSOR_SHARING=FORCE`** is a band-aid that makes Oracle replace literals with binds at parse time. Useful as a stopgap; not a substitute for fixing the code.
- **Bind peeking + adaptive cursor sharing** lets Oracle generate multiple plans for skewed predicates (the famous "histograms" case). Modern Oracle handles this well; ancient code that worked around it is often counter-productive now.
- **SQL injection follows the same fix.** Concatenating user input into SQL is the security version of the same bug. Always use binds.

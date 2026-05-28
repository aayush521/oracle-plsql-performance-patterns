# Contributing

Thanks for considering a contribution. This repo collects production-grade
Oracle PL/SQL performance patterns. Quality and clarity matter more than
quantity — a well-explained existing pattern with a sharper benchmark is
worth more than three mediocre new ones.

## Adding a new pattern

Each pattern lives in its own folder under `patterns/`. The CI workflow
enforces the layout, so follow it strictly.

### Directory layout

```
patterns/NN-pattern-name/
├── README.md            # Explanation, when-to-use, tuning notes
└── sql/
    └── demo.sql         # Runnable, idempotent demo
    └── benchmark.sql    # OPTIONAL — before/after comparison
```

The `NN-` prefix is a 2-digit zero-padded sequence number that controls the
order patterns are presented in the main README's table.

### Required content in `README.md`

1. **Problem** — what production pain this pattern addresses
2. **Pattern** — the actual technique with a copy-paste SQL snippet
3. **Run the demo** — exact SQL*Plus / sqlcl commands to execute
4. **Tuning notes** — gotchas, version-specific behavior, and when NOT to use it

### Required content in `demo.sql`

- **Idempotent** — re-running the demo on the same instance should leave the
  schema in a known state
- **Self-cleaning** — temporary objects must be dropped or replaced safely
- **Uses the demo schema** in `schema/sql/01-create-schema.sql` — don't
  assume any extra tables exist
- **Follows SQL*Plus conventions** — `PROMPT`, `SET SERVEROUTPUT ON`, and
  `/` to terminate PL/SQL blocks

### Don't forget

- Update the patterns table in the main `README.md`
- Add a step to `scripts/run-all.sql` so the new pattern is exercised by the
  full walk-through

## Testing your pattern

There is no automated SQL test runner — Oracle Free / Autonomous Free is
required to actually run the demos. The CI workflow only validates the
structural layout (every pattern has README + sql/demo.sql, every PL/SQL
block ends with `/`).

Run your demo manually against an Oracle 19c+ instance and confirm:

- It completes without errors
- Re-running it produces the same end state
- Plans (visible via `EXPLAIN PLAN` or `DBMS_XPLAN.DISPLAY_CURSOR`) match the
  behaviour described in your README

## Style

- Use `BULK COLLECT INTO` + `LIMIT` over row-by-row cursors
- Prefer set-based SQL over procedural PL/SQL where it expresses the same logic
- Call out partition pruning, index usage, and hint usage explicitly in the README

## Filing issues

If a pattern doesn't work on your version of Oracle, open an issue with:

- Oracle version (`SELECT banner FROM v$version;`)
- The exact SQL that failed
- Error message(s) and any relevant trace output

Suggestions for new patterns are also welcome — open an issue with a problem
statement and a sketch of the technique before opening a PR.

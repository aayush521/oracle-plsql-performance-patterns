-- =============================================================
-- Demo schema for the PL/SQL performance patterns repo.
-- Models a stripped-down banking exposures table — the kind of
-- shape we used in IFRS 9 / Expected Credit Loss batches.
--
-- Run as a privileged user that can create tables in the current
-- schema. Idempotent.
-- =============================================================

PROMPT === Creating demo schema objects ===

-- Drop in case of a previous run
BEGIN
    FOR rec IN (
        SELECT table_name FROM user_tables
        WHERE table_name IN ('EXPOSURES','EXPOSURES_STAGED','CUSTOMERS')
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || rec.table_name || ' CASCADE CONSTRAINTS PURGE';
    END LOOP;
END;
/

CREATE TABLE customers (
    customer_id     NUMBER          PRIMARY KEY,
    customer_name   VARCHAR2(120)   NOT NULL,
    risk_rating     VARCHAR2(2)     NOT NULL,           -- AA, A, BB, B, CC, ...
    country_code    VARCHAR2(3)     NOT NULL,
    onboarded_at    DATE            NOT NULL
);

CREATE TABLE exposures (
    exposure_id         NUMBER          PRIMARY KEY,
    customer_id         NUMBER          NOT NULL REFERENCES customers,
    reporting_date      DATE            NOT NULL,
    product_code        VARCHAR2(10)    NOT NULL,       -- LOAN, CARD, MTG, ...
    outstanding_amount  NUMBER(18,2)    NOT NULL,
    days_past_due       NUMBER(5)       NOT NULL,
    stage               NUMBER(1)       NOT NULL,       -- 1, 2, 3 (IFRS 9 stages)
    ecl_amount          NUMBER(18,2)
);

CREATE TABLE exposures_staged (
    exposure_id         NUMBER          PRIMARY KEY,
    reporting_date      DATE            NOT NULL,
    new_stage           NUMBER(1)       NOT NULL,
    new_ecl_amount      NUMBER(18,2)    NOT NULL,
    processed_at        TIMESTAMP       DEFAULT SYSTIMESTAMP
);

PROMPT === Schema created: customers, exposures, exposures_staged ===

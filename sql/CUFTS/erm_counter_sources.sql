CREATE TABLE erm_counter_sources (
    id              SERIAL PRIMARY KEY,
    site            INTEGER NOT NULL,
    name            VARCHAR(255) NOT NULL,
    reference       VARCHAR(255),
    type            CHAR(1),
    erm_sushi       INTEGER,
    
    next_run_date   DATE,
    run_start_date  DATE,
    run_end_date    DATE,
    interval_months INTEGER,
    
    last_run_timestamp TIMESTAMP
);

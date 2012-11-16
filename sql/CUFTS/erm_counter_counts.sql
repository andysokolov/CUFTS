CREATE TABLE erm_counter_counts (
    id                SERIAL PRIMARY KEY,
    counter_source    INTEGER NOT NULL,
    counter_title     INTEGER NOT NULL,
    start_date        DATE NOT NULL,
    end_date          DATE NOT NULL,
    type              VARCHAR(255) NOT NULL,
    count             INTEGER NOT NULL DEFAULT 0,
    timestamp         TIMESTAMP DEFAULT NOW()
);

CREATE INDEX erm_counter_counts_source_idx ON erm_counter_counts (counter_source);

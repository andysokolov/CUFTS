CREATE TABLE erm_costs (
    id                 SERIAL PRIMARY KEY,
    erm_main           INTEGER NOT NULL,
    date               DATE,
    invoice            NUMERIC(10,2),
    invoice_currency   VARCHAR(3),
    paid               NUMERIC(10,2),
    paid_currency      VARCHAR(3),
    period_start       DATE,
    period_end         DATE,
    number             VARCHAR(256),
    reference          VARCHAR(256),
    order_number       VARCHAR(256)
);

CREATE INDEX erm_costs_main_idx ON erm_costs (erm_main);

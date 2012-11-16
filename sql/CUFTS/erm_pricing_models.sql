CREATE TABLE erm_pricing_models (
    id              SERIAL PRIMARY KEY,
    site            INTEGER,
    pricing_model   VARCHAR(1024)
);

CREATE INDEX erm_pricing_models_site_idx ON erm_pricing_models (site);
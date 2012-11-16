-- cost base table change

DROP TABLE erm_cost_bases;

CREATE TABLE erm_pricing_models (
    id              SERIAL PRIMARY KEY,
    site            INTEGER,
    pricing_model   VARCHAR(1024)
);

CREATE INDEX erm_pricing_models_site_idx ON erm_pricing_models (site);

ALTER TABLE erm_main DROP COLUMN pricing_model;
ALTER TABLE erm_main RENAME COLUMN cost_base TO pricing_model;
ALTER TABLE erm_main RENAME COLUMN cost_base_notes TO pricing_model_notes;
ALTER TABLE erm_main ADD COLUMN pst_amount VARCHAR(1024);
ALTER TABLE erm_main ADD COLUMN gst_amount VARCHAR(1024);
ALTER TABLE erm_main ADD COLUMN journal_auth INTEGER;
ALTER TABLE erm_main ADD COLUMN issn VARCHAR(1024);
ALTER TABLE erm_main ADD COLUMN isbn VARCHAR(1024);
ALTER TABLE erm_main ADD COLUMN invoice_amount VARCHAR(1024);
ALTER TABLE erm_main ADD COLUMN currency VARCHAR(3);
ALTER TABLE erm_main ADD COLUMN print_included BOOLEAN;

ALTER TABLE sites ADD COLUMN erm_patron_fields VARCHAR(8192);
ALTER TABLE sites ADD COLUMN erm_staff_fields VARCHAR(8192);
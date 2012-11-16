CREATE TABLE erm_consortia (
    id          SERIAL PRIMARY KEY,
    site        INTEGER,
    consortia   VARCHAR(1024)
);

CREATE INDEX erm_consortia_site_idx ON erm_consortia (site);
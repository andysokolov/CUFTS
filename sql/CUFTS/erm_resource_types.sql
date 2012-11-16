CREATE TABLE erm_resource_types (
    id              SERIAL PRIMARY KEY,
    site            INTEGER,
    resource_type   VARCHAR(1024)
);

CREATE INDEX erm_resource_types_site_idx ON erm_resource_types (site);
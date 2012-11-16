CREATE TABLE erm_resource_mediums (
    id              SERIAL PRIMARY KEY,
    site            INTEGER,
    resource_medium VARCHAR(1024)
);

CREATE INDEX erm_resource_mediums_site_idx ON erm_resource_mediums (site);
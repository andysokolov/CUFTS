CREATE TABLE erm_content_types (
    id              SERIAL PRIMARY KEY,
    site            INTEGER,
    content_type    VARCHAR(1024)
);

CREATE INDEX erm_content_types_site_idx ON erm_content_types (site);
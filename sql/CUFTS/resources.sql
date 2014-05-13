CREATE TABLE resources (
    id            SERIAL PRIMARY KEY,

    key              VARCHAR(256),
    name             VARCHAR(256) NOT NULL,

    resource_type    INTEGER NOT NULL,    /* id for resource type */

    provider         VARCHAR(256),
    module           VARCHAR(256) NOT NULL,

    active           BOOLEAN NOT NULL DEFAULT TRUE,

    title_list_scanned    TIMESTAMP,
    title_count           INTEGER DEFAULT 0,
    update_months         INTEGER,
    next_update           DATE,

    resource_identifier VARCHAR(256),
    database_url        VARCHAR(1024),
    auth_name           VARCHAR(256),
    auth_passwd         VARCHAR(256),
    url_base            VARCHAR(1024),
    proxy_suffix        VARCHAR(1024),

    notes_for_local     TEXT,
    cjdb_note           TEXT,

    created     TIMESTAMP NOT NULL DEFAULT NOW(),
    modified    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX resources_key_idx ON resources (key);

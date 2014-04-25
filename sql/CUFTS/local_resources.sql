CREATE TABLE local_resources (
    id                      SERIAL PRIMARY KEY,
    site                    INTEGER NOT NULL,

    name                    VARCHAR(256),

    resource                INTEGER,   /* id for a global resource */

    provider                VARCHAR(256),

    resource_type           INTEGER,        /* id for resource type */

    proxy                   BOOLEAN NOT NULL DEFAULT FALSE,  /* Proxy this resource? */
    dedupe                  BOOLEAN NOT NULL DEFAULT FALSE,  /* Dedupe this resource? */
    auto_activate           BOOLEAN NOT NULL DEFAULT FALSE,  /* Autoactivate all titles? */

    rank                    INTEGER DEFAULT 0,

    module                  VARCHAR(256),

    active                  BOOLEAN NOT NULL DEFAULT TRUE,


    resource_identifier     VARCHAR(256),
    database_url            VARCHAR(1024),
    auth_name               VARCHAR(256),
    auth_passwd             VARCHAR(256),
    url_base                VARCHAR(1024),
    proxy_suffix            VARCHAR(1024),

    cjdb_note               TEXT,

    erm_main                INTEGER,

    erm_basic_name                      VARCHAR(256),
    erm_basic_vendor                    VARCHAR(256),
    erm_basic_publisher                 VARCHAR(256),
    erm_basic_subscription_notes        TEXT,

    erm_datescosts_cost                 VARCHAR(256),
    erm_datescosts_contract_end         VARCHAR(256),
    erm_datescosts_renewal_notification VARCHAR(256),
    erm_datescosts_notification_email   VARCHAR(256),
    erm_datescosts_local_fund           VARCHAR(256),
    erm_datescosts_local_acquisitions   VARCHAR(256),
    erm_datescosts_consortia            VARCHAR(256),
    erm_datescosts_consortia_notes      TEXT,
    erm_datescosts_notes                TEXT,

    erm_statistics_notes                TEXT,

    erm_admin_notes			TEXT,

    erm_terms_simultaneous_users        VARCHAR(256),
    erm_terms_allows_ill                VARCHAR(256),
    erm_terms_ill_notes                 TEXT,
    erm_terms_allows_ereserves          VARCHAR(256),
    erm_terms_ereserves_notes           TEXT,
    erm_terms_allows_coursepacks        VARCHAR(256),
    erm_terms_coursepacks_notes         TEXT,
    erm_terms_notes                     TEXT,

    erm_contacts_notes                  TEXT,

    erm_misc_notes                      TEXT,

    title_list_scanned      TIMESTAMP,

    created                 TIMESTAMP NOT NULL DEFAULT NOW(),
    modified                TIMESTAMP NOT NULL DEFAULT NOW()
);


CREATE INDEX local_resources_site_idx ON local_resources(site);
CREATE UNIQUE INDEX local_resources_res_site_idx ON local_resources(resource,site) WHERE resources IS NOT NULL;

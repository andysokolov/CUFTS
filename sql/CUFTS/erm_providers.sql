CREATE TABLE erm_providers (
    id          SERIAL PRIMARY KEY,
    key         VARCHAR(1024),
    site        INTEGER NOT NULL,

    provider_name           VARCHAR(1024),
    local_provider_name     VARCHAR(1024),

    admin_user              VARCHAR(1024),
    admin_password          VARCHAR(1024),
    admin_url               VARCHAR(1024),
    support_url             VARCHAR(1024),
    
    stats_available         BOOLEAN,
    stats_url               VARCHAR(1024),  -- will this cover the SUSHI stuff, or do we need more info for SUSHI?
    stats_frequency         VARCHAR(1024),
    stats_delivery          VARCHAR(1024),
    stats_counter           BOOLEAN,
    stats_user              VARCHAR(1024),
    stats_password          VARCHAR(1024),
    stats_notes             TEXT,

    provider_contact        TEXT,
    provider_notes          TEXT,
    
    support_email           VARCHAR(1024),
    support_phone           VARCHAR(1024),
    knowledgebase           VARCHAR(1024),
    customer_number         VARCHAR(1024)

);


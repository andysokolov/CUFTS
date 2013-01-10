CREATE TABLE erm_main (
    id          SERIAL PRIMARY KEY,
    key         VARCHAR(1024),
    
    site        INTEGER NOT NULL,
    license     INTEGER,   -- linked table (erm_license)
    provider    INTEGER,   -- linked table (erm_providers)
    
    counter_source    INTEGER,   -- linked table (erm_counter_sources)
    
    
-- Resource Information

    internal_name       VARCHAR(1024),
    vendor              VARCHAR(1024),
    publisher           VARCHAR(1024),
    url                 VARCHAR(1024),
    access              VARCHAR(1024),
    resource_type       INTEGER,        -- linked table (erm_resource_types)
    resource_medium     INTEGER,        -- linked table (erm_resource_mediums)
    file_type           VARCHAR(255),
    description_brief   TEXT,
    description_full    TEXT,
    
    update_frequency    VARCHAR(1024),
    coverage            VARCHAR(1024),
    embargo_period      VARCHAR(1024),
    simultaneous_users  VARCHAR(1024),
    proxy               BOOLEAN,
    public_list         BOOLEAN,
    public              BOOLEAN,
    public_message      TEXT,
    group_records       VARCHAR(1024),
    active_alert        VARCHAR(1024),
    print_equivalents   TEXT,
    alert               TEXT,
    alert_expiry        DATE,

    pick_and_choose     BOOLEAN,
    marc_available      BOOLEAN,
    marc_history        TEXT,
    marc_alert          VARCHAR(1024),
    marc_notes 		TEXT,
    marc_schedule 	DATE,
    marc_schedule_interval INT DEFAULT 0,

    requirements        TEXT,
    maintenance         TEXT,
    title_list_url      VARCHAR(1024),
    help_url            VARCHAR(1024),
    status_url          VARCHAR(1024),
    resolver_enabled    BOOLEAN,
    refworks_compatible BOOLEAN,
    refworks_info_url   VARCHAR(1024),
    user_documentation  TEXT,
    
    subscription_type            VARCHAR(1024),
    subscription_status          VARCHAR(1024),
    print_included               BOOLEAN,
    subscription_notes           TEXT,
    subscription_ownership       VARCHAR(1024),
    subscription_ownership_notes TEXT,
    cancellation_cap             BOOLEAN,
    cancellation_cap_notes       TEXT,
    
    issn        VARCHAR(1024),
    isbn        VARCHAR(1024),
    
    misc_notes          TEXT,
    
-- Dates and Costs

    cost                    VARCHAR(1024),
    invoice_amount          VARCHAR(1024),
    currency                VARCHAR(3),
    pricing_model           INTEGER,        -- linked table (erm_pricing_model)
    pricing_model_notes     TEXT,
    gst                     BOOLEAN,
    pst                     BOOLEAN,
    gst_amount              VARCHAR(1024),
    pst_amount              VARCHAR(1024),
    payment_status          VARCHAR(1024),
    order_date              DATE,
    contract_start          DATE,
    contract_end            DATE,
    original_term           VARCHAR(1024),
    auto_renew              BOOLEAN,
    renewal_notification    INTEGER,
    notification_email      VARCHAR(1024),
    notice_to_cancel        INTEGER,
    requires_review         BOOLEAN,
    review_by               VARCHAR(1024),
    review_notes            TEXT,
    local_bib               VARCHAR(1024),
    local_customer          VARCHAR(1024),
    local_vendor            VARCHAR(1024),
    local_vendor_code       VARCHAR(1024),
    local_acquisitions      VARCHAR(1024),
    local_fund              VARCHAR(1024),
    journal_auth            INTEGER,
    consortia               INTEGER,        -- linked table (erm_consortia)
    consortia_notes         TEXT,
    date_cost_notes         TEXT,
    subscription            VARCHAR(1024),
    price_cap               VARCHAR(1024),
    license_start_date      DATE,
    
    
-- Statistics

    stats_available         BOOLEAN,
    stats_url               VARCHAR(1024),  -- will this cover the SUSHI stuff, or do we need more info for SUSHI?
    stats_frequency         VARCHAR(1024),
    stats_delivery          VARCHAR(1024),
    stats_counter           BOOLEAN,
    stats_user              VARCHAR(1024),
    stats_password          VARCHAR(1024),
    stats_notes             TEXT,
    counter_stats           BOOLEAN,

-- Admin

    open_access             VARCHAR(1024),
    admin_subscription_no   VARCHAR(1024),
    admin_user              VARCHAR(1024),
    admin_password          VARCHAR(1024),
    admin_url               VARCHAR(1024),
    support_url             VARCHAR(1024),
    access_url              VARCHAR(1024),
    public_account_needed   BOOLEAN,
    public_user             VARCHAR(1024),
    public_password         VARCHAR(1024),
    training_user           VARCHAR(1024),
    training_password       VARCHAR(1024),
    marc_url                VARCHAR(1024),   -- should this live up with the other marc stuff?
    ip_authentication       BOOLEAN,
    referrer_authentication BOOLEAN,
    referrer_url            VARCHAR(1024),
    openurl_compliant       BOOLEAN,
    access_notes            TEXT,
    breaches                TEXT,
    admin_notes             TEXT,
    
-- Provder

    provider_name           VARCHAR(1024),
    local_provider_name     VARCHAR(1024),

    provider_contact        TEXT,
    provider_notes          TEXT,

    support_email           VARCHAR(1024),
    support_phone           VARCHAR(1024),
    knowledgebase           VARCHAR(1024),
    customer_number         VARCHAR(1024)
);


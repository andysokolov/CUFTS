CREATE TABLE erm_license (
        id          SERIAL PRIMARY KEY,
        key         VARCHAR(1024),
        site        INTEGER NOT NULL,

    -- Terms

        full_on_campus_access   BOOLEAN,
        full_on_campus_notes    TEXT,
        allows_remote_access    BOOLEAN,
        allows_proxy_access     BOOLEAN,
        allows_commercial_use   BOOLEAN,
        allows_walkins          BOOLEAN,
        allows_ill              BOOLEAN,
        ill_notes               TEXT,
        allows_ereserves        BOOLEAN,
        ereserves_notes         TEXT,
        allows_coursepacks      BOOLEAN,
        coursepack_notes        TEXT,
        allows_distance_ed      BOOLEAN,
        allows_downloads        BOOLEAN,
        allows_prints           BOOLEAN,
        allows_emails           BOOLEAN,
        emails_notes            TEXT,
        allows_archiving        BOOLEAN,
        archiving_notes         TEXT,
        own_data                BOOLEAN,
        citation_requirements   VARCHAR(2048),
        requires_print          BOOLEAN,
        requires_print_plus     BOOLEAN,
        additional_requirements TEXT,
        allowable_downtime      VARCHAR(2048),
        online_terms            VARCHAR(2048),
        user_restrictions       TEXT,
        terms_notes             TEXT,
        termination_requirements TEXT,
        perpetual_access        BOOLEAN,
        perpetual_access_notes  TEXT,
        

    -- Contacts

        contact_name            VARCHAR(2048),
        contact_role            VARCHAR(2048),
        contact_address         VARCHAR(2048),
        contact_phone           VARCHAR(2048),
        contact_fax             VARCHAR(2048),
        contact_email           VARCHAR(2048),
        contact_notes           TEXT

);

CREATE INDEX erm_license_site_idx ON erm_license ( site );
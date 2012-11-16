CREATE TABLE local_journals (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(1024),
    issn            VARCHAR(8),        /* ISSN with no dash */
    e_issn          VARCHAR(8),        /* Electronic ISSN if one exists (no dash) */

    resource        INTEGER NOT NULL,    /* id for local resource journal is in */
    journal         INTEGER,        /* id for a record in the journal table if relevant */

    active          BOOLEAN NOT NULL DEFAULT true,
    
    vol_cit_start   VARCHAR(128),        /* Starting volume for citations */
    vol_cit_end     VARCHAR(128),        /* Ending volume for citations */
    vol_ft_start    VARCHAR(128),        /* Starting volume for fulltext */
    vol_ft_end      VARCHAR(128),        /* Ending volume for fulltext */

    iss_cit_start   VARCHAR(128),        /* Starting issue for citations */
    iss_cit_end     VARCHAR(128),        /* Ending issue for citations */
    iss_ft_start    VARCHAR(128),        /* Starting issue for fulltext */
    iss_ft_end      VARCHAR(128),        /* Ending issue for fulltext */

    cit_start_date  DATE,            /* Starting date for citations */
    cit_end_date    DATE,            /* Ending date for citations */
    ft_start_date   DATE,            /* Starting date for fulltext */
    ft_end_date     DATE,            /* Ending date for fulltext */

    embargo_months  INTEGER,        /* Number of months title is embargoed */
    embargo_days    INTEGER,        /* Number of days title is embargoed */

    journal_auth    INTEGER,
    
    db_identifier   VARCHAR(256),   /* code used to identify the journal within the vendor's database */
    toc_url         VARCHAR(1024),  /* URL for the table of contents */
    journal_url     VARCHAR(1024),  /* URL for the journal */
    urlbase         VARCHAR(1024),  /* URL base used for creating links */
    publisher       VARCHAR(1024),  /* Journal publisher */
    abbreviation    VARCHAR(1024),  /* Journal abbreviation */
    coverage        VARCHAR(1024),  /* Freetext coverage description if start/end dates are not usable */

    current_months  VARCHAR(256),   /* Months of moving wall access to current issues */
    current_years   VARCHAR(256),   /* Years of moving wall access to current issues */
    cjdb_note       TEXT,           /* Note to display in CJDB (global may not be used, local only) */
    local_note      TEXT,           /* Note to display in editing tool, meant for local use only (but can be edited at global level) */

    erm_main        INTEGER,

    created        TIMESTAMP NOT NULL DEFAULT NOW(),
    scanned        TIMESTAMP NOT NULL DEFAULT NOW(),
    modified       TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX local_journals_issn_idx ON local_journals (issn) WHERE issn IS NOT NULL;
CREATE INDEX local_journals_title_idx ON local_journals (title) WHERE title IS NOT NULL;
CREATE INDEX local_journals_e_issn_idx ON local_journals (e_issn) WHERE e_issn IS NOT NULL;
CREATE INDEX local_journals_r_idx ON local_journals (resource);
CREATE INDEX local_journals_j_idx ON local_journals (journal);
CREATE UNIQUE INDEX local_journals_r_j_idx ON local_journals (resource, journal) WHERE journal IS NOT NULL;
CREATE INDEX local_journals_ja_index ON local_journals (journal_auth) WHERE journal_auth IS NOT NULL;
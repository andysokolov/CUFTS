CREATE TABLE erm_content_types_main (
    id            SERIAL PRIMARY KEY,
    erm_main      INTEGER NOT NULL,
    content_type  INTEGER NOT NULL
);

CREATE INDEX erm_content_types_main_c_idx ON erm_content_types_main ( content_type );
CREATE UNIQUE INDEX erm_content_types_main_cm_idx ON erm_content_types_main ( erm_main, content_type );

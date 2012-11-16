CREATE TABLE erm_display_fields (
    id            SERIAL PRIMARY KEY,
    site          INTEGER NOT NULL,
    field         VARCHAR(128),
    staff_view    BOOLEAN DEFAULT false,
    staff_edit    BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0
);

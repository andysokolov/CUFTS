ALTER TABLE sites ALTER google_scholar_on TYPE bool USING CASE WHEN google_scholar_on LIKE '1' THEN TRUE ELSE FALSE END;
ALTER TABLE sites ALTER COLUMN google_scholar_on SET DEFAULT FALSE;

ALTER TABLE sites ALTER cjdb_show_citations TYPE bool USING CASE WHEN cjdb_show_citations LIKE '1' OR cjdb_show_citations LIKE 'true' THEN TRUE ELSE FALSE END;
ALTER TABLE sites ALTER COLUMN cjdb_show_citations SET DEFAULT FALSE;

ALTER TABLE sites ALTER cjdb_display_db_name_only TYPE bool USING CASE WHEN cjdb_display_db_name_only LIKE '1' OR cjdb_display_db_name_only LIKE 'true' THEN TRUE ELSE FALSE END;
ALTER TABLE sites ALTER COLUMN cjdb_display_db_name_only SET DEFAULT FALSE;

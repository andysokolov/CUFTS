ALTER TABLE erm_main ADD COLUMN marc_records_url VARCHAR(1024);
ALTER TABLE erm_main ADD COLUMN marc_notes TEXT;
ALTER TABLE erm_main ADD COLUMN marc_schedule DATE;
ALTER TABLE erm_main ADD COLUMN marc_schedule_interval INT DEFAULT 0;

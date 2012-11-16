ALTER TABLE erm_sushi DROP COLUMN interval_months;
ALTER TABLE erm_counter_sources ADD COLUMN interval_months INT default 1;
ALTER TABLE erm_counter_sources DROP COLUMN run_end_date;
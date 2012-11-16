DROP VIEW journals_active;
DROP VIEW merged_journals;

ALTER TABLE journals ADD COLUMN local_note VARCHAR(1024);
ALTER TABLE local_journals ADD COLUMN local_note VARCHAR(1024);


CREATE VIEW journals_active AS
SELECT local_journals.resource as local_resource, 
       journals.id,
       journals.title,
       journals.issn,
       journals.e_issn,
       journals.resource,
       journals.vol_cit_start,
       journals.vol_cit_end,
       journals.vol_ft_start,
       journals.vol_ft_end,
       journals.iss_cit_start,
       journals.iss_cit_end,
       journals.iss_ft_start,
       journals.iss_ft_end,
       journals.cit_start_date,
       journals.cit_end_date,
       journals.ft_start_date,
       journals.ft_end_date,
       journals.embargo_months,
       journals.embargo_days,
       journals.journal_auth,
       journals.created,
       journals.scanned,
       journals.modified,
       journals.db_identifier,
       journals.toc_url,
       journals.journal_url,
       journals.urlbase,
       journals.publisher,
       journals.abbreviation,
       journals.current_months,
       journals.current_years,
       journals.cjdb_note,
       journals.local_note,
       journals.coverage
FROM (journals JOIN local_journals ON ((local_journals.journal = journals.id))) 
WHERE (local_journals.active = true);

CREATE VIEW merged_journals AS
SELECT local_journals.id AS id,
       local_resources.id AS local_resource,
       resources.id AS global_resource,
       COALESCE( local_resources.name, resources.name ) AS resource_name,
       local_resources.site AS site,
       local_resources.active AS active,
       COALESCE( local_journals.title, journals.title ) AS title,
       COALESCE( local_journals.issn, journals.issn ) AS issn,
       COALESCE( local_journals.e_issn, journals.e_issn ) AS e_issn,
       local_journals.cjdb_note,
       COALESCE( local_journals.vol_cit_start, journals.vol_cit_start ) AS vol_cit_start,
       COALESCE( local_journals.vol_cit_end, journals.vol_cit_end ) AS vol_cit_end,
       COALESCE( local_journals.vol_ft_end, journals.vol_ft_end ) AS vol_ft_end,
       COALESCE( local_journals.vol_ft_start, journals.vol_ft_start ) AS vol_ft_start,
       COALESCE( local_journals.iss_cit_start, journals.iss_cit_start ) AS iss_cit_start,
       COALESCE( local_journals.iss_cit_end, journals.iss_cit_end ) AS iss_cit_end,
       COALESCE( local_journals.iss_ft_end, journals.iss_ft_end ) AS iss_ft_end,
       COALESCE( local_journals.iss_ft_start, journals.iss_ft_start ) AS iss_ft_start,
       COALESCE( local_journals.cit_start_date, journals.cit_start_date ) AS cit_start_date,
       COALESCE( local_journals.cit_end_date, journals.cit_end_date ) AS cit_end_date,
       COALESCE( local_journals.ft_start_date, journals.ft_start_date ) AS ft_start_date,
       COALESCE( local_journals.ft_end_date, journals.ft_end_date ) AS ft_end_date,
       COALESCE( local_journals.embargo_months, journals.embargo_months ) AS embargo_months,
       COALESCE( local_journals.embargo_days, journals.embargo_days ) AS embargo_days,
       COALESCE( local_journals.journal_auth, journals.journal_auth ) AS journal_auth,
       COALESCE( local_journals.db_identifier, journals.db_identifier ) AS db_identifier,
       COALESCE( local_journals.toc_url, journals.toc_url ) AS toc_url,
       COALESCE( local_journals.journal_url, journals.journal_url ) AS journal_url,
       COALESCE( local_journals.urlbase, journals.urlbase ) AS urlbase,
       COALESCE( local_journals.publisher, journals.publisher ) AS publisher,
       COALESCE( local_journals.abbreviation, journals.abbreviation ) AS abbreviation,
       COALESCE( local_journals.current_months, journals.current_months ) AS current_months,
       COALESCE( local_journals.current_years, journals.current_years ) AS current_years,
       COALESCE( local_journals.coverage, journals.coverage ) AS coverage,
       COALESCE( local_journals.local_note, journals.local_note ) AS local_note,
       local_journals.erm_main AS erm_main,
       erm_main.key AS erm_main_key

FROM local_journals
LEFT OUTER JOIN journals ON ( local_journals.journal = journals.id )
JOIN local_resources ON ( local_resources.id = local_journals.resource )
LEFT OUTER JOIN resources ON ( local_resources.resource = resources.id )
LEFT OUTER JOIN erm_main ON ( local_journals.erm_main = erm_main.id )
;

ALTER TABLE local_resources ADD COLUMN cjdb_note VARCHAR(256);
ALTER TABLE resources ADD COLUMN cjdb_note VARCHAR(256);

UPDATE resources SET cjdb_note = resource_details.value FROM resource_details WHERE resource_details.resource = resources.id AND field = 'cjdb_note';
UPDATE local_resources SET cjdb_note = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'cjdb_note';

ALTER TABLE resources ADD COLUMN notes_for_local VARCHAR(256);
UPDATE resources SET notes_for_local = resource_details.value FROM resource_details WHERE resource_details.resource = resources.id AND field = 'notes_for_local';


ALTER TABLE local_resources ADD COLUMN erm_basic_name VARCHAR(256);
UPDATE local_resources SET erm_basic_name = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_basic_name';

ALTER TABLE local_resources ADD COLUMN erm_basic_vendor VARCHAR(256);
UPDATE local_resources SET erm_basic_vendor = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_basic_vendor';

ALTER TABLE local_resources ADD COLUMN erm_basic_publisher VARCHAR(256);
UPDATE local_resources SET erm_basic_publisher = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_basic_publisher';

ALTER TABLE local_resources ADD COLUMN erm_basic_subscription_notes TEXT;
UPDATE local_resources SET erm_basic_subscription_notes = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_basic_subscription_notes';

ALTER TABLE local_resources ADD COLUMN erm_datescosts_cost VARCHAR(256);
UPDATE local_resources SET erm_datescosts_cost = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_datescosts_cost';

ALTER TABLE local_resources ADD COLUMN erm_datescosts_contract_end VARCHAR(256);
UPDATE local_resources SET erm_datescosts_contract_end = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_datescosts_contract_end';

ALTER TABLE local_resources ADD COLUMN erm_datescosts_renewal_notification VARCHAR(256);
UPDATE local_resources SET erm_datescosts_renewal_notification = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_datescosts_renewal_notification';

ALTER TABLE local_resources ADD COLUMN erm_datescosts_notification_email VARCHAR(256);
UPDATE local_resources SET erm_datescosts_notification_email = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_datescosts_notification_email';

ALTER TABLE local_resources ADD COLUMN erm_datescosts_local_fund VARCHAR(256);
UPDATE local_resources SET erm_datescosts_local_fund = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_datescosts_notification_email';

ALTER TABLE local_resources ADD COLUMN erm_datescosts_local_acquisitions VARCHAR(256);
UPDATE local_resources SET erm_datescosts_local_acquisitions = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_datescosts_local_acquisitions';

ALTER TABLE local_resources ADD COLUMN erm_datescosts_consortia VARCHAR(256);
UPDATE local_resources SET erm_datescosts_consortia = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_datescosts_consortia';

ALTER TABLE local_resources ADD COLUMN erm_datescosts_consortia_notes TEXT;
UPDATE local_resources SET erm_datescosts_consortia_notes = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_datescosts_consortia_notes';

ALTER TABLE local_resources ADD COLUMN erm_datescosts_notes TEXT;
UPDATE local_resources SET erm_datescosts_notes = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_datescosts_notes';

ALTER TABLE local_resources ADD COLUMN erm_statistics_notes TEXT;
UPDATE local_resources SET erm_statistics_notes = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_statistics_notes';

ALTER TABLE local_resources ADD COLUMN erm_admin_notes TEXT;
UPDATE local_resources SET erm_admin_notes = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_admin_notes';

ALTER TABLE local_resources ADD COLUMN erm_terms_simultaneous_users VARCHAR(256);
UPDATE local_resources SET erm_terms_simultaneous_users = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_terms_simultaneous_users';

ALTER TABLE local_resources ADD COLUMN erm_terms_allows_ill TEXT;
UPDATE local_resources SET erm_terms_allows_ill = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_terms_allows_ill';

ALTER TABLE local_resources ADD COLUMN erm_terms_ill_notes TEXT;
UPDATE local_resources SET erm_terms_ill_notes = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_terms_ill_notes';

ALTER TABLE local_resources ADD COLUMN erm_terms_allows_ereserves VARCHAR(256);
UPDATE local_resources SET erm_terms_allows_ereserves = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_terms_allows_ereserves';

ALTER TABLE local_resources ADD COLUMN erm_terms_ereserves_notes TEXT;
UPDATE local_resources SET erm_terms_ereserves_notes = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_terms_ereserves_notes';

ALTER TABLE local_resources ADD COLUMN erm_terms_allows_coursepacks VARCHAR(256);
UPDATE local_resources SET erm_terms_allows_coursepacks = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_terms_allows_coursepacks';

ALTER TABLE local_resources ADD COLUMN erm_terms_coursepacks_notes TEXT;
UPDATE local_resources SET erm_terms_coursepacks_notes = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_terms_coursepacks_notes';

ALTER TABLE local_resources ADD COLUMN erm_terms_notes TEXT;
UPDATE local_resources SET erm_terms_notes = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_terms_notes';

ALTER TABLE local_resources ADD COLUMN erm_contacts_notes TEXT;
UPDATE local_resources SET erm_contacts_notes = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_contacts_notes';

ALTER TABLE local_resources ADD COLUMN erm_misc_notes TEXT;
UPDATE local_resources SET erm_misc_notes = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'erm_misc_notes';

DROP TABLE local_resource_details;
DROP TABLE resource_details;

ALTER TABLE sites ADD COLUMN cjdb_results_per_page VARCHAR(1024);
UPDATE sites SET cjdb_results_per_page = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_results_per_page';

ALTER TABLE sites ADD COLUMN cjdb_unified_journal_list VARCHAR(1024);
UPDATE sites SET cjdb_unified_journal_list = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_unified_journal_list';

ALTER TABLE sites ADD COLUMN cjdb_show_citations VARCHAR(1024);
UPDATE sites SET cjdb_show_citations = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_show_citations';

ALTER TABLE sites ADD COLUMN cjdb_hide_citation_coverage VARCHAR(1024);
UPDATE sites SET cjdb_hide_citation_coverage = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_hide_citation_coverage';

ALTER TABLE sites ADD COLUMN cjdb_display_db_name_only VARCHAR(1024);
UPDATE sites SET cjdb_display_db_name_only = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_display_db_name_only';

ALTER TABLE sites ADD COLUMN cjdb_print_name VARCHAR(1024);
UPDATE sites SET cjdb_print_name = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_print_name';

ALTER TABLE sites ADD COLUMN cjdb_print_link_label VARCHAR(1024);
UPDATE sites SET cjdb_print_link_label = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_print_link_label';

ALTER TABLE sites ADD COLUMN cjdb_authentication_module VARCHAR(1024);
UPDATE sites SET cjdb_authentication_module = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_authentication_module';

ALTER TABLE sites ADD COLUMN cjdb_authentication_server VARCHAR(1024);
UPDATE sites SET cjdb_authentication_server = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_authentication_server';

ALTER TABLE sites ADD COLUMN cjdb_authentication_string1 VARCHAR(1024);
UPDATE sites SET cjdb_authentication_string1 = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_authentication_string1';

ALTER TABLE sites ADD COLUMN cjdb_authentication_string2 VARCHAR(1024);
UPDATE sites SET cjdb_authentication_string2 = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_authentication_string2';

ALTER TABLE sites ADD COLUMN cjdb_authentication_string3 VARCHAR(1024);
UPDATE sites SET cjdb_authentication_string3 = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_authentication_string3';

ALTER TABLE sites ADD COLUMN cjdb_authentication_level100 VARCHAR(1024);
UPDATE sites SET cjdb_authentication_level100 = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_authentication_level100';

ALTER TABLE sites ADD COLUMN cjdb_authentication_level50 VARCHAR(1024);
UPDATE sites SET cjdb_authentication_level50 = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'cjdb_authentication_level50';

ALTER TABLE sites ADD COLUMN marc_dump_856_link_label VARCHAR(1024);
UPDATE sites SET marc_dump_856_link_label = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'marc_dump_856_link_label';

ALTER TABLE sites ADD COLUMN marc_dump_duplicate_title_field VARCHAR(1024);
UPDATE sites SET marc_dump_duplicate_title_field = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'marc_dump_duplicate_title_field';

ALTER TABLE sites ADD COLUMN marc_dump_cjdb_id_field VARCHAR(1024);
UPDATE sites SET marc_dump_cjdb_id_field = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'marc_dump_cjdb_id_field';

ALTER TABLE sites ADD COLUMN marc_dump_cjdb_id_indicator1 VARCHAR(1024);
UPDATE sites SET marc_dump_cjdb_id_indicator1 = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'marc_dump_cjdb_id_indicator1';

ALTER TABLE sites ADD COLUMN marc_dump_cjdb_id_indicator2 VARCHAR(1024);
UPDATE sites SET marc_dump_cjdb_id_indicator2 = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'marc_dump_cjdb_id_indicator2';

ALTER TABLE sites ADD COLUMN marc_dump_cjdb_id_subfield VARCHAR(1024);
UPDATE sites SET marc_dump_cjdb_id_subfield = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'marc_dump_cjdb_id_subfield';

ALTER TABLE sites ADD COLUMN marc_dump_holdings_field VARCHAR(1024);
UPDATE sites SET marc_dump_holdings_field = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'marc_dump_holdings_field';

ALTER TABLE sites ADD COLUMN marc_dump_holdings_indicator1 VARCHAR(1024);
UPDATE sites SET marc_dump_holdings_indicator1 = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'marc_dump_holdings_indicator1';

ALTER TABLE sites ADD COLUMN marc_dump_holdings_indicator2 VARCHAR(1024);
UPDATE sites SET marc_dump_holdings_indicator2 = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'marc_dump_holdings_indicator2';

ALTER TABLE sites ADD COLUMN marc_dump_holdings_subfield VARCHAR(1024);
UPDATE sites SET marc_dump_holdings_subfield = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'marc_dump_holdings_subfield';

ALTER TABLE sites ADD COLUMN marc_dump_medium_text VARCHAR(1024);
UPDATE sites SET marc_dump_medium_text = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'marc_dump_medium_text';

ALTER TABLE sites ADD COLUMN rebuild_cjdb VARCHAR(1024);
UPDATE sites SET rebuild_cjdb = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'rebuild_cjdb';

ALTER TABLE sites ADD COLUMN rebuild_MARC VARCHAR(1024);
UPDATE sites SET rebuild_MARC = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'rebuild_MARC';

ALTER TABLE sites ADD COLUMN rebuild_ejournals_only VARCHAR(1024);
UPDATE sites SET rebuild_ejournals_only = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'rebuild_ejournals_only';

ALTER TABLE sites ADD COLUMN show_ERM VARCHAR(1024);
UPDATE sites SET show_ERM = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'show_ERM';

ALTER TABLE sites ADD COLUMN test_MARC_file VARCHAR(1024);
UPDATE sites SET test_MARC_file = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'test_MARC_file';

ALTER TABLE sites ADD COLUMN google_scholar_on VARCHAR(1024);
UPDATE sites SET google_scholar_on = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'google_scholar_on';

ALTER TABLE sites ADD COLUMN google_scholar_keywords VARCHAR(1024);
UPDATE sites SET google_scholar_keywords = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'google_scholar_keywords';

ALTER TABLE sites ADD COLUMN google_scholar_e_link_label VARCHAR(1024);
UPDATE sites SET google_scholar_e_link_label = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'google_scholar_e_link_label';

ALTER TABLE sites ADD COLUMN google_scholar_other_link_label VARCHAR(1024);
UPDATE sites SET google_scholar_other_link_label = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'google_scholar_other_link_label';

ALTER TABLE sites ADD COLUMN google_scholar_openurl_base VARCHAR(1024);
UPDATE sites SET google_scholar_openurl_base = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'google_scholar_openurl_base';

ALTER TABLE sites ADD COLUMN google_scholar_other_xml VARCHAR(1024);
UPDATE sites SET google_scholar_other_xml = site_details.value FROM site_details WHERE site_details.site = sites.id AND field = 'google_scholar_other_xml';

DROP TABLE site_details;

ALTER TABLE local_journals ADD COLUMN db_identifier VARCHAR(256);
UPDATE local_journals SET db_identifier  = local_journal_details.value FROM local_journal_details WHERE local_journal_details.local_journal = local_journals.id AND field = 'db_identifier    ';

ALTER TABLE local_journals ADD COLUMN toc_url VARCHAR(1024);
UPDATE local_journals SET toc_url = local_journal_details.value FROM local_journal_details WHERE local_journal_details.local_journal = local_journals.id AND field = 'toc_url';

ALTER TABLE local_journals ADD COLUMN journal_url VARCHAR(1024);
UPDATE local_journals SET journal_url = local_journal_details.value FROM local_journal_details WHERE local_journal_details.local_journal = local_journals.id AND field = 'journal_url';

ALTER TABLE local_journals ADD COLUMN urlbase VARCHAR(1024);
UPDATE local_journals SET urlbase = local_journal_details.value FROM local_journal_details WHERE local_journal_details.local_journal = local_journals.id AND field = 'urlbase';

ALTER TABLE local_journals ADD COLUMN publisher VARCHAR(1024);
UPDATE local_journals SET publisher = local_journal_details.value FROM local_journal_details WHERE local_journal_details.local_journal = local_journals.id AND field = 'publisher';

ALTER TABLE local_journals ADD COLUMN abbreviation VARCHAR(1024);
UPDATE local_journals SET abbreviation = local_journal_details.value FROM local_journal_details WHERE local_journal_details.local_journal = local_journals.id AND field = 'abbreviation';

ALTER TABLE local_journals ADD COLUMN current_months VARCHAR(256);
UPDATE local_journals SET current_months = local_journal_details.value FROM local_journal_details WHERE local_journal_details.local_journal = local_journals.id AND field = 'current_months';

ALTER TABLE local_journals ADD COLUMN current_years VARCHAR(256);
UPDATE local_journals SET current_years = local_journal_details.value FROM local_journal_details WHERE local_journal_details.local_journal = local_journals.id AND field = 'current_years';

ALTER TABLE local_journals ADD COLUMN cjdb_note TEXT;
UPDATE local_journals SET cjdb_note = local_journal_details.value FROM local_journal_details WHERE local_journal_details.local_journal = local_journals.id AND field = 'cjdb_note';

DROP TABLE local_journal_details;

ALTER TABLE journals ADD COLUMN db_identifier VARCHAR(256);
UPDATE journals SET db_identifier = journal_details.value FROM journal_details WHERE journal_details.journal = journals.id AND field = 'db_identifier';

ALTER TABLE journals ADD COLUMN toc_url VARCHAR(1024);
UPDATE journals SET toc_url = journal_details.value FROM journal_details WHERE journal_details.journal = journals.id AND field = 'toc_url';

ALTER TABLE journals ADD COLUMN journal_url VARCHAR(1024);
UPDATE journals SET journal_url = journal_details.value FROM journal_details WHERE journal_details.journal = journals.id AND field = 'journal_url';

ALTER TABLE journals ADD COLUMN urlbase VARCHAR(1024);
UPDATE journals SET urlbase = journal_details.value FROM journal_details WHERE journal_details.journal = journals.id AND field = 'urlbase';

ALTER TABLE journals ADD COLUMN publisher VARCHAR(1024);
UPDATE journals SET publisher = journal_details.value FROM journal_details WHERE journal_details.journal = journals.id AND field = 'publisher';

ALTER TABLE journals ADD COLUMN abbreviation VARCHAR(1024);
UPDATE journals SET abbreviation = journal_details.value FROM journal_details WHERE journal_details.journal = journals.id AND field = 'abbreviation';

ALTER TABLE journals ADD COLUMN current_months VARCHAR(256);
UPDATE journals SET current_months = journal_details.value FROM journal_details WHERE journal_details.journal = journals.id AND field = 'current_months';

ALTER TABLE journals ADD COLUMN current_years VARCHAR(256);
UPDATE journals SET current_years = journal_details.value FROM journal_details WHERE journal_details.journal = journals.id AND field = 'current_years';

ALTER TABLE journals ADD COLUMN cjdb_note TEXT;
UPDATE journals SET cjdb_note = journal_details.value FROM journal_details WHERE journal_details.journal = journals.id AND field = 'cjdb_note';

DROP TABLE journal_details;
-- subjects

ALTER TABLE cjdb_subjects RENAME TO old_cjdb_subjects;

CREATE TABLE cjdb_subjects (
	id SERIAL PRIMARY KEY,
	subject VARCHAR(1024),
	search_subject VARCHAR(1024)
);
CREATE INDEX cjdb_subjects_exact_idx ON cjdb_subjects (search_subject);
CREATE INDEX cjdb_subjects_idx ON cjdb_subjects (search_subject varchar_pattern_ops);

CREATE TABLE cjdb_journals_subjects (
    id SERIAL PRIMARY KEY,
    journal INTEGER NOT NULL,
    site INTEGER NOT NULL,
    subject INTEGER NOT NULL,
    level INTEGER DEFAULT 0,
    origin VARCHAR(1024)
);

CREATE INDEX cjdb_j_s_j_idx ON cjdb_journals_subjects ( journal );
CREATE INDEX cjdb_j_s_ss_idx ON cjdb_journals_subjects ( site, subject );

INSERT INTO cjdb_subjects (subject, search_subject)
SELECT DISTINCT ON ( subject, search_subject) subject, search_subject 
FROM old_cjdb_subjects;

INSERT INTO cjdb_journals_subjects (journal, site, subject, origin)
SELECT journal, site, cjdb_subjects.id, origin
FROM old_cjdb_subjects, cjdb_subjects
WHERE old_cjdb_subjects.subject = cjdb_subjects.subject
AND old_cjdb_subjects.search_subject = cjdb_subjects.search_subject;

-- associations

ALTER TABLE cjdb_associations RENAME TO old_cjdb_associations;

CREATE TABLE cjdb_associations (
	id SERIAL PRIMARY KEY,
	association VARCHAR(1024),
	search_association VARCHAR(1024)
);
CREATE INDEX cjdb_ass_exact_idx ON cjdb_associations (search_association);
CREATE INDEX cjdb_ass_idx ON cjdb_associations (search_association varchar_pattern_ops);

CREATE TABLE cjdb_journals_associations (
    id SERIAL PRIMARY KEY,
    journal INTEGER NOT NULL,
    site INTEGER NOT NULL,
    association INTEGER NOT NULL
);

CREATE INDEX cjdb_j_a_j_idx ON cjdb_journals_associations ( journal );
CREATE INDEX cjdb_j_a_sa_idx ON cjdb_journals_associations ( site, association );

INSERT INTO cjdb_associations (association, search_association)
SELECT DISTINCT ON ( association, search_association) association, search_association 
FROM old_cjdb_associations;

INSERT INTO cjdb_journals_associations (journal, site, association)
SELECT journal, site, cjdb_associations.id
FROM old_cjdb_associations, cjdb_associations
WHERE old_cjdb_associations.association = cjdb_associations.association
AND old_cjdb_associations.search_association = cjdb_associations.search_association;



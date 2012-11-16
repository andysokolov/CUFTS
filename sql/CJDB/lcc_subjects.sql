CREATE TABLE cjdb_lcc_subjects (
	id	SERIAL PRIMARY KEY,
	class_low	VARCHAR(3),
	class_high	VARCHAR(3),
	number_low	NUMERIC(12,6),
	number_high	NUMERIC(12,6),

	subject1	VARCHAR(2048),
	subject2	VARCHAR(2048),
	subject3	VARCHAR(2048),

	site		INTEGER
);



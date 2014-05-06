CREATE TABLE job_queue_log (
    id SERIAL PRIMARY KEY,
    job_id integer,
    account_id integer,
    site_id integer,
    level integer NOT NULL,
    type character varying(128) NOT NULL,
    client_identifier character varying(128),
    message text,
    "timestamp" timestamp without time zone NOT NULL
);

CREATE INDEX job_queue_log_idx_account_id ON job_queue_log USING btree (account_id);
CREATE INDEX job_queue_log_idx_job_id ON job_queue_log USING btree (job_id);
CREATE INDEX job_queue_log_idx_site_id ON job_queue_log USING btree (site_id);

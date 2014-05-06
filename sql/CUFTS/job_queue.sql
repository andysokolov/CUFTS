CREATE TABLE job_queue (
    id SERIAL PRIMARY KEY,
    info text NOT NULL,
    type character varying(128) NOT NULL,
    class character varying(128) NOT NULL,
    account_id integer,
    priority integer DEFAULT 0 NOT NULL,
    site_id integer,
    local_resource_id integer,
    global_resource_id integer,
    status character varying,
    claimed_by character varying,
    completion integer DEFAULT 0,
    data text,
    checkpoint_timestamp timestamp without time zone,
    run_after timestamp without time zone,
    reschedule_hours integer,
    created timestamp without time zone NOT NULL,
    modified timestamp without time zone NOT NULL
);

CREATE INDEX job_queue_idx_account_id ON job_queue USING btree (account_id);
CREATE INDEX job_queue_idx_global_resource_id ON job_queue USING btree (global_resource_id);
CREATE INDEX job_queue_idx_local_resource_id ON job_queue USING btree (local_resource_id);
CREATE INDEX job_queue_idx_site_id ON job_queue USING btree (site_id);

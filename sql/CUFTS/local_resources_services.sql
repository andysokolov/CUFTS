CREATE TABLE local_resources_services (
	id		SERIAL PRIMARY KEY,

	local_resource	INTEGER NOT NULL,		/* id for resource */
	service		INTEGER NOT NULL,		/* id for service */
	
	created		TIMESTAMP NOT NULL DEFAULT NOW(),
	modified	TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX local_resources_services_resource_idx ON local_resources_services(local_resource);
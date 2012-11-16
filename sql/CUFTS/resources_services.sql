CREATE TABLE resources_services (
	id		SERIAL PRIMARY KEY,

	resource	INTEGER NOT NULL,		/* id for resource */
	service		INTEGER NOT NULL,		/* id for service */
	
	created		TIMESTAMP NOT NULL DEFAULT NOW(),
	modified	TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX resources_services_resource_idx ON resources_services(resource);
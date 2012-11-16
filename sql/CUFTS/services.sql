CREATE TABLE services (
	id		SERIAL PRIMARY KEY,

	name		VARCHAR(256) NOT NULL,		/* Name of the service for display purposes */
	method		VARCHAR(256) NOT NULL,		/* Method to call for service */
	description	VARCHAR(4098),			/* Long description */
	
	created		TIMESTAMP NOT NULL DEFAULT NOW(),
	modified	TIMESTAMP NOT NULL DEFAULT NOW()
);

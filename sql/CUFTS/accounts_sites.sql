CREATE TABLE accounts_sites (
	id		SERIAL PRIMARY KEY,

	account		INTEGER NOT NULL,
	site		INTEGER NOT NULL,

	created		TIMESTAMP NOT NULL DEFAULT NOW(),
	modified	TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX accounts_sites_account_idx on accounts_sites(account);
CREATE INDEX accounts_sites_sites_idx on accounts_sites(site);

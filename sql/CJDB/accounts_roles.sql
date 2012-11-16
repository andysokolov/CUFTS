CREATE TABLE cjdb_accounts_roles (
    id      SERIAL PRIMARY KEY,
    account INTEGER,
    role    INTEGER
);

CREATE UNIQUE INDEX cjdb_a_r_ar_idx ON cjdb_accounts_roles( account, role );

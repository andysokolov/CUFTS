CREATE TABLE erm_sushi (
    id              SERIAL PRIMARY KEY,
    site            INTEGER NOT NULL,
    name            VARCHAR(255) NOT NULL,
    requestor       VARCHAR(255),
    service_url     VARCHAR(255)
);

ALTER TABLE local_resources ADD COLUMN resource_identifier VARCHAR(256);
ALTER TABLE resources ADD COLUMN resource_identifier VARCHAR(256);

UPDATE resources SET resource_identifier = resource_details.value FROM resource_details WHERE resource_details.resource = resources.id AND field = 'resource_identifier';
UPDATE local_resources SET resource_identifier = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'resource_identifier';

DELETE from resource_details where field = 'resource_identifier';
DELETE from local_resource_details where field = 'resource_identifier';


ALTER TABLE local_resources ADD COLUMN database_url VARCHAR(1024);
ALTER TABLE resources ADD COLUMN database_url VARCHAR(1024);

UPDATE resources SET database_url = resource_details.value FROM resource_details WHERE resource_details.resource = resources.id AND field = 'database_url';
UPDATE local_resources SET database_url = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'database_url';

DELETE from resource_details where field = 'database_url';
DELETE from local_resource_details where field = 'database_url';


ALTER TABLE local_resources ADD COLUMN auth_name VARCHAR(256);
ALTER TABLE resources ADD COLUMN auth_name VARCHAR(256);

UPDATE resources SET auth_name = resource_details.value FROM resource_details WHERE resource_details.resource = resources.id AND field = 'auth_name';
UPDATE local_resources SET auth_name = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'auth_name';

DELETE from resource_details where field = 'auth_name';
DELETE from local_resource_details where field = 'auth_name';


ALTER TABLE local_resources ADD COLUMN auth_passwd VARCHAR(256);
ALTER TABLE resources ADD COLUMN auth_passwd VARCHAR(256);

UPDATE resources SET auth_passwd = resource_details.value FROM resource_details WHERE resource_details.resource = resources.id AND field = 'auth_passwd';
UPDATE local_resources SET auth_passwd = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'auth_passwd';

DELETE from resource_details where field = 'auth_passwd';
DELETE from local_resource_details where field = 'auth_passwd';


ALTER TABLE local_resources ADD COLUMN url_base VARCHAR(1024);
ALTER TABLE resources ADD COLUMN url_base VARCHAR(1024);

UPDATE resources SET url_base = resource_details.value FROM resource_details WHERE resource_details.resource = resources.id AND field = 'url_base';
UPDATE local_resources SET url_base = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'url_base';

DELETE from resource_details where field = 'url_base';
DELETE from local_resource_details where field = 'url_base';


ALTER TABLE local_resources ADD COLUMN proxy_suffix VARCHAR(1024);
ALTER TABLE resources ADD COLUMN proxy_suffix VARCHAR(1024);

UPDATE resources SET proxy_suffix = resource_details.value FROM resource_details WHERE resource_details.resource = resources.id AND field = 'proxy_suffix';
UPDATE local_resources SET proxy_suffix = local_resource_details.value FROM local_resource_details WHERE local_resource_details.local_resource = local_resources.id AND field = 'proxy_suffix';

DELETE from resource_details where field = 'proxy_suffix';
DELETE from local_resource_details where field = 'proxy_suffix';

DROP VIEW merged_resources; /* IF EXISTS */
CREATE VIEW merged_resources AS
    SELECT local_resources.id AS id,
           local_resources.id AS local_resource,
           resources.id AS global_resource,
           local_resources.site AS site,
           COALESCE( local_resources.name, resources.name ) AS name,
           COALESCE( local_resources.provider, resources.provider ) AS provider,
           COALESCE( local_resources.resource_type, resources.resource_type ) AS resource_type,
           COALESCE( local_resources.module, resources.module ) AS module,
           local_resources.proxy,
           local_resources.dedupe,
           local_resources.auto_activate,
           local_resources.rank,
           local_resources.erm_main,
           local_resources.active AS active

    FROM local_resources
    LEFT OUTER JOIN resources ON ( local_resources.resource = resources.id );

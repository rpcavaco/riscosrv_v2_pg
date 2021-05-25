-- Table: risco_v2_publico_dev.risco_map

-- DROP TABLE risco_v2_publico_dev.risco_map;

CREATE TABLE risco_v2_publico_dev.risco_map
(
    mapid character varying(64) COLLATE pg_catalog."default" NOT NULL,
    "desc" character varying COLLATE pg_catalog."default",
    srid integer NOT NULL,
    CONSTRAINT risco_map_pk PRIMARY KEY (mapid)
        USING INDEX TABLESPACE sde_tbs_01
)
WITH (
    OIDS = FALSE
)
TABLESPACE sde_tbs_01;

ALTER TABLE risco_v2_publico_dev.risco_map
    OWNER to sup_ap;
-- Table: riscov2_dev.risco_map

-- DROP TABLE riscov2_dev.risco_map;

CREATE TABLE riscov2_dev.risco_map
(
    mapname character varying(64) COLLATE pg_catalog."default" NOT NULL,
    "desc" character varying COLLATE pg_catalog."default",
    srid integer NOT NULL,
    CONSTRAINT risco_map_pk PRIMARY KEY (mapname)

);

ALTER TABLE riscov2_dev.risco_map
    OWNER to sup_ap;
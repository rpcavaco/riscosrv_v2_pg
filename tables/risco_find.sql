-- Table: riscov2_dev.risco_find

-- DROP TABLE riscov2_dev.risco_find;

CREATE TABLE riscov2_dev.risco_find
(
    falias character varying(64) COLLATE pg_catalog."default" NOT NULL,
    alias character varying COLLATE pg_catalog."default" NOT NULL,
    ord smallint NOT NULL DEFAULT 1,
    inuse boolean NOT NULL DEFAULT true,
    filteradapt text COLLATE pg_catalog."default",
    target risco_v2_publico.find_target,
    fschema character varying(64) COLLATE pg_catalog."default",
    CONSTRAINT pk_risco_find PRIMARY KEY (falias, ord)

);

ALTER TABLE riscov2_dev.risco_find
    OWNER to sup_ap;

COMMENT ON COLUMN riscov2_dev.risco_find.filteradapt
    IS 'JSON array containing format items to place values array elements in due positions similar to corresponding variable parameter positions';

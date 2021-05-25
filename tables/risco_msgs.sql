-- Table: risco_v2_publico_dev.risco_msgs

-- DROP TABLE risco_v2_publico_dev.risco_msgs;

CREATE TABLE risco_v2_publico_dev.risco_msgs
(
    sn integer NOT NULL DEFAULT nextval('risco_v2_publico_dev.risco_msgs_sn_seq'::regclass),
    msg text COLLATE pg_catalog."default",
    severity smallint NOT NULL DEFAULT 0,
    context character varying(128) COLLATE pg_catalog."default",
    ts timestamp with time zone DEFAULT clock_timestamp(),
    params json,
    CONSTRAINT risco_msgs_pkey PRIMARY KEY (sn)
        USING INDEX TABLESPACE sde_tbs_01
)
WITH (
    OIDS = FALSE
)
TABLESPACE sde_tbs_01;

ALTER TABLE risco_v2_publico_dev.risco_msgs
    OWNER to sup_ap;

COMMENT ON COLUMN risco_v2_publico_dev.risco_msgs.severity
    IS '0-info, 1-warning, 2-error, 3-fatal';
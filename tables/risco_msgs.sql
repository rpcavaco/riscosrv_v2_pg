-- Table: riscov2_dev.risco_msgs

-- DROP TABLE riscov2_dev.risco_msgs;

CREATE TABLE riscov2_dev.risco_msgs
(
    sn integer NOT NULL DEFAULT nextval('riscov2_dev.risco_msgs_sn_seq'::regclass),
    msg text COLLATE pg_catalog."default",
    severity smallint NOT NULL DEFAULT 0,
    context character varying(128) COLLATE pg_catalog."default",
    ts timestamp with time zone DEFAULT clock_timestamp(),
    params json,
    CONSTRAINT risco_msgs_pkey PRIMARY KEY (sn)

);

ALTER TABLE riscov2_dev.risco_msgs
    OWNER to sup_ap;

COMMENT ON COLUMN riscov2_dev.risco_msgs.severity
    IS '0-info, 1-warning, 2-error, 3-fatal';
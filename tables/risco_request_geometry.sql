-- Table: risco_v2_publico_dev.risco_request_geometry

-- DROP TABLE risco_v2_publico_dev.risco_request_geometry;

CREATE UNLOGGED TABLE risco_v2_publico_dev.risco_request_geometry
(
    reqid uuid NOT NULL,
    lyrid uuid NOT NULL,
    oidv integer NOT NULL,
    the_geom geometry
)
WITH (
    OIDS = FALSE
)
TABLESPACE sde_tbs_01;

ALTER TABLE risco_v2_publico_dev.risco_request_geometry
    OWNER to sup_ap;
-- Index: ix_reqid_lyrid

-- DROP INDEX risco_v2_publico_dev.ix_reqid_lyrid;

CREATE INDEX ix_reqid_lyrid
    ON risco_v2_publico_dev.risco_request_geometry USING btree
    (reqid ASC NULLS LAST, lyrid ASC NULLS LAST)
    TABLESPACE sde_tbs_01;
-- Index: req_geom_idx

-- DROP INDEX risco_v2_publico_dev.req_geom_idx;

CREATE INDEX req_geom_idx
    ON risco_v2_publico_dev.risco_request_geometry USING btree
    (reqid ASC NULLS LAST, lyrid ASC NULLS LAST, oidv ASC NULLS LAST)
    TABLESPACE sde_tbs_01;

CREATE TABLE IF NOT EXISTS riscov2_dev.risco_map_auth_session
(
    mapname character varying(64) COLLATE pg_catalog."default" NOT NULL,
    auth_ctrl_obj_schema character varying(64) COLLATE pg_catalog."default",
    auth_ctrl_obj_name character varying(64) COLLATE pg_catalog."default",
    login_field character varying(64) COLLATE pg_catalog."default",
    sessionid_field character varying(64) COLLATE pg_catalog."default",
    editok_validation_expression text COLLATE pg_catalog."default",
    do_match_login boolean NOT NULL DEFAULT false,
    CONSTRAINT pk_risco_map_auth_session PRIMARY KEY (mapname)
);

ALTER TABLE risco_v2.risco_map_auth_session
    OWNER to sup_ap;
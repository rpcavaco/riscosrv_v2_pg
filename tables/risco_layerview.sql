-- Table: riscov2_dev.risco_layerview

-- DROP TABLE riscov2_dev.risco_layerview;

CREATE TABLE IF NOT EXISTS riscov2_dev.risco_layerview
(
    lname character varying(64) COLLATE pg_catalog."default" NOT NULL,
    dbobjname character varying(64) COLLATE pg_catalog."default" NOT NULL,
    oidfname character varying(64) COLLATE pg_catalog."default" NOT NULL DEFAULT 'objectid'::character varying,
    geomfname character varying(64) COLLATE pg_catalog."default" NOT NULL DEFAULT 'shape'::character varying,
    adic_fields_str text COLLATE pg_catalog."default",
    schema character varying(64) COLLATE pg_catalog."default",
    lyrid uuid NOT NULL DEFAULT uuid_generate_v1(),
    inuse boolean NOT NULL DEFAULT true,
    maps text[] COLLATE pg_catalog."default",
    srid integer,
    useridfname character varying(64) COLLATE pg_catalog."default",
    filter_expression text COLLATE pg_catalog."default",
    joinobj character varying(64) COLLATE pg_catalog."default",
    join_expression text COLLATE pg_catalog."default",
    joinschema character varying(64) COLLATE pg_catalog."default",
    outer_join boolean,
    public_access boolean NOT NULL DEFAULT false,
    is_function boolean NOT NULL DEFAULT false,
    deffilter text COLLATE pg_catalog."default",
    editable boolean NOT NULL DEFAULT false,
    editobj_schema character varying(64) COLLATE pg_catalog."default",
    editobj_name character varying(64) COLLATE pg_catalog."default",
    edit_users text[] COLLATE pg_catalog."default",
    gisid_field character varying(64) COLLATE pg_catalog."default",
    accept_deletion boolean NOT NULL DEFAULT false,
	mark_as_deleted_ts_field character varying(64) COLLATE pg_catalog."default",
	creation_ts_field character varying(64) COLLATE pg_catalog."default",
	save_ret_fields_str text COLLATE pg_catalog."default",
    CONSTRAINT risco_layer_pk PRIMARY KEY (lname)
);

ALTER TABLE riscov2_dev.risco_layerview
    OWNER to sup_ap;

COMMENT ON COLUMN riscov2_dev.risco_layerview.adic_fields_str
    IS 'comma separated zero or more field names';

COMMENT ON COLUMN riscov2_dev.risco_layerview.filter_expression
    IS 'SQL where clause with variable place holders, to use when layer is also used as alphanumeric row source';

COMMENT ON COLUMN riscov2_dev.risco_layerview.joinobj
    IS 'database object to join to';

COMMENT ON COLUMN riscov2_dev.risco_layerview.join_expression
    IS 'SQL join expression, using one letter table aliases, in alphabetic order (ex.: ''a'', ''b'' ... )';

COMMENT ON COLUMN riscov2_dev.risco_layerview.is_function
    IS 'Layer datasource is a row returning function ?';

COMMENT ON COLUMN riscov2_dev.risco_layerview.deffilter
    IS 'SQL where clause without variables, as ''definition query''';

COMMENT ON COLUMN riscov2_dev.risco_layerview.gisid_field
    IS 'Field containing unique identification os GIS object (necessary for editing)';

COMMENT ON COLUMN riscov2_dev.risco_layerview.mark_as_deleted_ts_field
    IS 'Timestamp field name for turning a record marked-as-deleted';

COMMENT ON COLUMN riscov2_dev.risco_layerview.creation_ts_field
    IS 'Timestamp field name for mark creation ts moment';	

COMMENT ON COLUMN riscov2_dev.risco_layerview.accept_deletion
    IS 'Boolean flag field, true means deletion is allowed, either as record removal or as stamping record''s marked-as-deleted flag';	

COMMENT ON COLUMN riscov2_dev.risco_layerview.creation_ts_field
    IS 'Timestamp field name for mark creation ts moment';		
	
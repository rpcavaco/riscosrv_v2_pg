-- Table: riscov2_dev.risco_layerview

-- DROP TABLE riscov2_dev.risco_layerview;

CREATE TABLE riscov2_dev.risco_layerview
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
    orderby text COLLATE pg_catalog."default",
    CONSTRAINT risco_layer_pk PRIMARY KEY (lname)

);

ALTER TABLE riscov2_dev.risco_layerview
    OWNER to sup_ap;

COMMENT ON COLUMN riscov2_dev.risco_layerview.adic_fields_str
    IS 'zero ou vários campos, separados por vírgula';

COMMENT ON COLUMN riscov2_dev.risco_layerview.filter_expression
    IS 'um ou vários campos, separados por vírgula';

COMMENT ON COLUMN riscov2_dev.risco_layerview.joinobj
    IS 'tabela (gráfica ou alfa) para fazer join';

COMMENT ON COLUMN riscov2_dev.risco_layerview.join_expression
    IS 'expressão sql, os alias das tabelas são as letras da ordem alfabética ''a'' e ''b''';
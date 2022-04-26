-- Table: riscov2_dev.risco_tableview

-- DROP TABLE riscov2_dev.risco_tableview;

CREATE TABLE riscov2_dev.risco_tableview
(
    alias character varying(64) COLLATE pg_catalog."default" NOT NULL,
    tname character varying(64) COLLATE pg_catalog."default" NOT NULL,
    fields_str text COLLATE pg_catalog."default",
    schema character varying(64) COLLATE pg_catalog."default",
    tblid uuid NOT NULL DEFAULT uuid_generate_v1(),
    inuse boolean NOT NULL DEFAULT true,
    orderby text COLLATE pg_catalog."default",
    filter_expression text COLLATE pg_catalog."default",
    joinobj character varying(64) COLLATE pg_catalog."default",
    join_expression text COLLATE pg_catalog."default",
    joinschema character varying(64) COLLATE pg_catalog."default",
    outer_join boolean,
    CONSTRAINT risco_table_pk PRIMARY KEY (alias)
        USING INDEX TABLESPACE sde_tbs_01
)
WITH (
    OIDS = FALSE
)
TABLESPACE sde_tbs_01;

ALTER TABLE riscov2_dev.risco_tableview
    OWNER to sup_ap;

COMMENT ON COLUMN riscov2_dev.risco_tableview.fields_str
    IS 'zero ou vários campos, separados por vírgula';

COMMENT ON COLUMN riscov2_dev.risco_tableview.orderby
    IS 'zero ou vários campos, separados por vírgula';

COMMENT ON COLUMN riscov2_dev.risco_tableview.filter_expression
    IS 'expressão sql com placeholders';

COMMENT ON COLUMN riscov2_dev.risco_tableview.joinobj
    IS 'tabela para fazer join';

COMMENT ON COLUMN riscov2_dev.risco_tableview.join_expression
    IS 'expressão sql, os alias das tabelas são as letras da ordem alfabética ''a'' e ''b''';
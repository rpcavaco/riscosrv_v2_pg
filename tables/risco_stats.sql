CREATE TABLE IF NOT EXISTS riscov2_dev.risco_stats
(
    key character varying(32) COLLATE pg_catalog."default" NOT NULL,
    dataobjname character varying(32) COLLATE pg_catalog."default" NOT NULL,
    allowedcols text COLLATE pg_catalog."default",
    dataobjschema character varying(32) COLLATE pg_catalog."default",
    filter_expression text COLLATE pg_catalog."default",
    CONSTRAINT risco_stats_pkey PRIMARY KEY (key)
);

ALTER TABLE riscov2_dev.risco_stats
    OWNER to sup_ap;

COMMENT ON COLUMN riscov2_dev.risco_stats.dataobjschema
    IS 'schema name of object for which we need to expose statistics';

COMMENT ON COLUMN riscov2_dev.risco_stats.dataobjname
    IS 'name of object for which we need to expose statistics';	

COMMENT ON COLUMN riscov2_dev.risco_stats.allowedcols
     IS 'column names for which we need to expose statistics';	
 
COMMENT ON COLUMN riscov2_dev.risco_stats.filter_expression
    IS 'constant where clause, no placeholders';	


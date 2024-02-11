\connect gisdata

/*
-------------------------------------------------------------------------------
MIT License

Copyright (c) 2024 Rui Cavaco

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-------------------------------------------------------------------------------
*/

-- DEPLOYMENT SCRIPT FOR RISCO v2 POSTGRESQL + POSTGIS COMPONENTS --

-- Generated on 2024-02-11T17:43:22.526913


CREATE SCHEMA risco_v2
    AUTHORIZATION risco_v2;




--------------------------------------------------------------------------------
-- ===== DEFINED TYPES =====
--------------------------------------------------------------------------------



-- ----- Type find_target -----

CREATE TYPE risco_v2.find_target AS ENUM
    ('function', 'layer', 'table');

ALTER TYPE risco_v2.find_target
    OWNER TO risco_v2;


--------------------------------------------------------------------------------
-- ===== SEQUENCES =====
--------------------------------------------------------------------------------



-- ----- Sequence risco_msgs_sn_seq -----

CREATE SEQUENCE risco_v2.risco_msgs_sn_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	NO CYCLE;

ALTER SEQUENCE risco_v2.risco_msgs_sn_seq OWNER TO risco_v2;


--------------------------------------------------------------------------------
-- ===== TABLES =====
--------------------------------------------------------------------------------



-- ----- Table risco_find -----

CREATE TABLE risco_v2.risco_find
(
    falias character varying(64) COLLATE pg_catalog."default" NOT NULL,
    alias character varying COLLATE pg_catalog."default" NOT NULL,
    ord smallint NOT NULL DEFAULT 1,
    inuse boolean NOT NULL DEFAULT true,
    filteradapt text COLLATE pg_catalog."default",
    target risco_v2.find_target,
    fschema character varying(64) COLLATE pg_catalog."default",
    CONSTRAINT pk_risco_find PRIMARY KEY (falias, ord)

);

ALTER TABLE risco_v2.risco_find
    OWNER to risco_v2;

COMMENT ON COLUMN risco_v2.risco_find.filteradapt
    IS 'JSON array containing format items to place values array elements in due positions similar to corresponding variable parameter positions';


-- ----- Table risco_layerview -----

CREATE TABLE IF NOT EXISTS risco_v2.risco_layerview
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
    accept_deletion boolean NOT NULL DEFAULT true,
	mark_as_deleted_ts_field character varying(64) COLLATE pg_catalog."default",
	creation_ts_field character varying(64) COLLATE pg_catalog."default",
    CONSTRAINT risco_layer_pk PRIMARY KEY (lname)
);

ALTER TABLE risco_v2.risco_layerview
    OWNER to risco_v2;

COMMENT ON COLUMN risco_v2.risco_layerview.adic_fields_str
    IS 'comma separated zero or more field names';

COMMENT ON COLUMN risco_v2.risco_layerview.filter_expression
    IS 'SQL where clause with variable place holders, to use when layer is also used as alphanumeric row source';

COMMENT ON COLUMN risco_v2.risco_layerview.joinobj
    IS 'database object to join to';

COMMENT ON COLUMN risco_v2.risco_layerview.join_expression
    IS 'SQL join expression, using one letter table aliases, in alphabetic order (ex.: ''a'', ''b'' ... )';

COMMENT ON COLUMN risco_v2.risco_layerview.is_function
    IS 'Layer datasource is a row returning function ?';

COMMENT ON COLUMN risco_v2.risco_layerview.deffilter
    IS 'SQL where clause without variables, as ''definition query''';

COMMENT ON COLUMN risco_v2.risco_layerview.gisid_field
    IS 'Field containing unique identification os GIS object (necessary for editing)';

COMMENT ON COLUMN risco_v2.risco_layerview.mark_as_deleted_ts_field
    IS 'Timestamp field name for turning a record marked-as-deleted';

COMMENT ON COLUMN risco_v2.risco_layerview.creation_ts_field
    IS 'Timestamp field name for mark creation ts moment';

COMMENT ON COLUMN risco_v2.risco_layerview.accept_deletion
    IS 'Boolean flag field, true means deletion is allowed, either as record removal or as stamping record''s marked-as-deleted flag';

COMMENT ON COLUMN risco_v2.risco_layerview.creation_ts_field
    IS 'Timestamp field name for mark creation ts moment';



-- ----- Table risco_map -----

CREATE TABLE risco_v2.risco_map
(
    mapname character varying(64) COLLATE pg_catalog."default" NOT NULL,
    descr character varying COLLATE pg_catalog."default",
    srid integer NOT NULL,
    CONSTRAINT risco_map_pk PRIMARY KEY (mapname)

);

ALTER TABLE risco_v2.risco_map
    OWNER to risco_v2;


-- ----- Table risco_map_auth_session -----

CREATE TABLE IF NOT EXISTS risco_v2.risco_map_auth_session
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
    OWNER to risco_v2;


-- ----- Table risco_msgs -----

CREATE TABLE risco_v2.risco_msgs
(
    sn integer NOT NULL DEFAULT nextval('risco_v2.risco_msgs_sn_seq'::regclass),
    msg text COLLATE pg_catalog."default",
    severity smallint NOT NULL DEFAULT 0,
    context character varying(128) COLLATE pg_catalog."default",
    ts timestamp with time zone DEFAULT clock_timestamp(),
    params json,
    CONSTRAINT risco_msgs_pkey PRIMARY KEY (sn)

);

ALTER TABLE risco_v2.risco_msgs
    OWNER to risco_v2;

COMMENT ON COLUMN risco_v2.risco_msgs.severity
    IS '0-info, 1-warning, 2-error, 3-fatal';


-- ----- Table risco_request -----

CREATE TABLE risco_v2.risco_request
(
    reqid uuid NOT NULL DEFAULT uuid_generate_v4(),
    cenx numeric NOT NULL,
    ceny numeric NOT NULL,
    wid numeric NOT NULL,
    hei numeric NOT NULL,
    pixsz numeric NOT NULL,
    CONSTRAINT pk_request_ PRIMARY KEY (reqid)

);

ALTER TABLE risco_v2.risco_request
    OWNER to risco_v2;


-- ----- Table risco_request_geometry -----

CREATE UNLOGGED TABLE risco_v2.risco_request_geometry
(
    reqid uuid NOT NULL,
    lyrid uuid NOT NULL,
    oidv integer NOT NULL,
    the_geom geometry
);

ALTER TABLE risco_v2.risco_request_geometry
    OWNER to risco_v2;

CREATE INDEX ix_reqid_lyrid
    ON risco_v2.risco_request_geometry USING btree
    (reqid ASC NULLS LAST, lyrid ASC NULLS LAST);

CREATE INDEX req_geom_idx
    ON risco_v2.risco_request_geometry USING btree
    (reqid ASC NULLS LAST, lyrid ASC NULLS LAST, oidv ASC NULLS LAST);


-- ----- Table risco_stats -----

CREATE TABLE IF NOT EXISTS risco_v2.risco_stats
(
    key character varying(32) COLLATE pg_catalog."default" NOT NULL,
    dataobjname character varying(32) COLLATE pg_catalog."default" NOT NULL,
    allowedcols text COLLATE pg_catalog."default",
    dataobjschema character varying(32) COLLATE pg_catalog."default",
    filter_expression text COLLATE pg_catalog."default",
    CONSTRAINT risco_stats_pkey PRIMARY KEY (key)
);

ALTER TABLE risco_v2.risco_stats
    OWNER to risco_v2;

COMMENT ON COLUMN risco_v2.risco_stats.dataobjschema
    IS 'schema name of object for which we need to expose statistics';

COMMENT ON COLUMN risco_v2.risco_stats.dataobjname
    IS 'name of object for which we need to expose statistics';

COMMENT ON COLUMN risco_v2.risco_stats.allowedcols
     IS 'column names for which we need to expose statistics';

COMMENT ON COLUMN risco_v2.risco_stats.filter_expression
    IS 'constant where clause, no placeholders';



-- ----- Table risco_tableview -----

CREATE TABLE risco_v2.risco_tableview
(
    alias character varying(64) COLLATE pg_catalog."default" NOT NULL,
    dbobjname character varying(64) COLLATE pg_catalog."default" NOT NULL,
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

);

ALTER TABLE risco_v2.risco_tableview
    OWNER to risco_v2;

COMMENT ON COLUMN risco_v2.risco_tableview.fields_str
    IS 'comma-separated zero or more fieldnames';

COMMENT ON COLUMN risco_v2.risco_tableview.orderby
    IS 'comma-separated zero or more fieldnames';

COMMENT ON COLUMN risco_v2.risco_tableview.filter_expression
    IS 'where clause with parameter placeholders';

COMMENT ON COLUMN risco_v2.risco_tableview.joinobj
    IS 'name of table to join';

COMMENT ON COLUMN risco_v2.risco_tableview.join_expression
    IS 'sql join expression ON , table aliases are letter characters in alphabetic order ''a'' e ''b''';

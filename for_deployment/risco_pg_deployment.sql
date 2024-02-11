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

-- Generated on 2024-02-11T21:20:40.114187


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


--------------------------------------------------------------------------------
-- ===== PROCEDURES =====
--------------------------------------------------------------------------------



-- ----- Procedure / function riscov2_dev.alphastats -----

CREATE OR REPLACE FUNCTION risco_v2.alphastats(p_key text, p_options json)
	RETURNS jsonb
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$
DECLARE
	v_ret jsonb;
	v_sch text;
	v_oname text;
	v_cols text[];
	v_labelcols text[];
	v_col text;
	v_label text;
	v_sql text;
	v_sql_proto text;
	v_sql_proto_templ text;
	v_sql_templ text;
	v_sql1 text;
	v_sql2 text;
	v_sql3 text;
	v_sql4 text;
	v_int integer;
	v_int2 integer;
	v_counts json;
	v_from text;
	v_from_constrained text;
	v_joinschema text;
	v_joinobj text;
	v_join_expression text;
	v_filter_expression text;
	v_geomfname text;
	v_outer_join boolean;
	v_outsrid int;
	v_clustersize numeric;
	v_isdiscrete boolean;

BEGIN

	set search_path to risco_v2, public;

	v_ret := '{}'::jsonb;

	select dataobjschema, dataobjname,
		regexp_split_to_array(allowedcols, '[\s\,]+') cols,
		regexp_split_to_array(labelcols, '[\s\,]+') labelcols,
		joinschema, joinobj, join_expression, outer_join, geomfname, filter_expression
	into v_sch, v_oname, v_cols, v_labelcols,
		 v_joinschema, v_joinobj, v_join_expression, v_outer_join, v_geomfname,
		 v_filter_expression
	from risco_stats
	where key = p_key;

	v_outsrid := p_options->>'outsrid';
	v_clustersize := p_options->>'clustersize';
	-- raise notice 'v_geomfname:% p_key:% outsrid:%', v_geomfname, p_key, v_outsrid;

	-- NEGATIVE CLUSTERSIZE prevents clustering

	if v_clustersize is null then
		v_clustersize := 150;
	end if;

	if FOUND then

		for i in 1..array_length(v_cols, 1)
		loop
			v_col := v_cols[i];

			if not p_options->>'col' is null and v_col != p_options->>'col' then
				continue;
			end if;

			v_label := null;
			if not v_labelcols is null and array_length(v_labelcols, 1) >= i then
				v_label := v_labelcols[i];
			end if;

			v_ret := jsonb_set(v_ret, array[v_col], '{}'::jsonb, true);

			v_from := format('%s.%s', v_sch, v_oname);
			v_from_constrained := v_from;

			if not v_joinschema is null and length(v_joinschema) > 0 and
					not v_joinobj is null and length(v_joinobj) > 0 and
					not v_join_expression is null and length(v_join_expression) > 0 then

				v_from := format('%s.%s a', v_sch, v_oname);
				v_from_constrained := v_from;

				if not v_outer_join is null and v_outer_join then
					v_from := v_from || ' left outer join ';
				else
					v_from := v_from || ' inner join ';
				end if;
				v_from := format('%s %s.%s b on %s', v_from, v_joinschema, v_joinobj, v_join_expression);
				if v_outer_join is null or not v_outer_join then
					v_from_constrained := format('%s %s.%s b on %s', v_from, v_joinschema, v_joinobj, v_join_expression);
				end if;

			end if;

			if v_filter_expression is null then
				v_sql := format('select count(*) from %s where not %s is null', v_from_constrained, v_col);
			else
				v_sql := format('select count(*) from %s where not %s is null and %s', v_from_constrained, v_col, v_filter_expression);
			end if;

			execute v_sql into v_int; -- records count

			if v_filter_expression is null then
				v_sql := format('select count(*) from (select distinct %s valor from %s where not %s is null) t1', v_col, v_from_constrained, v_col);
			else
				v_sql := format('select count(*) from (select distinct %s valor from %s where not %s is null and %s) t1', v_col, v_from_constrained, v_col, v_filter_expression);
			end if;

			execute v_sql into v_int2; -- classes count

			-- discrete data (only, for now)
			if v_int2 < v_int / 20.0 and v_int2 < 500 then

				v_ret := jsonb_set(v_ret, array[v_col, 'sumofclasscounts'], to_jsonb(v_int), true);
				v_ret := jsonb_set(v_ret, array[v_col, 'classescount'], to_jsonb(v_int2), true);

				v_sql1 := 'select json_object_agg(val, json_build_object(''cnt'', cnt';
				v_sql2 := 'select %s val,';
				v_sql3 := v_col;

				if not v_label is null then
					v_sql1 := v_sql1 || ', ''lbl'', lbl';
					v_sql2 := v_sql2 || format(' %s lbl,', v_label);
					v_sql3 := v_sql3 || format(', %s', v_label);
				end if;

				if not v_geomfname is null and v_clustersize > 0 then
					v_sql1 := v_sql1 || ', ''xmin'', ST_XMin(env), ''ymin'', ST_YMin(env), ''xmax'', ST_XMax(env), ''ymax'', ST_yMax(env), ''centroids'', g.centroids';
					if not v_outsrid is null then
						v_sql2 := v_sql2 || format(' st_extent(st_transform(%s, %s)) env,', v_geomfname, v_outsrid);
					else
						v_sql2 := v_sql2 || format(' st_extent(%s) env,', v_geomfname);
					end if;
					-- v_sql3 := v_sql3 || format(', %s', v_geomfname);
				end if;

				if v_clustersize > 0 then

					if not v_geomfname is null and v_filter_expression is null then
						v_sql_proto_templ := '%s)) from (%s count(*) cnt from %%s where not %s is null group by %s) c cross join lateral (%s) g';
						v_sql4 := format('select json_agg(coords) centroids from (select json_build_array(ST_X(centpt), st_y(centpt)) coords from (%s) e) f',
							format('select cluster, st_pointonsurface(st_union(%s)) centpt from (%s) d group by cluster', v_geomfname,
							format('select %s, ST_ClusterDBSCAN(%1$s, %s, 1) OVER () AS cluster from %s where %s = c.val and not %s is null', v_geomfname, v_clustersize, v_from_constrained, v_col, v_col)));
					else
						v_sql_proto_templ := '%s)) from (%s count(*) cnt from %%s where not %s is null and %%s group by %s) c cross join lateral (%s) g';
						v_sql4 := format('select json_agg(coords) centroids from (select json_build_array(ST_X(centpt), st_y(centpt)) coords from (%s) e) f',
							format('select cluster, st_pointonsurface(st_union(%s)) centpt from (%s) d group by cluster', v_geomfname,
							format('select %s, ST_ClusterDBSCAN(%1$s, %s, 1) OVER () AS cluster from %s where %s = c.val and not %s is null and %%s', v_geomfname, v_clustersize, v_from_constrained, v_col, v_col)));
					end if;
					v_sql_proto := format(v_sql_proto_templ, v_sql1, v_sql2, v_col, v_sql3, v_sql4);

				else

					if v_filter_expression is null then
						v_sql_proto_templ := '%s)) from (%s count(*) cnt from %%s where not %s is null group by %s) c';
					else
						v_sql_proto_templ := '%s)) from (%s count(*) cnt from %%s where not %s is null and %%s group by %s) c';
					end if;
					v_sql_proto := format(v_sql_proto_templ, v_sql1, v_sql2, v_col, v_sql3);

				end if;

				-- raise notice 'v_sql_proto >>%<<', v_sql_proto;

				if v_clustersize > 0 then

					if v_filter_expression is null then
						v_sql := format(v_sql_proto, v_col, v_from, v_col);
					else
						v_sql := format(v_sql_proto, v_col, v_from, v_filter_expression, v_filter_expression);
					end if;

					-- raise notice 'v_sql >>%<<', v_sql;

					execute v_sql into v_counts;

					v_ret := jsonb_set(v_ret, array[v_col, 'classes'], to_jsonb(v_counts), true);

				end if;

			end if;

		end loop;

	end if;

	return v_ret;

END;
$BODY$;

ALTER FUNCTION risco_v2.alphastats(text, json) OWNER to risco_v2;


-- ----- Procedure / function riscov2_dev.binning -----

CREATE OR REPLACE FUNCTION risco_v2.binning(p_key text, p_geomtype text, p_radius numeric)
	RETURNS json
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$
DECLARE
	v_null integer;
BEGIN

	RETURN '{}'::json;

END;
$BODY$;

ALTER FUNCTION risco_v2.binning(text, text, numeric) OWNER to risco_v2;


-- ----- Procedure / function riscov2_dev.clrreq -----

CREATE OR REPLACE FUNCTION risco_v2.clrreq(p_creqid character varying, p_layer_name character varying)
 RETURNS void
 LANGUAGE 'plpgsql'
 VOLATILE
AS $BODY$
	declare

		v_lyrid uuid;
		v_reqid uuid;

	begin

		perform set_config('search_path', 'risco_v2,public', true);

	    v_reqid := uuid(p_creqid);

		SELECT lyrid
	    INTO v_lyrid
	    FROM risco_layerview
		WHERE lname = p_layer_name;

		delete
		from risco_request_geometry
		WHERE reqid = v_reqid
		AND lyrid = v_lyrid;

	END;

$BODY$;

alter function risco_v2.clrreq(character varying, character varying) owner to risco_v2;


-- ----- Procedure / function riscov2_dev.do_get -----

CREATE OR REPLACE FUNCTION risco_v2.do_get(
	p_alias_name character varying,
	p_keyword character varying,
	p_filter_values json,
	p_pointbuffer_m numeric,
	p_lang character varying)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
	v_row record;
	v_row2 record;
	v_qry text;
	v_flds text;
	v_from text;
	v_arr1 text[];
	v_arr2 text[];
	v_fmt_interm text;
	v_sql_outer_template text;
	v_ret jsonb;
	v_partial jsonb;
begin
	if p_filter_values is null then
		return null;
	end if;

	perform set_config('search_path', 'risco_v2,public', true);

	v_ret := '{}'::jsonb;
	v_sql_outer_template := 'select json_agg(json_strip_nulls(row_to_json(t))) from (%s) t';

	for v_row in (
		select fschema, alias,
			target, filteradapt
		from risco_find
		where falias = p_alias_name
		and inuse
		order by ord
	)
	loop

		-- raise notice 'v_row.target:%', v_row.target;
		v_partial := null;

		if v_row.target = 'function' then

			v_qry := format('select %I.%I(%L, $1, $2)', v_row.fschema, v_row.alias, p_keyword);
			--v_qry := format(v_sql_outer_template, v_qry);

			-- raise notice '%', v_qry;

			execute v_qry into v_partial using p_filter_values, p_pointbuffer_m;
			--raise notice '%', v_partial;

			v_ret := to_jsonb(v_partial);

			-- only one entry v_row.target = 'function' per alias
			exit;

		end if;

		if v_row.target = 'layer' then

			select schema, dbobjname, oidfname, geomfname, adic_fields_str,
					outer_join, joinschema, joinobj, join_expression,
					filter_expression, orderby
				into v_row2
			from risco_layerview
			where alias = v_row.alias
			and not filter_expression is null
			and length(filter_expression) > 0;

			v_flds := format('a.%I, a.%I', v_row2.oidfname, v_row2.geomfname);
			if not v_row2.adic_fields_str is null and length(v_row2.adic_fields_str) > 0 then
				v_flds := format('%s, %s', v_flds, v_row2.adic_fields_str);
			end if;

		elsif v_row.target = 'table' then

			select schema, dbobjname, fields_str,
					outer_join, joinschema, joinobj, join_expression,
					filter_expression, orderby
				into v_row2
			from risco_tableview
			where alias = v_row.alias
			and not filter_expression is null
			and length(fields_str) > 0
			and length(filter_expression) > 0;

			v_flds := v_row2.fields_str;

		end if;

		v_from := format('%s.%s a', v_row2.schema, v_row2.dbobjname);
		if not v_row2.joinschema is null and length(v_row2.joinschema) > 0 and
				not v_row2.joinobj is null and length(v_row2.joinobj) > 0 and
				not v_row2.join_expression is null and length(v_row2.join_expression) > 0 then
			if not v_row2.outer_join is null and v_row2.outer_join then
				v_from := v_from || ' outer join ';
			else
				v_from := v_from || ' inner join ';
			end if;
			v_from := format('%s %s.%s b on %s', v_from, v_row2.joinschema, v_row2.joinobj, v_row2.join_expression);
		end if;

		-- raise notice 'v_from:%', v_from;

		v_qry := format('select %s from %s where %s', v_flds, v_from, v_row2.filter_expression);
		-- raise notice 'fadapt:% v_qry 1:%', v_row.filteradapt, v_qry;

		if not v_row.filteradapt is null and length(v_row.filteradapt) > 0 then

			select array(select json_array_elements_text(p_filter_values)) into v_arr1;
			select format(v_row.filteradapt, variadic v_arr1) into v_fmt_interm;

			select array(select json_array_elements_text(v_fmt_interm::json)) into v_arr2;

		else
			select ARRAY(SELECT json_array_elements_text(p_filter_values)) into v_arr2;
		end if;
		v_qry := format(v_qry, variadic v_arr2);

		-- raise notice 'v_qry 2:%', v_qry;

		if not v_row2.orderby is null and length(v_row2.orderby) > 0 then
			v_qry := v_qry || ' order by ' ||  v_row2.orderby;
		end if;

		v_qry := format(v_sql_outer_template, v_qry);

		--raise notice '%', v_qry;

		execute v_qry into v_partial;

		v_ret := jsonb_set(v_ret, array[v_row.alias], to_jsonb(v_partial), true);

	end loop;

	--raise notice '--%--', v_qry;

	return v_ret;

END;
$BODY$;

ALTER FUNCTION risco_v2.do_get(character varying, character varying, json, numeric, character varying)
    OWNER TO risco_v2;

GRANT EXECUTE ON FUNCTION risco_v2.do_get(character varying, character varying, json, numeric, character varying) TO risco_v2;



-- ----- Procedure / function riscov2_dev.full_chunk_calc -----

CREATE OR REPLACE FUNCTION risco_v2.full_chunk_calc(p_cenx double precision, p_ceny double precision, p_pixsz double precision, p_width double precision, p_height double precision, p_mapname character varying, p_vizlayers character varying)
 RETURNS text
 LANGUAGE 'plpgsql'
 VOLATILE
AS $body$
DECLARE
	v_minx numeric;
	v_miny numeric;
	v_maxx numeric;
	v_maxy numeric;
	v_srid integer;
	v_tol numeric;
	v_sql text;
	v_reqid uuid;
	v_schema character varying(64);
	v_table character varying(64);
	v_geomfname character varying(64);
	v_geom_source text;
	v_rec record;
	v_ret json;
    v_ctrlcnt integer;
    v_lyr_table regclass;
    v_env geometry;
    v_actenv geometry;
    v_use_vizlayers boolean;
    v_vizlyrs_array text[];
	v_t0 timestamp;
	v_t1 timestamp;
	v_t2 timestamp;
	v_profile boolean;
BEGIN
	v_profile := 'f'; -- controle profiling layers

	if v_profile then
		v_t0 := clock_timestamp();
		v_t1 := clock_timestamp();
	end if;

	perform set_config('search_path', 'risco_v2,public', true);

	select srid from risco_map rm
	into v_srid
	where mapname = p_mapname;

	if v_srid is null then
		raise exception 'missing risco_map record for mapname: %', p_mapname;
	end if;

	v_minx := p_cenx - (p_width/2.0);
	v_miny := p_ceny - (p_height/2.0);
	v_maxx := p_cenx + (p_width/2.0);
	v_maxy := p_ceny + (p_height/2.0);

	INSERT INTO risco_request
	(cenx, ceny, wid, hei, pixsz)
	VALUES
	(p_cenx, p_ceny, p_width, p_height, p_pixsz)
	RETURNING reqid INTO v_reqid;

    SELECT ST_MakeEnvelope(v_minx, v_miny, v_maxx, v_maxy, v_srid) INTO v_env;

    IF NOT p_vizlayers IS NULL AND length(p_vizlayers) > 0 	THEN
    	v_use_vizlayers := true;
        v_vizlyrs_array := regexp_split_to_array(p_vizlayers, E'[\\s+]?[\\,][\\s+]?');
    ELSE
    	v_use_vizlayers := false;
    END IF;

	if v_profile then
		v_t2 := clock_timestamp();
		raise notice '..... timing B: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0);
		v_t1 := v_t2;
	end if;

	FOR v_rec IN
		SELECT lname, schema, dbobjname, geomfname, oidfname, lyrid, srid, is_function, deffilter
		FROM risco_layerview
		WHERE inuse
		AND p_mapname = ANY(maps)
	LOOP
		IF v_use_vizlayers AND v_rec.lname != ALL (v_vizlyrs_array) THEN
			CONTINUE;
		END IF;

		if v_profile then
		    raise notice '..... dbobjname: %   srid tema:% srid mapa:%', v_rec.dbobjname, v_rec.srid, v_srid;
		end if;

            BEGIN

				if v_rec.srid = v_srid then
					v_geom_source := v_rec.geomfname;
					v_actenv := v_env;
				else
					v_geom_source := format('ST_Transform(%I, %s)', v_rec.geomfname, v_srid);
					v_actenv := ST_Transform(v_env, v_rec.srid);
				end if;

				if v_rec.is_function then

					v_sql := 'INSERT INTO risco_request_geometry (reqid, lyrid, oidv, the_geom) ' ||
					'SELECT $1, $2, ' || v_rec.oidfname || ' oidv, ST_SnapToGrid(' || v_geom_source || ', $3, $4, $5, $6) the_geom ' ||
					'FROM ' || v_rec.schema || '.' || v_rec.dbobjname || '(' || v_minx || ',' || v_miny || ',' || v_maxx || ',' || v_maxy || ')';

				else

					v_sql := 'INSERT INTO risco_request_geometry (reqid, lyrid, oidv, the_geom) ' ||
					'SELECT $1, $2, ' || v_rec.oidfname || ' oidv, ST_SnapToGrid(' || v_geom_source || ', $3, $4, $5, $6) the_geom ' ||
					'FROM ' || v_rec.schema || '.' || v_rec.dbobjname || ' ' ||
					'where ' || v_rec.geomfname || ' && $7';

					if not v_rec.deffilter is null then

						v_sql := v_sql || ' and (' || v_rec.deffilter || ')';

					end if;

				end if;

				if v_profile then
					raise notice 'B v_sql:%, %, %, %, %, %, %, v_env:%', v_sql, v_reqid, v_rec.lyrid, p_cenx, p_ceny, p_pixsz, p_pixsz, ST_AsText(v_actenv);
				end if;

				execute v_sql
				using v_reqid, v_rec.lyrid, p_cenx, p_ceny, p_pixsz, p_pixsz,
						v_actenv;

            EXCEPTION

				WHEN SQLSTATE '42P01' THEN

					INSERT INTO risco_msgs (severity, context, msg)
					VALUES
					(2, 'full_chunk_calc', v_rec.schema || '.' || v_rec.dbobjname || ': table does not exist');
					CONTINUE;

				WHEN SQLSTATE '23505' THEN

					INSERT INTO risco_msgs (severity, context, msg)
					VALUES
					(2, 'full_chunk_calc', v_rec.schema || '.' || v_rec.dbobjname || ': table has non unique GIDs, was removed from response');
					CONTINUE;

             END;

		if v_profile then
			v_t2 := clock_timestamp();
		    raise notice '..... timing C: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0);
			v_t1 := v_t2;
		end if;

	END LOOP;

	SELECT json_build_object('reqid', v_reqid, 'stats',
		json_object_agg(lname,
        json_build_object('nchunks',CASE
		WHEN a.vcount < 5000  THEN
			1
		WHEN a.vcount < 10000  THEN
			2
		WHEN a.vcount < 25000  THEN
			3
		WHEN a.vcount < 50000  THEN
			4
		WHEN a.vcount < 90000  THEN
			5
		WHEN a.vcount < 120000  THEN
			6
		WHEN a.vcount < 140000  THEN
			7
		WHEN a.vcount < 160000  THEN
			8
		WHEN a.vcount < 180000  THEN
			9
		ELSE
			round(a.vcount / 20000)
		END,
		'nvert', a.vcount,
		'gisid_field', a.gisid_field,
		'accept_deletion', a.accept_deletion
	)))
	INTO v_ret
	FROM
	(SELECT lname, sum(st_npoints(the_geom)) vcount, t2.gisid_field, t2.accept_deletion
	FROM risco_request_geometry T1
	INNER JOIN risco_layerview T2
	ON T1.lyrid = T2.lyrid AND T1.reqid = v_reqid
	WHERE inuse
	GROUP BY lname) a;

	if v_profile then
		v_t2 := clock_timestamp();
		raise notice '..... timing FINAL: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0);
		v_t1 := v_t2;
	end if;

	RETURN v_ret::text;

END;
$body$;

alter function risco_v2.full_chunk_calc(double precision, double precision, double precision, double precision, double precision, character varying, character varying) owner to risco_v2;

GRANT EXECUTE ON FUNCTION risco_v2.full_chunk_calc(double precision, double precision, double precision, double precision, double precision, character varying, character varying) TO PUBLIC;


-- ----- Procedure / function riscov2_dev.gen_coords_elem -----

CREATE OR REPLACE FUNCTION risco_v2.gen_coords_elem(p_geom geometry, p_cenx double precision, p_ceny double precision, p_pixsz double precision)
 RETURNS json
 LANGUAGE 'plpgsql'
 VOLATILE
AS $body$

DECLARE
	v_retobj json;
    v_tmp_retobj text;
    v_max_depth integer;
    v_depth integer;
    v_snapped_geom geometry;
	v_aggr_table regclass;
BEGIN

    SELECT COALESCE(max(array_length((dp).path,1)), 0)
    INTO v_max_depth
    FROM ST_DumpPoints(p_geom) dp;

    -- Geometria p_geom ja deve estar snapped-to-grid

    IF p_geom IS NULL THEN
    	RETURN NULL;
    END IF;

	CASE v_max_depth
		WHEN 3 THEN
			select json_agg(coords) coords
			INTO v_retobj
			from
			(
				select path[1], json_agg(coords) coords
				from
				(
					select path[1:2] path, json_agg(coord) coords
					from (
						select (dp).path path,
							unnest(ARRAY[ROUND((ST_X((dp).geom) - p_cenx) / p_pixsz)::int,
							ROUND((ST_Y((dp).geom) - p_ceny) / p_pixsz)::int]) coord
						from ST_DumpPoints(p_geom) dp
					) b
					group by path[1:2]
					order by path[1:2]
				) c
				group by path[1]
				order by path[1]
			) d;

		WHEN 2 THEN
			select json_agg(coords) coords
			INTO v_retobj
			from
			(
				select path[1] path, json_agg(coord) coords
				from (
					select (dp).path path,
							unnest(ARRAY[ROUND((ST_X((dp).geom) - p_cenx) / p_pixsz)::int,
							ROUND((ST_Y((dp).geom) - p_ceny) / p_pixsz)::int]) coord
					from ST_DumpPoints(p_geom) dp
				) b
				group by path[1]
				order by path[1]
			) d;

		ELSE

			SELECT json_agg(coords) coords
			INTO v_retobj
			FROM
				(SELECT unnest(
					ARRAY[ROUND((ST_X((dp).geom) - p_cenx) / p_pixsz)::int,
					ROUND((ST_Y((dp).geom) - p_ceny) / p_pixsz)::int]
					) coords
					FROM ST_DumpPoints(p_geom) dp
				) a;

	END CASE;

    RETURN v_retobj;
END;

$body$;

alter function risco_v2.gen_coords_elem(geometry, double precision, double precision, double precision) owner to risco_v2;


-- ----- Procedure / function riscov2_dev.json_quote_from_fieldtype -----

CREATE OR REPLACE FUNCTION risco_v2.json_quote_from_fieldtype(p_schema text, p_dbobj text, p_fieldname text, p_jsonvalue jsonb, b_keyvalue_pair boolean)
	RETURNS text
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$
DECLARE
	v_type text;
	v_sql text;
	v_ret text;
BEGIN

	SELECT
	data_type into v_type
	FROM information_schema.columns
	WHERE table_Schema = p_schema
	and table_name = p_dbobj
	and column_name = p_fieldname;

	if v_type = 'integer' or v_type = 'numeric' or v_type = 'double precision' or v_type = 'boolean' or v_type = 'smallint' or v_type = 'bigint' or v_type = 'real'  then
		if b_keyvalue_pair then
			v_ret := format('%I = %s', p_fieldname, p_jsonvalue);
		else
			v_ret := format('%s', p_jsonvalue);
		end if;
	else
		if b_keyvalue_pair then
			v_ret := format('%I = ''%s''', p_fieldname, p_jsonvalue);
		else
			v_ret := format('''%s''', p_jsonvalue);
		end if;
	end if;

	RETURN v_ret;

END;
$BODY$;

ALTER FUNCTION risco_v2.json_quote_from_fieldtype(text, text, text, jsonb, boolean) OWNER to risco_v2;


-- ----- Procedure / function riscov2_dev.quantize2json -----

CREATE OR REPLACE FUNCTION risco_v2.quantize2json(p_creqid character varying, p_layer_name character varying, p_chunks integer, p_vertexcnt integer, p_chunk integer DEFAULT 1)
 RETURNS text
 LANGUAGE 'plpgsql'
 VOLATILE

AS $BODY$
DECLARE
	v_retobj text;

	v_deffilter text;

    v_schema text;
    v_tablename text;
    v_oidfldname text;
    v_adic_flds_str text;

	v_cenx numeric;
	v_ceny numeric;
	v_width numeric;
	v_height numeric;
	v_pixsz numeric;

	v_lyrid uuid;

	v_filter_flag boolean;
	v_adicflds_flag boolean;

    v_sign text := 'RPGIS_050';

    v_sql text;
    v_reqid uuid;

	--v_base_table regclass;
	v_t0 timestamp;
	v_t1 timestamp;
	v_t2 timestamp;
	v_profile boolean;
	v_is_function boolean;

	v_minx numeric;
	v_miny numeric;
	v_maxx numeric;
	v_maxy numeric;

BEGIN
	v_profile := 'f'; -- controle profiling layers

	if v_profile then
		v_t0 := clock_timestamp();
		v_t1 := clock_timestamp();
	end if;

	perform set_config('search_path', 'risco_v2,public', true);

	IF p_chunk < 1 OR p_chunk > p_chunks THEN
        select json_build_object('sign',v_sign,
                'lname', p_layer_name,
                'fcnt', 0,
                'chnk', p_chunk,
                'nchunks', p_chunks,
                'error', 'invalid chunk'
               )::text
        INTO v_retobj;
		RETURN v_retobj;
	END IF;

    v_retobj := NULL;

    v_reqid := uuid(p_creqid);

    SELECT cenx, ceny, wid, hei, pixsz
    INTO v_cenx, v_ceny, v_width, v_height, v_pixsz
    FROM risco_request
	WHERE reqid = v_reqid;

	if v_profile then
		v_t2 := clock_timestamp();
		raise notice '..... timing A: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0);
		v_t1 := v_t2;
	end if;

    SELECT lyrid, schema, dbobjname, oidfname, adic_fields_str, is_function, deffilter
    INTO v_lyrid, v_schema, v_tablename, v_oidfldname, v_adic_flds_str, v_is_function, v_deffilter
    FROM risco_layerview
	WHERE lname = p_layer_name;

	if v_is_function then

		v_minx := v_cenx - (v_width/2.0);
		v_miny := v_ceny - (v_height/2.0);
		v_maxx := v_cenx + (v_width/2.0);
		v_maxy := v_ceny + (v_height/2.0);

	end if;

	if v_profile then
		v_t2 := clock_timestamp();
		raise notice '..... timing B: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0);
		v_t1 := v_t2;
	end if;

	IF NOT v_deffilter IS NULL THEN
		v_filter_flag := true;
	ELSE
		v_filter_flag := false;
	END IF;

	IF v_adic_flds_str IS NULL or length(v_adic_flds_str) = 0 THEN
		v_adicflds_flag := false;
	ELSE
		v_adicflds_flag := true;
	END IF;

    IF v_filter_flag OR v_adicflds_flag THEN

 		v_sql := 'with delsel as (' ||
 			'select oidv, the_geom as snapped_shape ' ||
			--'delete '
			'from risco_request_geometry ' ||
			'WHERE NOT the_geom IS NULL ' ||
			'AND reqid = $13 ' ||
			'AND lyrid = $14 ' ||
			--'returning oidv, the_geom as snapped_shape ' ||
		') ' ||
		'select json_build_object(''sign'',$1, ''fcnt'', count(c.*), ' ||
                '''lname'', $2, ''pxsz'', $3, ''cenx'', $4, ''ceny'', $5, ' ||
                '''chnk'', $6, ''nchunks'', $7, ' ||
                '''cont'', json_object_agg(c.oidv, c.cont) ) ' ||
                'from (select oidv, ' ||
                'json_build_object(''typ'', util_condensed_type(geomtype), ';

        IF v_adicflds_flag THEN

			v_sql := v_sql || '''a'', row_to_json( (select r from (select ' || v_adic_flds_str || ') r ) ), ';

        END IF;

        v_sql := v_sql || '''crds'', gen_coords_elem(snapped_shape, $8, $9, $10) ) cont ' ||
                    'from (select a.*, GeometryType(snapped_shape) geomtype, '
                    'ceil(1.0 * $11 * sum(st_npoints(snapped_shape)) over (order by st_npoints(snapped_shape) desc, oidv) / $12) chnk ' ||
                    'from (select delsel.oidv, delsel.snapped_shape';

        IF v_adicflds_flag THEN
			v_sql := v_sql || ', ' || v_adic_flds_str;
		END IF;

		if v_is_function then

			v_sql := v_sql || ' from ' || v_schema || '.' || v_tablename || '('  || v_minx || ',' || v_miny || ',' || v_maxx || ',' || v_maxy || ') t1 inner join delsel ' ||
				'on t1.' || v_oidfldname || ' = delsel.oidv';

		else

			v_sql := v_sql || ' from ' || v_schema || '.' || v_tablename || ' t1 inner join delsel ' ||
				'on t1.' || v_oidfldname || ' = delsel.oidv';

		end if;

        IF v_filter_flag THEN

			v_sql := v_sql || ' and (' || v_deffilter || ')) a) b where b.chnk = $15) c';

        ELSE

			v_sql := v_sql || ') a) b where b.chnk = $15) c';

        END IF;

		EXECUTE v_sql INTO STRICT v_retobj
		USING v_sign, p_layer_name, v_pixsz, v_cenx, v_ceny, p_chunk, p_chunks,
				v_cenx, v_ceny, v_pixsz,
				p_chunks, p_vertexcnt, v_reqid, v_lyrid, p_chunk;

		if v_profile then
			v_t2 := clock_timestamp();
			raise notice '..... timing C1: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0);
			v_t1 := v_t2;
		end if;

    ELSE

		with delsel as (
			--delete
			select oidv, the_geom as snapped_shape
			from risco_request_geometry
			WHERE NOT the_geom IS NULL
			AND reqid = v_reqid
			AND lyrid = v_lyrid
			-- returning oidv, the_geom as snapped_shape
		)
    	SELECT json_build_object('sign',v_sign, 'fcnt', count(c.*),
			'lname', p_layer_name, 'pxsz', v_pixsz, 'cenx', v_cenx, 'ceny', v_ceny,
			'chnk', p_chunk, 'nchunks', p_chunks,
			'cont', json_object_agg(c.oidv, c.cont) )
			from (
				select oidv,
				json_build_object('typ', util_condensed_type(geomtype),
				'crds', gen_coords_elem(snapped_shape, v_cenx, v_ceny, v_pixsz) ) cont
				from (
					select delsel.*, GeometryType(snapped_shape) geomtype,
					ceil(1.0 * p_chunks * sum(st_npoints(snapped_shape)) over (order by st_npoints(snapped_shape) desc, oidv) / p_vertexcnt) chnk
					from delsel
				) b
				where b.chnk = p_chunk
			) c
		INTO STRICT v_retobj;

		if v_profile then
			v_t2 := clock_timestamp();
			raise notice '..... timing C2: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0);
			v_t1 := v_t2;
		end if;

    END IF;

	RETURN v_retobj;

END;
$BODY$;

ALTER FUNCTION risco_v2.quantize2json(character varying, character varying, integer, integer, integer) OWNER to risco_v2;

GRANT EXECUTE ON FUNCTION risco_v2.quantize2json(character varying, character varying, integer, integer, integer) TO PUBLIC;


-- ----- Procedure / function riscov2_dev.save -----

CREATE OR REPLACE FUNCTION risco_v2.save(p_layer_name text, p_sessionid text, p_payload_json text, opt_mapname text, opt_login text)
	RETURNS jsonb
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$
DECLARE
	v_authorized boolean;
	v_rec record;
	v_rec2 record;
	v_sql text;
	v_operations_list jsonb;
	v_out_list jsonb;
	v_login text;
	v_ret jsonb;
	v_payload json;
	v_featholder_rec record;
	v_properties_rec record;
	v_op_rec record;
	v_op_ret record;
	v_geometry json;
	v_sql_template text;
	v_cnt smallint;
	v_operation text;
	v_item_count smallint;
	v_typ text;
	v_savegeom text;
	v_full_editobj text;
	v_editobj_schema text;
	v_editobj_name text;
	v_fieldvalue_pairs text[];
	v_fieldnames text[];
	v_fieldvalues text[];
	v_final_status text;

BEGIN

	set search_path to risco_v2, public;

	v_operations_list := '[]'::jsonb;

	v_ret := '{ "state": "NOTOK", "reason": "procedure not inited" }'::jsonb;
	v_authorized := false;

	if p_layer_name is null then
		return '{ "state": "NOTOK", "reason": "no layer name given" }'::jsonb;
	end if;
	if p_sessionid is null then
		return '{ "state": "NOTOK", "reason": "no sessionid given" }'::jsonb;
	end if;
	if p_payload_json is null then
		return '{ "state": "NOTOK", "reason": "no JSON payload given" }'::jsonb;
	end if;

	if not opt_mapname is null then

		select * into v_rec
		from risco_map_auth_session
		where mapname = opt_mapname;

		if FOUND then

			if v_rec.do_match_login then

				if opt_login is null then
					return '{ "state": "NOTOK", "reason": "login must match, but no login provided" }'::jsonb;
				end if;

				v_sql := format('select %I from %I.%I where %I = %L and %I = %L and %s', v_rec.login_field,
					v_rec.auth_ctrl_obj_schema, v_rec.auth_ctrl_obj_name,
					v_rec.sessionid_field, p_sessionid, v_rec.login_field, opt_login,
					v_rec.editok_validation_expression);

			else

				v_sql := format('select %I from %I.%I where %I = %L and %s', v_rec.login_field,
					v_rec.auth_ctrl_obj_schema, v_rec.auth_ctrl_obj_name,
					v_rec.sessionid_field, p_sessionid,
					v_rec.editok_validation_expression);

			end if;

		else

			return format('{ "state": "NOTOK", "reason": "no map ''%s'' configured in risco_map_auth_session" }', opt_mapname)::jsonb;

		end if;

		execute v_sql into v_login;
		if not v_login is null then
			v_authorized := true;
		end if;

	end if;

	if not v_authorized then
		return format('{ "state": "NOTOK", "reason": "save attempt unauthorized, sessionid:%s" }', p_sessionid)::jsonb;
	end if;

	v_sql := NULL;

	select  geomfname, oidfname, useridfname, schema, dbobjname, srid, is_function, editobj_schema, editobj_name,
		gisid_field, mark_as_deleted_ts_field, accept_deletion, creation_ts_field
	into v_rec2
	from risco_layerview
	where lower(trim(lname)) = lower(trim(p_layer_name))
	and editable
	and inuse
	and (edit_users is null or v_login = ANY(edit_users));

	if not FOUND then
		return format('{ "state": "NOTOK", "reason": "cannot fetch editable layerview, layername:%s sessionid:%s" }', p_layer_name, p_sessionid)::jsonb;
	end if;

	if v_operation != 'OP_UNDEFINED' then
		return format('{ "state": "NOTOK", "reason": "operation %s prematurely defined (1), sessionid:%s" }', v_operation, p_sessionid)::jsonb;
	end if;

	if not v_rec2.editobj_name is null then

		v_full_editobj := format('%I.%I', editobj_schema, editobj_name);
		v_editobj_schema := editobj_schema;
		v_editobj_name := editobj_name;

	else

		v_full_editobj := format('%I.%I', v_rec2.schema, v_rec2.dbobjname);
		v_editobj_schema := v_rec2.schema;
		v_editobj_name := v_rec2.dbobjname;

	end if;

	if v_editobj_name is null then
		return format('{ "state": "NOTOK", "reason": "layer edit object is not defined, layername:%s sessionid:%s" }', p_layer_name, p_sessionid)::jsonb;
	end if;

	v_payload := p_payload_json::json;
	v_item_count := 0;

	for v_featholder_rec in
		select json_array_elements from json_array_elements(v_payload)
	loop

		v_operation := 'OP_UNDEFINED';

		v_fieldvalue_pairs := '{}';
		v_fieldnames := '{}';
		v_fieldvalues := '{}';

		v_item_count := v_item_count + 1;

		if not (v_featholder_rec.json_array_elements->'gisid') is null and length(v_featholder_rec.json_array_elements->>'gisid')  > 0 then

			SELECT
			data_type into v_typ
			FROM information_schema.columns
			WHERE table_Schema = v_editobj_schema
			and table_name = v_editobj_name
			and column_name = v_rec2.gisid_field;

			if v_rec2.mark_as_deleted_ts_field is null then
				if v_typ = 'integer' or v_typ = 'numeric' or v_typ = 'double precision' or v_typ = 'smallint' or v_typ = 'bigint' or v_typ = 'real' then
					v_sql_template := 'select count(*) from %s where %I = %s';
				else
					v_sql_template := 'select count(*) from %s where %I = ''%s''';
				end if;
				v_sql := format(v_sql_template, v_full_editobj, v_rec2.gisid_field, v_featholder_rec.json_array_elements->>'gisid');
			else
				if v_typ = 'integer' or v_typ = 'numeric' or v_typ = 'double precision' or v_typ = 'smallint' or v_typ = 'bigint' or v_typ = 'real' then
					v_sql_template := 'select count(*) from %s where %I = %s and %I is NULL';
				else
					v_sql_template := 'select count(*) from %s where %I = ''%s'' and %I is NULL';
				end if;
				v_sql := format(v_sql_template, v_full_editobj, v_rec2.gisid_field, v_featholder_rec.json_array_elements->>'gisid', v_rec2.mark_as_deleted_ts_field);
			end if;

			execute v_sql into v_cnt;

			if v_cnt < 1 then
				return format('{ "state": "NOTOK", "reason": "error in data: gisid (%s) not null but active feature not found in %s, sessionid:%s, item:%s" }', v_featholder_rec.json_array_elements->>'gisid', v_full_editobj, p_sessionid, v_item_count)::jsonb;
			end if;

			-- record to edit exists in table, operation is either update or delete; if feature is null, op is delete

			if v_featholder_rec.json_array_elements->'feat'->>'type' != 'Feature' then
				v_operation := 'OP_DELETE';
			else
				v_operation := 'OP_UPDATE';
			end if;

		else

			-- record to edit does not exist in table, operation is insert, feat must be present

			if (v_featholder_rec.json_array_elements->'feat') is null then
				return format('{ "state": "NOTOK", "reason": "no gisid and no feature JSON -- nothing to do, sessionid:%s item:%s" }', p_sessionid, v_item_count)::jsonb;
			else
				v_operation := 'OP_INSERT';
			end if;

		end if;

		v_sql := NULL;

		if v_operation = 'OP_UNDEFINED' then
			return format('{ "state": "NOTOK", "reason": "internal assertion failed: operation unexpectedly undefined, sessionid:%s item:%s" }', p_sessionid, v_item_count)::jsonb;
		end if;

		if v_featholder_rec.json_array_elements->'feat'->>'type' != 'Feature' then

			if v_operation != 'OP_DELETE' then
				return format('{ "state": "NOTOK", "reason": "internal assertion failed: operation %s needs feature JSON, which is null, sessionid:%s item:%s" }', v_operation, p_sessionid, v_item_count)::jsonb;
			end if;

			-- delete statment
			if not v_rec2.accept_deletion then
				return format('{ "state": "NOTOK", "reason": "trying to delete on layer ''%s'' with ''accept_deletion'' flag FALSE, sessionid:%s item:%s" }', p_layer_name, p_sessionid, v_item_count)::jsonb;
			end if;

			if v_rec2.mark_as_deleted_ts_field is null then

				if v_typ = 'integer' or v_typ = 'numeric' or v_typ = 'double precision'
						or v_typ = 'smallint' or v_typ = 'bigint' or v_typ = 'real' then
					v_sql_template := 'delete from %s where %I = %s returning %I oid, %I gisid';
				else
					v_sql_template := 'delete from %s where %I = ''%s'' returning %I oid, %I gisid';
				end if;

				v_sql := format(v_sql_template,
					v_full_editobj,
					v_rec2.gisid_field,
					v_featholder_rec.json_array_elements->>'gisid',
					v_rec2.oidfname,
					v_rec2.gisid_field
				);

			else

				if not v_rec2.useridfname is null then
					v_fieldvalue_pairs := v_fieldvalue_pairs || format('%I = %L', v_rec2.useridfname, v_login);
				end if;

				v_fieldvalue_pairs := v_fieldvalue_pairs || format('%I = %L', v_rec2.mark_as_deleted_ts_field, CURRENT_TIMESTAMP);

				if v_typ = 'integer' or v_typ = 'numeric' or v_typ = 'double precision'
						or v_typ = 'smallint' or v_typ = 'bigint' or v_typ = 'real' then
					v_sql_template := 'update %s set %s where %I = %s and %I is NULL returning %I oid, %I gisid';
				else
					v_sql_template := 'update %s set %s where %I = ''%s'' and %I is NULL returning %I oid, %I gisid';
				end if;

				v_sql := format(v_sql_template,
					v_full_editobj,
					array_to_string(v_fieldvalue_pairs, ', '),
					v_rec2.gisid_field,
					v_featholder_rec.json_array_elements->>'gisid',
					v_rec2.mark_as_deleted_ts_field,
					v_rec2.oidfname,
					v_rec2.gisid_field
				);

			end if;

		else

			if v_operation != 'OP_INSERT' and v_operation != 'OP_UPDATE' then
				return format('{ "state": "NOTOK", "reason": "internal assertion failed: operation %s not compatible with feature JSON presence, which is not null, sessionid:%s" }', v_operation, p_sessionid)::jsonb;
			end if;

			v_savegeom := NULL;

			-- raise notice 'tabela:%, json:% igual:%', v_rec2.srid, v_geometry->'crs', (v_rec2.srid = (v_geometry->>'crs')::int) ;
			v_geometry := v_featholder_rec.json_array_elements->'feat'->'geometry';
			if not v_geometry is null then

				if v_geometry->>'type' != 'Point' then
					return format('{ "state": "NOTOK", "reason": "only point features are supported for now, sessionid:%s" }', p_sessionid)::jsonb;
				end if;

				if v_geometry->>'type' = 'Point' then
					v_savegeom := format('ST_GeomFromText(''POINT(%s %s)'',  %s)', v_geometry->'coordinates'->0, v_geometry->'coordinates'->1, (v_geometry->>'crs'));
				end if;

				if v_rec2.srid != (v_geometry->>'crs')::int then
					v_savegeom := format('ST_Transform(%s,  %s)', v_savegeom, v_rec2.srid);
				end if;

			end if;

			if v_operation = 'OP_INSERT' then

				-- insert statment

				if not v_savegeom is null then
					v_fieldnames := v_fieldnames || format('%I', v_rec2.geomfname);
					v_fieldvalues := v_fieldvalues || format('%s', v_savegeom);
				end if;

				if not (v_featholder_rec.json_array_elements->'feat'->'properties') is null then

					for v_properties_rec in
						select key, value from json_each_text(v_featholder_rec.json_array_elements->'feat'->'properties')
					loop
						v_fieldnames := v_fieldnames || key;
						v_fieldvalues := v_fieldvalues || json_quote_from_fieldtype(v_editobj_schema, v_editobj_name, key, value, false);
					end loop;

				end if;

				if not v_rec2.useridfname is null then
					v_fieldnames := v_fieldnames || v_rec2.useridfname;
					v_fieldvalues := v_fieldvalues || v_login;
				end if;

				if not v_rec2.creation_ts_field is null then
					v_fieldnames := v_fieldnames || v_rec2.creation_ts_field;
					v_fieldvalues := v_fieldvalues || format('%L', CURRENT_TIMESTAMP);
				end if;

				v_sql_template := 'insert into %I.%I (%s) values (%s) returning %I oid, %I gisid';
				v_sql := format(
					v_sql_template,
					v_editobj_schema,
					v_editobj_name,
					array_to_string(v_fieldnames, ', '),
					array_to_string(v_fieldvalues, ', '),
					v_rec2.oidfname,
					v_rec2.gisid_field
				);

			elsif v_operation = 'OP_UPDATE' then

				if not v_rec2.mark_as_deleted_ts_field is null then

					-- mark previous version as deleted and insert new record version

					if v_typ = 'integer' or v_typ = 'numeric' or v_typ = 'double precision'
							or v_typ = 'smallint' or v_typ = 'bigint' or v_typ = 'real' then
						v_sql_template := 'update %s set %I = %L where %I = %s and %I is NULL';
					else
						v_sql_template := 'update %s set %I = %L where %I = ''%s'' and %I is NULL';
					end if;

					v_sql := format(v_sql_template,
						v_full_editobj,
						v_rec2.mark_as_deleted_ts_field,
						CURRENT_TIMESTAMP,
						v_rec2.gisid_field,
						v_featholder_rec.json_array_elements->>'gisid',
						v_rec2.mark_as_deleted_ts_field
					);

					-- .... and insert new record version

					if not v_savegeom is null then
						v_fieldnames := v_fieldnames || format('%I', v_rec2.geomfname);
						v_fieldvalues := v_fieldvalues || format('%s', v_savegeom);
					end if;

					if not (v_featholder_rec.json_array_elements->'feat'->'properties') is null then

						for v_properties_rec in
							select key, value from json_each_text(v_featholder_rec.json_array_elements->'feat'->'properties')
						loop
							v_fieldnames := v_fieldnames || key;
							v_fieldvalues := v_fieldvalues || json_quote_from_fieldtype(v_editobj_schema, v_editobj_name, key, value, false);
						end loop;

					end if;

					if not v_rec2.useridfname is null then
						v_fieldnames := v_fieldnames || v_rec2.useridfname;
						v_fieldvalues := v_fieldvalues || v_login;
					end if;

					if not v_rec2.creation_ts_field is null then
						v_fieldnames := v_fieldnames || v_rec2.creation_ts_field;
						v_fieldvalues := v_fieldvalues || format('%L', CURRENT_TIMESTAMP);
					end if;

					v_sql_template := 'insert into %I.%I (%s) values (%s) returning %I oid, %I gisid';
					v_sql := format(
						v_sql_template,
						v_editobj_schema,
						v_editobj_name,
						array_to_string(v_fieldnames, ', '),
						array_to_string(v_fieldvalues, ', '),
						v_rec2.oidfname,
						v_rec2.gisid_field
					);

				else

					-- SIMPLE update statment

					if not v_savegeom is null then
						v_fieldvalue_pairs := v_fieldvalue_pairs || format('%I = %s', v_rec2.geomfname, v_savegeom);
					end if;

					if not (v_featholder_rec.json_array_elements->'feat'->'properties') is null then

						for v_properties_rec in
							select key, value from json_each_text(v_featholder_rec.json_array_elements->'feat'->'properties')
						loop
							v_fieldvalue_pairs := v_fieldvalue_pairs || json_quote_from_fieldtype(v_editobj_schema, v_editobj_name, v_properties_rec.key, v_properties_rec.value, true);
						end loop;

					end if;

					if array_length(v_fieldvalue_pairs, 1) = 0 then
						return format('{ "state": "NOTOK", "reason": "update operation using void data, unchanged record, sessionid:%s" }', p_sessionid)::jsonb;
					end if;

					if v_typ = 'integer' or v_typ = 'numeric' or v_typ = 'double precision'
							or v_typ = 'smallint' or v_typ = 'bigint' or v_typ = 'real' then
						v_sql_template := 'update %s set %s where %I = %s returning %I oid, %I gisid';
					else
						v_sql_template := 'update %s set %s where %I = ''%s'' returning %I oid, %I gisid';
					end if;

					v_sql := format(v_sql_template,
						v_full_editobj,
						array_to_string(v_fieldvalue_pairs, ', '),
						v_rec2.gisid_field,
						v_featholder_rec.json_array_elements->>'gisid',
						v_rec2.oidfname,
						v_rec2.gisid_field
					);

				end if;

			else

				return format('{ "state": "NOTOK", "reason": "unexpected and invalid path in save function, op:%s, sessionid:%s" }', v_operation, p_sessionid)::jsonb;

			end if;

		end if;

		if v_sql is NULL then
			return format('{ "state": "NOTOK", "reason": "internal assertion failed: operation %s SQL statement is null, sessionid:%s, item:%s" }', v_operation, p_sessionid, v_item_count)::jsonb;
		else
			v_operations_list = v_operations_list || format('{ "op": "%s", "sql": "%s" }', v_operation, v_sql)::jsonb;
		end if;

	end loop;

	-- Execute operations list, return oid,and gisid for each

	v_out_list := '[]'::jsonb;
	v_final_status := 'NOTOK';

	for v_op_rec in
		select jsonb_array_elements from jsonb_array_elements(v_operations_list)
	loop

		begin

			execute v_op_rec.jsonb_array_elements->>'sql' into v_op_ret;

			v_final_status := 'OK';

			v_out_list = v_out_list || format('{ "state": "OK", "op": "%s", "oid": "%s", "gisid": "%s" }', v_op_rec.jsonb_array_elements->>'op', v_op_ret.oid, v_op_ret.gisid)::jsonb;

		exception
			when others then

				insert into risco_save_dbgmsgs (msg) values (format('%s, %s, sql:%s', SQLERRM, SQLSTATE, v_op_rec.jsonb_array_elements->>'sql'));
				v_out_list = v_out_list || format('{ "state": "NOTOK", "op": "%s", "sql": "%s" }', v_op_rec.jsonb_array_elements->>'op', v_op_rec.jsonb_array_elements->>'sql')::jsonb;

		end;

	end loop;

	return format('{ "state": "%s", "results": %s }', v_final_status, v_out_list)::jsonb;

END;
$BODY$;

ALTER FUNCTION risco_v2.save(text, text, text, text, text) OWNER to risco_v2;


-- ----- Procedure / function riscov2_dev.truncate_requests -----

CREATE OR REPLACE FUNCTION risco_v2.truncate_requests()
	RETURNS void
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$

BEGIN

	perform set_config('search_path', 'risco_v2,public', true);

   	delete from risco_request;

    delete from risco_request_geometry;

    delete from risco_msgs;

END;
$BODY$;

ALTER FUNCTION risco_v2.truncate_requests() OWNER TO risco_v2;


-- ----- Procedure / function riscov2_dev.util_condensed_type -----

CREATE OR REPLACE FUNCTION risco_v2.util_condensed_type(p_geom_type_str character varying)
 RETURNS text
 LANGUAGE 'plpgsql'
 VOLATILE
AS $body$

DECLARE
	v_ret text;
BEGIN

	if p_geom_type_str = 'LINESTRING' then
	  v_ret := 'line';
	elsif p_geom_type_str = 'POINT' then
	  v_ret := 'point';
	elsif p_geom_type_str = 'MULTIPOINT' then
	  v_ret := 'mpoint';
	elsif p_geom_type_str = 'POLYGON' then
	  v_ret := 'poly';
	elsif p_geom_type_str = 'MULTILINESTRING' then
	  v_ret := 'mline';
	elsif p_geom_type_str = 'MULTIPOLYGON' then
	  v_ret := 'mpoly';
	end if;

    return v_ret;

END;

$body$;

alter function risco_v2.util_condensed_type(character varying) owner to risco_v2;

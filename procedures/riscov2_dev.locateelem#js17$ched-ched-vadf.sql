CREATE OR REPLACE FUNCTION riscov2_dev.locateelem(p_mapname character varying(64), p_lyr_name character varying(64), p_gisid character varying)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
AS $BODY$
declare
	v_out_srid integer;
	v_row_lyrs record;	
	v_db_obj text;
	v_template text;
	v_sql text;
	v_ret jsonb;
begin
	set search_path to riscov2_dev, public;
	
	v_ret := null;
	
	select srid into v_out_srid
	from risco_map
	where mapname = p_mapname;
	
	select is_function, "schema", dbobjname, editobj_schema, editobj_name, oidfname, geomfname, gisid_field into v_row_lyrs
	from risco_layerview
	where lname = p_lyr_name
	and inuse;
	
	if v_row_lyrs.is_function then
		v_db_obj := format('%s.%s', v_row_lyrs.editobj_schema, v_row_lyrs.editobj_name);
	else
		v_db_obj := format('%s.%s', v_row_lyrs.schema, v_row_lyrs.dbobjname);
	end if;
	
	v_template := 'select json_build_object(''lname'', %L, ''oidv'', oidv, ''bbox'', json_build_array(st_xmin(the_geom), st_ymin(the_geom), st_xmax(the_geom), st_ymax(the_geom))) from (select %I oidv, %I the_geom from %s where %I = %L) a';
	
	v_sql := format(v_template, p_lyr_name, v_row_lyrs.oidfname, v_row_lyrs.geomfname, v_db_obj, v_row_lyrs.gisid_field, p_gisid);
	
	-- raise notice '%', v_sql;
	
	execute v_sql into v_ret;
	
	return v_ret;

END;
$BODY$;

ALTER FUNCTION riscov2_dev.locateelem(character varying(64), character varying(64), character varying)
    OWNER TO sup_ap;

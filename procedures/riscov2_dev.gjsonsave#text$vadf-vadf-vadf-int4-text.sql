CREATE OR REPLACE FUNCTION riscov2_dev.gjsonsave(p_layer_name character varying, p_gisid character varying, p_userid character varying, p_epsg integer, p_geojson text)
	RETURNS text
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$
DECLARE
	v_sql text;
	v_sql_template text;
	v_geomfname text;
	v_oidfname text;
	v_useridfname text;
	v_tschema text;
	v_tname text;
	v_srid integer;
	v_geojson json;
	v_geom json;
	v_cnt integer;
	v_cnt2 integer;
	v_savegeom text;
	v_gisid text;
	v_user_validation_ops text;
	v_user_priv text;
BEGIN

	if v_geojson->>'type' != 'Feature' then
		return 'NOFEAT';
	end if;

	v_geom := v_geojson->'geometry';
	if v_geom->>'type' != 'Point' then
		return 'UNSUP_GEOMTYPE';
	end if;

	perform set_config('search_path', 'riscov2_dev,public', true);

	select  geomfname, oidfname, useridfname, schema, dbobjname, srid, user_validation_ops
	into v_geomfname, v_oidfname, v_useridfname, v_tschema, v_tname, v_srid, v_user_validation_ops
	from risco_layerview
	where lower(lname) = lower(p_layer_name)
	and inuse;

	if length(v_user_validation_ops) > 0 and v_user_validation_ops != 'WRITE' and v_user_validation_ops != 'BOTH' then
		return 'READONLY_LAYER';
	end if;

	v_geojson := p_geojson::json;
	
	if length(p_gisid)  > 0 then
		v_sql_template := 'select count(*) from %I.%I where %I = %L';
		v_sql := format(v_sql_template, v_tschema, v_tname, v_oidfname, p_gisid);
		execute v_sql into v_cnt;
	else
		v_cnt := 0;
	end if;

	if length(v_user_validation_ops) > 0 and (v_user_validation_ops = 'WRITE' or v_user_validation_ops = 'BOTH') then

		if v_cnt > 0 then -- UPDATE
			v_user_priv := 'UPDATE';
		else
			v_user_priv := 'INSERT';
		end if;

		select count(*) into v_cnt2
		from information_schema.role_table_grants
		where table_catalog = 'bdgc' -- > !! SUBSTITUIR !!
		and table_schema = v_tschema
		and table_name = v_tname
		and grantee = p_userid
		and privilege_type = v_user_priv;

		if v_cnt2 > 0 then
			return 'UNAUTHORIZED';
		end if;
			
	end if;

	if p_epsg != v_srid then
		if v_geom->>'type' = 'Point' then
			v_savegeom := format('ST_Transform(ST_GeomFromText(''POINT(%s %s)'', %L),  %L)', v_geom->'coordinates'->0, v_geom->'coordinates'->1, p_epsg, v_srid);
		end if;
	else
		if v_geom->>'type' = 'Point' then
			v_savegeom := format('ST_GeomFromText(''POINT(%s %s)'',  %L)', v_geom->'coordinates'->0, v_geom->'coordinates'->1, v_srid);
		end if;
	end if;
	
	if v_cnt > 0 then
		v_sql_template := 'update %I.%I set %I = %L, %I = %L where %I = %L';
		v_sql := format(v_sql_template, v_tschema, v_tname, v_geomfname, v_savegeom, v_useridfname, p_userid, v_oidfname, p_gisid);
		execute v_sql;
		v_gisid := p_gisid;
	else
		v_sql_template := 'insert into %I.%I (%I, %I) values (%L, %L) returning %I';
		v_sql := format(v_sql_template, v_tschema, v_tname, v_geomfname, v_useridfname, v_savegeom, p_userid, v_oidfname);
		execute v_sql into v_gisid;
	end if;

	RETURN v_gisid;

END;

$BODY$;

ALTER FUNCTION riscov2_dev.gjsonsave(p_layer_name character varying, p_gisid character varying, p_userid character varying, p_epsg integer, p_geojson text) OWNER to sup_ap;
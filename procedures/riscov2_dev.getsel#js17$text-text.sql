CREATE OR REPLACE FUNCTION riscov2_dev.getsel(p_selname text, p_selcode text)
	RETURNS jsonb
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$
DECLARE
	v_ret jsonb;
	v_rec record;
	v_partial jsonb;
	v_box jsonb;
	v_sql_outer_template text;
	v_qry text;	
	v_box_template text;
BEGIN

	set search_path to riscov2_dev, public;

	v_ret := '{ "state": "NOTOK" }'::jsonb;
	v_sql_outer_template := 'select json_agg(json_strip_nulls(row_to_json(t))) from (%s) t';


	select "schema", selobjectstable,  selobj_code_field, 
		selobj_gisid_field, selobj_gislabel_field, selobj_style_field,
		lyr_schema, lyr_objname, lyr_geom_fname, lyr_gisid_fname into v_rec
	from risco_selections
	where selname = p_selname;

	if FOUND then

		if v_rec.selobj_style_field is null then

			v_qry := format('select %I gisid, %I label from %I.%I where %I = %L', v_rec.selobj_gisid_field, v_rec.selobj_gislabel_field, v_rec.schema, v_rec.selobjectstable, v_rec.selobj_code_field, p_selcode);

		else

			v_qry := format('select %I gisid, %I label, %I style from %I.%I where %I = %L', v_rec.selobj_gisid_field, v_rec.selobj_gislabel_field, v_rec.selobj_style_field, v_rec.schema, v_rec.selobjectstable, v_rec.selobj_code_field, p_selcode);

		end if;

		v_qry := format(v_sql_outer_template, v_qry);
		execute v_qry into v_partial;


		v_box_template := 'select json_build_array(st_xmin(s), st_ymin(s), st_xmax(s), st_ymax(s)) ' ||
			'from ( ' ||
			'select st_expand(ST_Extent(%I), 20) s ' ||
			'from %I.%I a ' ||
			'join %I.%I b ' ||
			'on a.%I = b.%I::text ' ||
			'where a.%I = %L) a';

		v_qry := format(v_box_template, v_rec.lyr_geom_fname, v_rec.schema, v_rec.selobjectstable, v_rec.lyr_schema, v_rec.lyr_objname, 
				v_rec.selobj_gisid_field, v_rec.lyr_gisid_fname, v_rec.selobj_code_field, p_selcode);
		execute v_qry into v_box;

		v_ret := format('{ "state": "OK", "selcode": "%s", "box": %s, "results": %s }', p_selcode, v_box, v_partial)::jsonb;

	end if;	

	RETURN v_ret;

END;
$BODY$;

ALTER FUNCTION riscov2_dev.getsel(text, text) OWNER to sup_ap;;
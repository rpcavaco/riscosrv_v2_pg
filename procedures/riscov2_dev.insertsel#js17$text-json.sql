CREATE OR REPLACE FUNCTION riscov2_dev.insertsel(p_selname text, p_seldata json)
	RETURNS jsonb
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$
DECLARE
	v_rec record;
	v_ret jsonb;
	v_desc text;
	v_id text;
	v_sql text;
	v_i json;
	v_cnt int;
BEGIN

	set search_path to riscov2_dev, public;

	v_ret := '{ "state": "NOTOK" }'::jsonb;
	v_cnt := 0;

	select "schema", seltable, selobjectstable, sel_code_field, sel_desc_field, selobj_code_field, 
		selobj_gisid_field, selobj_gislabel_field into v_rec
	from risco_selections
	where selname = p_selname;

	if FOUND then

		v_desc := p_seldata->>'desc';
		v_id := uuid_generate_v4()::text;

		v_sql := format('insert into %I.%I (%I, %I) values (%L, %L)', v_rec.schema, v_rec.seltable, v_rec.sel_code_field, v_rec.sel_desc_field, v_id, v_desc);
		execute v_sql;

		FOR v_i IN SELECT * FROM json_array_elements(p_seldata->'elems')
		LOOP
			v_sql := format('insert into %I.%I (%I, %I, %I) values (%L, %L, %L)', v_rec.schema, v_rec.selobjectstable, v_rec.selobj_code_field, v_rec.selobj_gisid_field, v_rec.selobj_gislabel_field, v_id, v_i->>'gisid', v_i->>'gislabel');
			execute v_sql;
			v_cnt := v_cnt + 1;
		END LOOP;

		v_ret := format('{ "state": "OK", "selcode": "%s", "results": %s }', v_id, v_cnt)::jsonb;

	end if;

	RETURN v_ret;

END;
$BODY$;

ALTER FUNCTION riscov2_dev.insertsel(text, json) OWNER to sup_ap;;
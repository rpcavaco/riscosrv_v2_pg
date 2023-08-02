CREATE OR REPLACE FUNCTION riscov2_dev.alphastats(p_key text, p_options json)
	RETURNS jsonb
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$
DECLARE
	v_ret jsonb;
	v_sch text;
	v_oname text;
	v_cols text[];
	v_col text;
	v_sql text;
	v_int integer;
	v_total integer;
	v_counts json;
	v_mode text;

BEGIN

	set search_path to riscov2_dev, public;

	v_ret := '{}'::jsonb;
	v_mode := 'NONE';

	select dataobjschema, dataobjname, regexp_split_to_array(allowedcols, '[\s\,]+') cols into v_sch, v_oname, v_cols
	from risco_stats
	where key = p_key;
	v_total := 0;

	if FOUND then

		foreach v_col in ARRAY v_cols
		loop

			v_ret := jsonb_set(v_ret, array[v_col], '{}'::jsonb, true); 

			v_sql := format('select sum(%s) from %s.%s', v_col, v_sch, v_oname);
			raise notice 'v_sql:%', v_sql;

			begin
				execute v_sql into v_int;
				v_mode := 'NUMERIC';
			exception
				WHEN SQLSTATE '42883' THEN --- function does not exist - not applicable to data type (non-numeric)
					v_mode := 'NON-NUMERIC';
			end;

			if v_mode = 'NON-NUMERIC' then

				v_sql := format('select count(*) from (
					select distinct %s valor
					from %s.%s
				) a', v_col, v_sch, v_oname);

				execute v_sql into v_int;
				v_ret := jsonb_set(v_ret, array[v_col, 'classescount'], to_jsonb(v_int), true); 

				v_sql := format('select json_object_agg(valor, cnt) from (
				select %s valor, count(*) cnt
				from %s.%s
				where not %1$s is null
				group by %1$s
				) a', v_col, v_sch, v_oname);

				execute v_sql into v_counts;

				v_ret := jsonb_set(v_ret, array[v_col, 'classcounts'], to_jsonb(v_counts), true); 

				v_sql := format('select count(*) cnt
				from %s.%s
				where not %s is null', v_sch, v_oname, v_col);

				execute v_sql into v_total;

				v_ret := jsonb_set(v_ret, array[v_col, 'sumofclasscounts'], to_jsonb(v_total), true); 


			end if;

		end loop;


	end if;


	return v_ret;

END;
$BODY$;

ALTER FUNCTION riscov2_dev.alphastats(text, json) OWNER to sup_ap;
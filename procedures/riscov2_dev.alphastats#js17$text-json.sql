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
	v_labelcols text[];
	v_col text;
	v_label text;
	v_sql text;
	v_sql_proto text;
	v_sql_proto_templ text;
	v_sql1 text;
	v_sql2 text;
	v_sql3 text;
	v_int integer;
	v_total integer;
	v_counts json;
	v_mode text;
	v_from text;
	v_joinschema text; 
	v_joinobj text; 
	v_join_expression text;
	v_filter_expression text;
	v_geomfname text;
	v_outer_join boolean;
	v_outsrid int;

BEGIN

	set search_path to riscov2_dev, public;

	v_ret := '{}'::jsonb;
	v_mode := 'NONE';

	select dataobjschema, dataobjname,
		regexp_split_to_array(allowedcols, '[\s\,]+') cols, 
		regexp_split_to_array(labelcols, '[\s\,]+') labelcols,
		joinschema, joinobj, join_expression, outer_join, geomfname, filter_expression
	into v_sch, v_oname, v_cols, v_labelcols,
		 v_joinschema, v_joinobj, v_join_expression, v_outer_join, v_geomfname,
		 v_filter_expression
	from risco_stats
	where key = p_key;
	v_total := 0;

	v_outsrid := p_options->>'outsrid';
	-- raise notice 'v_geomfname:% p_key:% outsrid:%', v_geomfname, p_key, v_outsrid; 

	if FOUND then

		for i in 1..array_length(v_cols, 1)
		loop
			v_col := v_cols[i];

			v_label := null;
			if not v_labelcols is null and array_length(v_labelcols, 1) >= i then 
				v_label := v_labelcols[i];
			end if;

			v_ret := jsonb_set(v_ret, array[v_col], '{}'::jsonb, true); 

			v_sql := format('select sum(%s) from %s.%s', v_col, v_sch, v_oname);
			-- raise notice 'v_sql:%', v_sql;

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

				v_from := format('%s.%s a', v_sch, v_oname);
				if not v_joinschema is null and length(v_joinschema) > 0 and 
						not v_joinobj is null and length(v_joinobj) > 0 and
						not v_join_expression is null and length(v_join_expression) > 0 then
					if not v_outer_join is null and v_outer_join then
						v_from := v_from || ' left outer join ';
					else
						v_from := v_from || ' inner join ';
					end if;
					v_from := format('%s %s.%s b on %s', v_from, v_joinschema, v_joinobj, v_join_expression);
				end if;

				v_sql1 := 'select json_object_agg(val, json_build_object(''cnt'', cnt';
				v_sql2 := 'select %s val,';
				v_sql3 := v_col;

				if not v_label is null then
					v_sql1 := v_sql1 || ', ''lbl'', lbl';
					v_sql2 := v_sql2 || format(' %s lbl,', v_label);
					v_sql3 := v_sql3 || format(', %s', v_label);
				end if;

				if not v_geomfname is null then
					v_sql1 := v_sql1 || ', ''xmin'', ST_XMin(env), ''ymin'', ST_YMin(env), ''xmax'', ST_XMax(env), ''ymax'', ST_yMax(env)';
					if not v_outsrid is null then
						v_sql2 := v_sql2 || format(' st_extent(st_transform(%s, %s)) env,', v_geomfname, v_outsrid);
					else
						v_sql2 := v_sql2 || format(' st_extent(%s) env,', v_geomfname);
					end if;
					-- v_sql3 := v_sql3 || format(', %s', v_geomfname);
				end if;

				if v_filter_expression is null then
					v_sql_proto_templ := '%s)) from (%s count(*) cnt from %%s group by %s) c';
				else 
					v_sql_proto_templ := '%s)) from (%s count(*) cnt from %%s where %%s group by %s) c';
				end if;
				v_sql_proto := format(v_sql_proto_templ, v_sql1, v_sql2, v_sql3);

				-- raise notice 'v_sql_proto >>%<<', v_sql_proto;

				if v_filter_expression is null then
					v_sql := format(v_sql_proto, v_col, v_from, v_col);
				else
					v_sql := format(v_sql_proto, v_col, v_from, v_filter_expression);
				end if;

				-- raise notice 'v_sql >>%<<', v_sql;

				execute v_sql into v_counts;

				v_ret := jsonb_set(v_ret, array[v_col, 'classes'], to_jsonb(v_counts), true); 

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
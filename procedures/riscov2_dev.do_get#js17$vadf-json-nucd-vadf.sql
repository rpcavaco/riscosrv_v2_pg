CREATE OR REPLACE FUNCTION riscov2_dev.do_get(p_alias_name character varying, p_keyword character varying, p_filter_values json, p_pointbuffer_m numeric, p_lang character varying)
 RETURNS jsonb
 LANGUAGE 'plpgsql'
 VOLATILE
AS $body$
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

	perform set_config('search_path', 'riscov2_dev,public', true);

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
									
			--raise notice '%', v_qry;
	
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
	--raise notice 'v_from:%', v_from;
	
		v_qry := format('select %s from %s where %s', v_flds, v_from, v_row2.filter_expression);
		if not v_row.filteradapt is null and length(v_row.filteradapt) > 0 then 

			select array(select json_array_elements_text(p_filter_values)) into v_arr1;			
			select format(v_row.filteradapt, variadic v_arr1) into v_fmt_interm; 
		
			select array(select json_array_elements_text(v_fmt_interm::json)) into v_arr2;
		
			v_qry := format(v_qry, variadic v_arr2);
		else
			v_qry := format(v_qry, json_array_elements_text(p_filter_values));
		end if;
		
	-- raise notice 'v_qry:%', v_qry;
	
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
$body$;

alter function riscov2_dev.do_get(character varying, character varying, json, numeric, character varying) owner to sup_ap;

GRANT EXECUTE ON FUNCTION riscov2_dev.do_get(character varying, character varying, json, numeric, character varying) TO PUBLIC;
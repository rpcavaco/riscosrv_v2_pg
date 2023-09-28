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

	set search_path to riscov2_dev, public;

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
				
					if v_filter_expression is null then
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

				if v_filter_expression is null then
					v_sql := format(v_sql_proto, v_col, v_from, v_col);
				else
					v_sql := format(v_sql_proto, v_col, v_from, v_filter_expression, v_filter_expression);
				end if;

				-- raise notice 'v_sql >>%<<', v_sql;

				execute v_sql into v_counts;

				v_ret := jsonb_set(v_ret, array[v_col, 'classes'], to_jsonb(v_counts), true); 

			end if;

		end loop;


	end if;


	return v_ret;

END;
$BODY$;

ALTER FUNCTION riscov2_dev.alphastats(text, json) OWNER to sup_ap;
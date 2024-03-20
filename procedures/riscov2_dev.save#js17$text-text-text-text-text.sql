CREATE OR REPLACE FUNCTION riscov2_dev.save(p_layer_name text, p_sessionid text, p_payload_json text, opt_mapname text, opt_login text)
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
	v_op_retadic record;	
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
	v_retadic_qry text;

BEGIN

	set search_path to riscov2_dev, public;
	
	v_login := NULL;
	if not opt_login is null and opt_login != '' then	
		select  arr[array_upper(arr, 1)] into v_login
		from (
			select regexp_split_to_array(opt_login, E'\\\\') arr
		) a;
	end if;

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

				if v_login is null or v_login = '' then
					return '{ "state": "NOTOK", "reason": "login must match, but no login provided" }'::jsonb;
				end if;

				v_sql := format('select %I from %I.%I where %I = %L and %I = %L and %s', v_rec.login_field, 
					v_rec.auth_ctrl_obj_schema, v_rec.auth_ctrl_obj_name, 
					v_rec.sessionid_field, p_sessionid, v_rec.login_field, v_login, 
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
		gisid_field, mark_as_deleted_ts_field, accept_deletion, creation_ts_field, save_ret_fields_str
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

		v_full_editobj := format('%I.%I', v_rec2.editobj_schema, v_rec2.editobj_name);
		v_editobj_schema := v_rec2.editobj_schema;
		v_editobj_name := v_rec2.editobj_name;

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
					v_sql_template := 'delete from %s where %I = %s returning %I oid, %I::text gisid';
				else
					v_sql_template := 'delete from %s where %I = ''%s'' returning %I oid, %I::text gisid';
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
					v_sql_template := 'update %s set %s where %I = %s and %I is NULL returning %I oid, %I::text gisid';
				else
					v_sql_template := 'update %s set %s where %I = ''%s'' and %I is NULL returning %I oid, %I::text gisid';
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

				v_sql_template := 'insert into %I.%I (%s) values (%s) returning %I oid, %I::text gisid';
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

					v_sql_template := 'insert into %I.%I (%s) values (%s) returning %I oid, %I::text gisid';
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
						v_sql_template := 'update %s set %s where %I = %s returning %I oid, %I::text gisid';
					else
						v_sql_template := 'update %s set %s where %I = ''%s'' returning %I oid, %I::text gisid';
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

			if not v_rec2.save_ret_fields_str is null then

				v_retadic_qry := format('select (row_to_json(a))::text as adicjson from (select %s from %s where %I = %L) a', v_rec2.save_ret_fields_str, v_full_editobj, v_rec2.gisid_field, v_op_ret.gisid);

				execute v_retadic_qry into v_op_retadic;

				v_out_list = v_out_list || format('{ "state": "OK", "op": "%s", "oid": "%s", "gisid": "%s", "cont": %s}', v_op_rec.jsonb_array_elements->>'op', v_op_ret.oid, v_op_ret.gisid, v_op_retadic.adicjson)::jsonb;

			else

				v_out_list = v_out_list || format('{ "state": "OK", "op": "%s", "oid": "%s", "gisid": "%s" }', v_op_rec.jsonb_array_elements->>'op', v_op_ret.oid, v_op_ret.gisid)::jsonb;

			end if;

		exception
			when others then

				insert into risco_save_dbgmsgs (msg) values (format('%s, %s, sql:%s', SQLERRM, SQLSTATE, v_op_rec.jsonb_array_elements->>'sql'));
				v_out_list = v_out_list || format('{ "state": "NOTOK", "op": "%s", "sql": "%s" }', v_op_rec.jsonb_array_elements->>'op', v_op_rec.jsonb_array_elements->>'sql')::jsonb;

		end;

	end loop;

	return format('{ "state": "%s", "results": %s }', v_final_status, v_out_list)::jsonb;

END;
$BODY$;

ALTER FUNCTION riscov2_dev.save(text, text, text, text, text) OWNER to sup_ap;
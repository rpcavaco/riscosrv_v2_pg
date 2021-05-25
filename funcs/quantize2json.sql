CREATE OR REPLACE FUNCTION risco_v2_publico_dev.quantize2json(p_creqid character varying, p_layer_name character varying, p_chunks integer, p_vertexcnt integer, p_chunk integer DEFAULT 1)
 RETURNS text
 LANGUAGE plpgsql
AS $function$

DECLARE
	v_retobj text;
	
	v_filter_fname text;
	v_filter_value text;
	v_filter_lname text;

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

BEGIN

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
    
    SELECT cenx, ceny, wid, hei, pixsz,
			filter_lname, filter_fname, filter_value
    INTO v_cenx, v_ceny, v_width, v_height, v_pixsz,
			v_filter_fname, v_filter_lname, v_filter_value
    FROM risco_v2_publico_dev.risco_request
	WHERE reqid = v_reqid;

    SELECT lyrid, schema, tname, oidfname, adic_fields_str
    INTO v_lyrid, v_schema, v_tablename, v_oidfldname, v_adic_flds_str
    FROM risco_v2_publico_dev.risco_layerview
	WHERE lname = p_layer_name;
	
	IF NOT v_filter_fname IS NULL and LENGTH(v_filter_fname) > 0 
		AND LOWER(v_filter_lname) = LOWER(p_layer_name)
	THEN
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
			'from risco_v2_publico_dev.risco_request_geometry ' ||
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
                'json_build_object(''typ'', risco_v2_publico_dev.util_condensed_type(geomtype), ';
                
        IF v_adicflds_flag THEN
			
			v_sql := v_sql || '''a'', row_to_json( (select r from (select ' || v_adic_flds_str || ') r ) ), ';
        
        END IF;
    
        v_sql := v_sql || '''crds'', risco_v2_publico_dev.gen_coords_elem(snapped_shape, $8, $9, $10) ) cont ' ||
                    'from (select a.*, GeometryType(snapped_shape) geomtype, '                
                    'ceil(1.0 * $11 * sum(st_npoints(snapped_shape)) over (order by st_npoints(snapped_shape) desc, oidv) / $12) chnk ' ||   
                    'from (select delsel.oidv, delsel.snapped_shape';            
                    
        IF v_adicflds_flag THEN
			v_sql := v_sql || ', ' || v_adic_flds_str;
		END IF;

		v_sql := v_sql || ' from ' || v_schema || '.' || v_tablename || ' t1 inner join delsel ' ||
				'on t1.' || v_oidfldname || ' = delsel.oidv';
	
		/*v_sql := v_sql || ' from ' || v_schema || '.' || v_tablename || ' t1 inner join risco_v2_publico_dev.risco_request_geometry t2 ' ||
				'on t1.' || v_oidfldname || ' = t2.oidv ' ||                   
				'WHERE NOT t2.the_geom IS NULL AND t2.reqid = $13 ' ||
				'AND lyrid = $14' ||
				''; */
                    
        IF v_filter_flag THEN

			v_sql := v_sql || ' and t1.' || p_filter_fname || ' = $15) a) b where b.chnk = $16) c';

			INSERT INTO risco_v2_publico_dev.risco_msgs (severity, context, msg, params)
			VALUES
			(0, 'risco_v2_publico_dev.quantize2json A', v_sql, json_build_array(v_sign, p_layer_name, v_pixsz, v_cenx, v_ceny, p_chunk, p_chunks, 
					v_cenx, v_ceny, v_pixsz,                     
					p_chunks, p_vertexcnt, v_reqid, v_lyrid, v_filter_value, p_chunk));
		
			/*RAISE EXCEPTION 'a %, %, %, %, %, %, %, %, %, %, %, %, %, %, %, %',
					v_sign, p_layer_name, v_pixsz, v_cenx, v_ceny, p_chunk, p_chunks, 
					v_cenx, v_ceny, v_pixsz,                     
					p_chunks, p_vertexcnt, v_reqid, v_lyrid, v_filter_value, p_chunk;*/
			
			EXECUTE v_sql INTO STRICT v_retobj 
			USING v_sign, p_layer_name, v_pixsz, v_cenx, v_ceny, p_chunk, p_chunks, 
					v_cenx, v_ceny, v_pixsz,                     
					p_chunks, p_vertexcnt, v_reqid, v_lyrid, v_filter_value, p_chunk;
					

        ELSE
        
			v_sql := v_sql || ') a) b where b.chnk = $15) c';

			INSERT INTO risco_v2_publico_dev.risco_msgs (severity, context, msg, params)
			VALUES
			(0, 'risco_v2_publico_dev.quantize2json B', v_sql, json_build_array(v_sign, p_layer_name, v_pixsz, v_cenx, v_ceny, p_chunk, p_chunks, 
					v_cenx, v_ceny, v_pixsz,                     
					p_chunks, p_vertexcnt, v_reqid, v_lyrid, p_chunk));
		
			--RAISE EXCEPTION  'v_sql: %', v_sql;

			/*
			RAISE EXCEPTION 'aB %, %, %, %, %, %, %, %, %, %, %, %, %, %, %',
					v_sign, p_layer_name, v_pixsz, v_cenx, v_ceny, p_chunk, p_chunks, 
					v_cenx, v_ceny, v_pixsz,                     
					p_chunks, p_vertexcnt, v_reqid, v_lyrid, p_chunk;*/

			EXECUTE v_sql INTO STRICT v_retobj 
			USING v_sign, p_layer_name, v_pixsz, v_cenx, v_ceny, p_chunk, p_chunks, 
					v_cenx, v_ceny, v_pixsz,                     
					p_chunks, p_vertexcnt, v_reqid, v_lyrid, p_chunk;

        END IF;
   
    ELSE
    
		with delsel as (
			--delete 
			select oidv, the_geom as snapped_shape 
			from risco_v2_publico_dev.risco_request_geometry 
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
				json_build_object('typ', risco_v2_publico_dev.util_condensed_type(geomtype), 
				'crds', risco_v2_publico_dev.gen_coords_elem(snapped_shape, v_cenx, v_ceny, v_pixsz) ) cont 
				from (
					select delsel.*, GeometryType(snapped_shape) geomtype,              
					ceil(1.0 * p_chunks * sum(st_npoints(snapped_shape)) over (order by st_npoints(snapped_shape) desc, oidv) / p_vertexcnt) chnk
					from delsel
				) b 
				where b.chnk = p_chunk
			) c 
		INTO STRICT v_retobj;

    END IF;

	RETURN v_retobj;

END;

$function$
;

-- Permissions

ALTER FUNCTION risco_v2_publico_dev.quantize2json(varchar,varchar,int4,int4,int4) OWNER TO sup_ap;
GRANT ALL ON FUNCTION risco_v2_publico_dev.quantize2json(varchar,varchar,int4,int4,int4) TO public;
GRANT ALL ON FUNCTION risco_v2_publico_dev.quantize2json(varchar,varchar,int4,int4,int4) TO sup_ap;

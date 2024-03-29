CREATE OR REPLACE FUNCTION riscov2_dev.quantize2json(p_creqid character varying, p_layer_name character varying, p_chunks integer, p_vertexcnt integer, p_chunk integer DEFAULT 1)
 RETURNS text
 LANGUAGE 'plpgsql'
 VOLATILE
 
AS $BODY$
DECLARE
	v_retobj text;
	
	v_deffilter text;

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
	v_t0 timestamp;
	v_t1 timestamp;
	v_t2 timestamp;
	v_profile boolean;
	v_is_function boolean;

	v_minx numeric;
	v_miny numeric;
	v_maxx numeric;
	v_maxy numeric;
	
BEGIN
	v_profile := 'f'; -- controle profiling layers

	if v_profile then
		v_t0 := clock_timestamp();
		v_t1 := clock_timestamp();
	end if;

	perform set_config('search_path', 'risco_v2,public', true);
	
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
    
    SELECT cenx, ceny, wid, hei, pixsz
    INTO v_cenx, v_ceny, v_width, v_height, v_pixsz
    FROM risco_request
	WHERE reqid = v_reqid;

	if v_profile then
		v_t2 := clock_timestamp();
		raise notice '..... timing A: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0); 
		v_t1 := v_t2;
	end if;

    SELECT lyrid, schema, dbobjname, oidfname, adic_fields_str, is_function, deffilter
    INTO v_lyrid, v_schema, v_tablename, v_oidfldname, v_adic_flds_str, v_is_function, v_deffilter
    FROM risco_layerview
	WHERE lname = p_layer_name;

	if v_is_function then

		v_minx := v_cenx - (v_width/2.0);
		v_miny := v_ceny - (v_height/2.0);
		v_maxx := v_cenx + (v_width/2.0);
		v_maxy := v_ceny + (v_height/2.0);

	end if;

	if v_profile then
		v_t2 := clock_timestamp();
		raise notice '..... timing B: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0); 
		v_t1 := v_t2;
	end if;

	IF NOT v_deffilter IS NULL THEN
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
			'from risco_request_geometry ' ||
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
                'json_build_object(''typ'', util_condensed_type(geomtype), ';
                
        IF v_adicflds_flag THEN
			
			v_sql := v_sql || '''a'', row_to_json( (select r from (select ' || v_adic_flds_str || ') r ) ), ';
        
        END IF;
    
        v_sql := v_sql || '''crds'', gen_coords_elem(snapped_shape, $8, $9, $10) ) cont ' ||
                    'from (select a.*, GeometryType(snapped_shape) geomtype, '                
                    'ceil(1.0 * $11 * sum(st_npoints(snapped_shape)) over (order by st_npoints(snapped_shape) desc, oidv) / $12) chnk ' ||   
                    'from (select delsel.oidv, delsel.snapped_shape';            
                    
        IF v_adicflds_flag THEN
			v_sql := v_sql || ', ' || v_adic_flds_str;
		END IF;

		if v_is_function then

			v_sql := v_sql || ' from ' || v_schema || '.' || v_tablename || '('  || v_minx || ',' || v_miny || ',' || v_maxx || ',' || v_maxy || ') t1 inner join delsel ' ||
				'on t1.' || v_oidfldname || ' = delsel.oidv';

		else 

			v_sql := v_sql || ' from ' || v_schema || '.' || v_tablename || ' t1 inner join delsel ' ||
				'on t1.' || v_oidfldname || ' = delsel.oidv';

		end if;
	
        IF v_filter_flag THEN

			v_sql := v_sql || ' and (' || v_deffilter || ')) a) b where b.chnk = $15) c';

        ELSE
        
			v_sql := v_sql || ') a) b where b.chnk = $15) c';

        END IF;

		EXECUTE v_sql INTO STRICT v_retobj 
		USING v_sign, p_layer_name, v_pixsz, v_cenx, v_ceny, p_chunk, p_chunks, 
				v_cenx, v_ceny, v_pixsz,                     
				p_chunks, p_vertexcnt, v_reqid, v_lyrid, p_chunk;

		if v_profile then
			v_t2 := clock_timestamp();
			raise notice '..... timing C1: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0); 
			v_t1 := v_t2;
		end if;
       
    ELSE
    
		with delsel as (
			--delete 
			select oidv, the_geom as snapped_shape 
			from risco_request_geometry 
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
				json_build_object('typ', util_condensed_type(geomtype), 
				'crds', gen_coords_elem(snapped_shape, v_cenx, v_ceny, v_pixsz) ) cont 
				from (
					select delsel.*, GeometryType(snapped_shape) geomtype,              
					ceil(1.0 * p_chunks * sum(st_npoints(snapped_shape)) over (order by st_npoints(snapped_shape) desc, oidv) / p_vertexcnt) chnk
					from delsel
				) b 
				where b.chnk = p_chunk
			) c 
		INTO STRICT v_retobj;

		if v_profile then
			v_t2 := clock_timestamp();
			raise notice '..... timing C2: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0); 
			v_t1 := v_t2;
		end if;
	
    END IF;

	RETURN v_retobj;

END;
$BODY$;

ALTER FUNCTION riscov2_dev.quantize2json(character varying, character varying, integer, integer, integer) OWNER to sup_ap;

GRANT EXECUTE ON FUNCTION riscov2_dev.quantize2json(character varying, character varying, integer, integer, integer) TO PUBLIC;
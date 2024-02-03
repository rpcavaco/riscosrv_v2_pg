CREATE OR REPLACE FUNCTION riscov2_dev.full_chunk_calc(p_cenx double precision, p_ceny double precision, p_pixsz double precision, p_width double precision, p_height double precision, p_mapname character varying, p_vizlayers character varying)
 RETURNS text
 LANGUAGE 'plpgsql'
 VOLATILE
AS $body$
DECLARE
	v_minx numeric;
	v_miny numeric;
	v_maxx numeric;
	v_maxy numeric;
	v_srid integer;
	v_tol numeric;
	v_sql text;
	v_reqid uuid;
	v_schema character varying(64);
	v_table character varying(64);
	v_geomfname character varying(64);
	v_geom_source text;
	v_rec record;
	v_ret json;
    v_ctrlcnt integer;
    v_lyr_table regclass;
    v_env geometry;
    v_actenv geometry;
    v_use_vizlayers boolean;
    v_vizlyrs_array text[];
	v_t0 timestamp;
	v_t1 timestamp;
	v_t2 timestamp;
	v_profile boolean;
BEGIN
	v_profile := 'f'; -- controle profiling layers

	if v_profile then
		v_t0 := clock_timestamp();
		v_t1 := clock_timestamp();
	end if;

	perform set_config('search_path', 'riscov2_dev,public', true);

	select srid from risco_map rm 
	into v_srid
	where mapname = p_mapname;

	if v_srid is null then
		raise exception 'missing risco_map record for mapname: %', p_mapname;
	end if;
	
	v_minx := p_cenx - (p_width/2.0);
	v_miny := p_ceny - (p_height/2.0);
	v_maxx := p_cenx + (p_width/2.0);
	v_maxy := p_ceny + (p_height/2.0);
	
	INSERT INTO risco_request
	(cenx, ceny, wid, hei, pixsz)
	VALUES 
	(p_cenx, p_ceny, p_width, p_height, p_pixsz)
	RETURNING reqid INTO v_reqid;
    
    SELECT ST_MakeEnvelope(v_minx, v_miny, v_maxx, v_maxy, v_srid) INTO v_env;
    
    IF NOT p_vizlayers IS NULL AND length(p_vizlayers) > 0 	THEN
    	v_use_vizlayers := true;
        v_vizlyrs_array := regexp_split_to_array(p_vizlayers, E'[\\s+]?[\\,][\\s+]?');
    ELSE
    	v_use_vizlayers := false;
    END IF;

	if v_profile then
		v_t2 := clock_timestamp();
		raise notice '..... timing B: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0); 
		v_t1 := v_t2;
	end if;
	
	FOR v_rec IN 
		SELECT lname, schema, dbobjname, geomfname, oidfname, lyrid, srid, is_function, deffilter
		FROM risco_layerview 
		WHERE inuse
		AND p_mapname = ANY(maps) 
	LOOP
		IF v_use_vizlayers AND v_rec.lname != ALL (v_vizlyrs_array) THEN
			CONTINUE;
		END IF;

		if v_profile then
		    raise notice '..... dbobjname: %   srid tema:% srid mapa:%', v_rec.dbobjname, v_rec.srid, v_srid;
		end if;
            
            BEGIN
			
				if v_rec.srid = v_srid then
					v_geom_source := v_rec.geomfname;
					v_actenv := v_env;
				else
					v_geom_source := format('ST_Transform(%I, %s)', v_rec.geomfname, v_srid);
					v_actenv := ST_Transform(v_env, v_rec.srid);
				end if;

				if v_rec.is_function then

					v_sql := 'INSERT INTO risco_request_geometry (reqid, lyrid, oidv, the_geom) ' ||
					'SELECT $1, $2, ' || v_rec.oidfname || ' oidv, ST_SnapToGrid(' || v_geom_source || ', $3, $4, $5, $6) the_geom ' ||
					'FROM ' || v_rec.schema || '.' || v_rec.dbobjname || '(' || v_minx || ',' || v_miny || ',' || v_maxx || ',' || v_maxy || ')';

				else	
							
					v_sql := 'INSERT INTO risco_request_geometry (reqid, lyrid, oidv, the_geom) ' ||
					'SELECT $1, $2, ' || v_rec.oidfname || ' oidv, ST_SnapToGrid(' || v_geom_source || ', $3, $4, $5, $6) the_geom ' ||
					'FROM ' || v_rec.schema || '.' || v_rec.dbobjname || ' ' || 
					'where ' || v_rec.geomfname || ' && $7';

					if not v_rec.deffilter is null then

						v_sql := v_sql || ' and (' || v_rec.deffilter || ')';

					end if;

				end if;

				if v_profile then
					raise notice 'B v_sql:%, %, %, %, %, %, %, v_env:%', v_sql, v_reqid, v_rec.lyrid, p_cenx, p_ceny, p_pixsz, p_pixsz, ST_AsText(v_actenv);
				end if;

				execute v_sql
				using v_reqid, v_rec.lyrid, p_cenx, p_ceny, p_pixsz, p_pixsz, 
						v_actenv;							
            
            EXCEPTION        
            
				WHEN SQLSTATE '42P01' THEN
                
					INSERT INTO risco_msgs (severity, context, msg)
					VALUES
					(2, 'full_chunk_calc', v_rec.schema || '.' || v_rec.dbobjname || ': table does not exist');
					CONTINUE;
               
				WHEN SQLSTATE '23505' THEN
                
					INSERT INTO risco_msgs (severity, context, msg)
					VALUES
					(2, 'full_chunk_calc', v_rec.schema || '.' || v_rec.dbobjname || ': table has non unique GIDs, was removed from response');
					CONTINUE;
               
             END;

		if v_profile then
			v_t2 := clock_timestamp();
		    raise notice '..... timing C: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0); 
			v_t1 := v_t2;
		end if;
		
		
	END LOOP;

	SELECT json_build_object('reqid', v_reqid, 'stats',
		json_object_agg(lname, 
        json_build_object('nchunks',CASE
		WHEN a.vcount < 5000  THEN
			1
		WHEN a.vcount < 10000  THEN
			2
		WHEN a.vcount < 25000  THEN
			3
		WHEN a.vcount < 50000  THEN
			4
		WHEN a.vcount < 90000  THEN
			5
		WHEN a.vcount < 120000  THEN
			6
		WHEN a.vcount < 140000  THEN
			7
		WHEN a.vcount < 160000  THEN
			8
		WHEN a.vcount < 180000  THEN
			9
		ELSE
			round(a.vcount / 20000)
		END,
		'nvert', a.vcount, 
		'gisid_field', a.gisid_field,
		'accept_deletion', a.accept_deletion
	)))
	INTO v_ret
	FROM
	(SELECT lname, sum(st_npoints(the_geom)) vcount, t2.gisid_field, t2.accept_deletion
	FROM risco_request_geometry T1
	INNER JOIN risco_layerview T2
	ON T1.lyrid = T2.lyrid AND T1.reqid = v_reqid
	WHERE inuse
	GROUP BY lname) a;

	if v_profile then
		v_t2 := clock_timestamp();
		raise notice '..... timing FINAL: %  accum:%', (v_t2 - v_t1), (v_t2 - v_t0); 
		v_t1 := v_t2;
	end if;
	
	RETURN v_ret::text;

END;
$body$;

alter function riscov2_dev.full_chunk_calc(double precision, double precision, double precision, double precision, double precision, character varying, character varying) owner to sup_ap;

GRANT EXECUTE ON FUNCTION riscov2_dev.full_chunk_calc(double precision, double precision, double precision, double precision, double precision, character varying, character varying) TO PUBLIC;
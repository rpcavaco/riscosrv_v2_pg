CREATE OR REPLACE FUNCTION risco_v2_publico_dev.gen_coords_elem(p_geom geometry, p_cenx double precision, p_ceny double precision, p_pixsz double precision)
 RETURNS json
 LANGUAGE 'plpgsql'
 VOLATILE
AS $body$

DECLARE
	v_retobj json;
    v_tmp_retobj text;
    v_max_depth integer;
    v_depth integer;
    v_snapped_geom geometry;
	v_aggr_table regclass;
BEGIN

    SELECT COALESCE(max(array_length((dp).path,1)), 0)
    INTO v_max_depth
    FROM ST_DumpPoints(p_geom) dp;
    
    -- Geometria p_geom ja deve estar snapped-to-grid
    
    IF p_geom IS NULL THEN
    	RETURN NULL;
    END IF;
    
	CASE v_max_depth
		WHEN 3 THEN
			select json_agg(coords) coords
			INTO v_retobj
			from
			(
				select path[1], json_agg(coords) coords
				from
				(
					select path[1:2] path, json_agg(coord) coords
					from (
						select (dp).path path, 
							unnest(ARRAY[ROUND((ST_X((dp).geom) - p_cenx) / p_pixsz)::int,  
							ROUND((ST_Y((dp).geom) - p_ceny) / p_pixsz)::int]) coord
						from ST_DumpPoints(p_geom) dp
					) b
					group by path[1:2]
					order by path[1:2]
				) c
				group by path[1]
				order by path[1]
			) d;
			
		WHEN 2 THEN
			select json_agg(coords) coords
			INTO v_retobj
			from
			(
				select path[1] path, json_agg(coord) coords
				from (
					select (dp).path path, 
							unnest(ARRAY[ROUND((ST_X((dp).geom) - p_cenx) / p_pixsz)::int,  
							ROUND((ST_Y((dp).geom) - p_ceny) / p_pixsz)::int]) coord
					from ST_DumpPoints(p_geom) dp
				) b
				group by path[1]
				order by path[1]
			) d;
			
		ELSE 

			SELECT json_agg(coords) coords
			INTO v_retobj
			FROM
				(SELECT unnest(
					ARRAY[ROUND((ST_X((dp).geom) - p_cenx) / p_pixsz)::int,  
					ROUND((ST_Y((dp).geom) - p_ceny) / p_pixsz)::int] 
					) coords
					FROM ST_DumpPoints(p_geom) dp
				) a;
		
	END CASE;
            
    RETURN v_retobj;
END;

$body$;


alter function risco_v2_publico_dev.gen_coords_elem(p_geom geometry, p_cenx double precision, p_ceny double precision, p_pixsz double precision) owner to sup_ap;
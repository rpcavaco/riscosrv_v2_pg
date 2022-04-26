CREATE OR REPLACE FUNCTION riscov2_dev.util_condensed_type(p_geom_type_str character varying)
 RETURNS text
 LANGUAGE 'plpgsql'
 VOLATILE
AS $body$

DECLARE
	v_ret text;
BEGIN

	if p_geom_type_str = 'LINESTRING' then
	  v_ret := 'line';
	elsif p_geom_type_str = 'POINT' then
	  v_ret := 'point';
	elsif p_geom_type_str = 'MULTIPOINT' then
	  v_ret := 'mpoint';
	elsif p_geom_type_str = 'POLYGON' then
	  v_ret := 'poly';
	elsif p_geom_type_str = 'MULTILINESTRING' then
	  v_ret := 'mline';
	elsif p_geom_type_str = 'MULTIPOLYGON' then
	  v_ret := 'mpoly';
	end if;
 
    return v_ret;

END;

$body$;

alter function riscov2_dev.util_condensed_type(p_geom_type_str character varying) owner to sup_ap;
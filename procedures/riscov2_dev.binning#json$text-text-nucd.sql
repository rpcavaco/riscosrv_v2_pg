CREATE OR REPLACE FUNCTION riscov2_dev.binning(p_key text, p_geomtype text, p_radius numeric)
	RETURNS json
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$
DECLARE
	v_null integer;
BEGIN

	RETURN '{}'::json;

END;
$BODY$;

ALTER FUNCTION riscov2_dev.binning(text, text, numeric) OWNER to sup_ap;
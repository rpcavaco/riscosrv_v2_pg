CREATE OR REPLACE FUNCTION riscov2_dev.truncate_requests()
	RETURNS void
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$

BEGIN

	perform set_config('search_path', 'riscov2_dev,public', true);

   	delete from risco_request;

    delete from risco_request_geometry;

    delete from risco_msgs;

END;
$BODY$;

ALTER FUNCTION riscov2_dev.truncate_requests() OWNER TO sup_ap;
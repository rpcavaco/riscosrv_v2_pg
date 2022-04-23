CREATE OR REPLACE FUNCTION risco_v2_publico_dev.truncate_requests()
	RETURNS void
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$

BEGIN

   	delete from risco_v2_publico_dev.risco_request;

    delete from risco_v2_publico_dev.risco_request_geometry;

    delete from risco_v2_publico_dev.risco_msgs;

END;
$BODY$;

ALTER FUNCTION risco_v2_publico_dev.truncate_requests() OWNER TO sup_ap;
CREATE OR REPLACE FUNCTION risco_v2_publico_dev.clrreq(p_creqid character varying, p_layer_name character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
	declare 
	
		v_lyrid uuid;
		v_reqid uuid;
	
	begin
		
	    v_reqid := uuid(p_creqid);
	

		SELECT lyrid
	    INTO v_lyrid
	    FROM risco_v2_publico_dev.risco_layerview
		WHERE lname = p_layer_name;

		delete 
		from risco_v2_publico_dev.risco_request_geometry 
		WHERE reqid = v_reqid
		AND lyrid = v_lyrid;
		
	END;

$function$
;

-- Permissions

ALTER FUNCTION risco_v2_publico_dev.clrreq(varchar,varchar) OWNER TO sup_ap;
GRANT ALL ON FUNCTION risco_v2_publico_dev.clrreq(varchar,varchar) TO sup_ap;

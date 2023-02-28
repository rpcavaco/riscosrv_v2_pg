CREATE OR REPLACE FUNCTION riscov2_dev.clrreq(p_creqid character varying, p_layer_name character varying)
 RETURNS void
 LANGUAGE 'plpgsql'
 VOLATILE
AS $BODY$
	declare 
	
		v_lyrid uuid;
		v_reqid uuid;
	
	begin

		perform set_config('search_path', 'riscov2_dev,public', true);

	    v_reqid := uuid(p_creqid);
	

		SELECT lyrid
	    INTO v_lyrid
	    FROM risco_layerview
		WHERE lname = p_layer_name;

		delete 
		from risco_request_geometry 
		WHERE reqid = v_reqid
		AND lyrid = v_lyrid;
		
	END;

$BODY$;


alter function riscov2_dev.clrreq(character varying, character varying) owner to sup_ap;
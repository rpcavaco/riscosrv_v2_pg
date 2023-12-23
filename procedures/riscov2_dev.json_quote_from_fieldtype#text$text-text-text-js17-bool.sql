CREATE OR REPLACE FUNCTION riscov2_dev.json_quote_from_fieldtype(p_schema text, p_dbobj text, p_fieldname text, p_jsonvalue jsonb, b_keyvalue_pair boolean)
	RETURNS text
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$
DECLARE
	v_type text;
	v_sql text;
	v_ret text;
BEGIN

	SELECT
	data_type into v_type
	FROM information_schema.columns
	WHERE table_Schema = p_schema
	and table_name = p_dbobj
	and column_name = p_fieldname;

	if v_type = 'integer' or v_type = 'numeric' or v_type = 'double precision' or v_type = 'boolean' or v_type = 'smallint' or v_type = 'bigint' or v_type = 'real'  then
		if b_keyvalue_pair then
			v_ret := format('%I = %s', p_fieldname, p_jsonvalue);
		else
			v_ret := format('%s', p_jsonvalue);
		end if;
	else
		if b_keyvalue_pair then
			v_ret := format('%I = ''%s''', p_fieldname, p_jsonvalue);
		else
			v_ret := format('''%s''', p_jsonvalue);
		end if;	
	end if;

	RETURN v_ret;

END;
$BODY$;

ALTER FUNCTION riscov2_dev.json_quote_from_fieldtype(text, text, text, jsonb, boolean) OWNER to sup_ap;
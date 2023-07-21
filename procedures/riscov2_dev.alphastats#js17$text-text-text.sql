CREATE OR REPLACE FUNCTION riscov2_dev.alphastats(p_key text, p_field text, p_mode text)
	RETURNS jsonb
	LANGUAGE 'plpgsql'
	VOLATILE
AS $BODY$
DECLARE
	v_sch text;
	v_oname text;	
	v_counts json;
	v_cnt integer;
	v_ret jsonb;
	v_sql text;
	v_num numeric;
BEGIN

	set search_path to riscov2_dev, public;

	v_ret := '{}'::jsonb;

	select dataobjschema, dataobjname into v_sch, v_oname
	from
	(
		select dataobjschema, dataobjname, regexp_split_to_array(allowedcols, '[\s\,]+') cols
		from risco_stats
		where key = p_key
	) a
	where p_field = ANY (a.cols);

	if FOUND then

		if p_mode = 'DISCRETE' then

			v_sql := format('select count(*) from (
				select distinct %s valor
				from %s.%s
			) a', p_field, v_sch, v_oname);

			execute v_sql into v_cnt;
			-- v_ret := jsonb_set(v_ret, array['dbobject'], to_jsonb(format('%s.%s', v_sch, v_oname)), true); 
			v_ret := jsonb_set(v_ret, array['field'], to_jsonb(p_field), true); 
			v_ret := jsonb_set(v_ret, array['totalcount'], to_jsonb(v_cnt), true); 

			v_sql := format('select json_object_agg(valor, cnt) from (
			select %s valor, count(*) cnt
			from %s.%s
			group by %1$s
			) a', p_field, v_sch, v_oname);

			execute v_sql into v_counts;

			v_ret := jsonb_set(v_ret, array['counts'], to_jsonb(v_counts), true); 

		else -- CONTINUOUS

			v_ret := jsonb_set(v_ret, array['field'], to_jsonb(p_field), true); 

			v_sql := format('select sum(%s) from %s.%s', p_field, v_sch, v_oname);
			execute v_sql into v_num;
			v_ret := jsonb_set(v_ret, array['sum'], to_jsonb(v_num), true); 

			v_sql := format('select avg(%s) from %s.%s', p_field, v_sch, v_oname);
			execute v_sql into v_num;
			v_ret := jsonb_set(v_ret, array['avg'], to_jsonb(v_num), true); 

			v_sql := format('select min(%s) from %s.%s', p_field, v_sch, v_oname);
			execute v_sql into v_num;
			v_ret := jsonb_set(v_ret, array['min'], to_jsonb(v_num), true); 

			v_sql := format('select max(%s) from %s.%s', p_field, v_sch, v_oname);
			execute v_sql into v_num;
			v_ret := jsonb_set(v_ret, array['max'], to_jsonb(v_num), true); 

			v_sql := format('select stddev(%s) from %s.%s', p_field, v_sch, v_oname);
			execute v_sql into v_num;
			v_ret := jsonb_set(v_ret, array['stddev'], to_jsonb(v_num), true); 

		end if;

	else

		v_ret := jsonb_set(v_ret, array['error'], to_jsonb('not configured'), true); 

	end if;

	return v_ret;

END;
$BODY$;

ALTER FUNCTION riscov2_dev.alphastats(text, text, text) OWNER to sup_ap;
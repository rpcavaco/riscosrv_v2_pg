-- DROP SEQUENCE risco_v2_publico_dev.risco_msgs_sn_seq;

CREATE SEQUENCE risco_v2_publico_dev.risco_msgs_sn_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 0
	NO CYCLE;

-- Permissions

ALTER SEQUENCE risco_v2_publico_dev.risco_msgs_sn_seq OWNER TO sup_ap;
GRANT ALL ON SEQUENCE risco_v2_publico_dev.risco_msgs_sn_seq TO sup_ap;

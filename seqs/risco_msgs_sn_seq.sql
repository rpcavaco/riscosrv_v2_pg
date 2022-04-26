-- DROP SEQUENCE riscov2_dev.risco_msgs_sn_seq;

CREATE SEQUENCE riscov2_dev.risco_msgs_sn_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 0
	NO CYCLE;

-- Permissions

ALTER SEQUENCE riscov2_dev.risco_msgs_sn_seq OWNER TO sup_ap;
GRANT ALL ON SEQUENCE riscov2_dev.risco_msgs_sn_seq TO sup_ap;

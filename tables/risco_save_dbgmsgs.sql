
CREATE TABLE IF NOT EXISTS riscov2_dev.risco_save_dbgmsgs
(
    ts timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    msg text COLLATE pg_catalog."default"
);

ALTER TABLE riscov2_dev.risco_save_dbgmsgs
    OWNER to sup_ap;
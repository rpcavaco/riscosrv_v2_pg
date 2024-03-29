-- Table: riscov2_dev.risco_request

-- DROP TABLE riscov2_dev.risco_request;

CREATE TABLE riscov2_dev.risco_request
(
    reqid uuid NOT NULL DEFAULT uuid_generate_v4(),
    cenx numeric NOT NULL,
    ceny numeric NOT NULL,
    wid numeric NOT NULL,
    hei numeric NOT NULL,
    pixsz numeric NOT NULL,
    CONSTRAINT pk_request_ PRIMARY KEY (reqid)

);

ALTER TABLE riscov2_dev.risco_request
    OWNER to sup_ap;
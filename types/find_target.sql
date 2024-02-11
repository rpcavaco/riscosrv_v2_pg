-- Type: find_target

-- DROP TYPE riscov2_dev.find_target;

CREATE TYPE riscov2_dev.find_target AS ENUM
    ('function', 'layer', 'table');

ALTER TYPE riscov2_dev.find_target
    OWNER TO sup_ap;
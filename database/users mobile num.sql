USE cleanway_ims;

DROP PROCEDURE IF EXISTS sp_migrate_users_mobile_number;

DELIMITER $$

CREATE PROCEDURE sp_migrate_users_mobile_number()
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'users'
          AND COLUMN_NAME = 'mobile_number'
    ) THEN
        ALTER TABLE users ADD COLUMN mobile_number VARCHAR(20) NULL AFTER full_name;
    END IF;
END$$

DELIMITER ;

CALL sp_migrate_users_mobile_number();

DROP PROCEDURE IF EXISTS sp_migrate_users_mobile_number;
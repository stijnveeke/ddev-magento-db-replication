USE mydatabase;
delimiter //
CREATE PROCEDURE IF NOT EXISTS SetupReplicationIfNotRunning()
BEGIN
    DECLARE replicationStatus BOOLEAN;
    ### Execute the following block if an exception is thrown.
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
BEGIN
        SET replicationStatus = FALSE;
        ### Sets the master-database...
        CHANGE MASTER TO
            MASTER_HOST='ddev-${DDEV_SITENAME}-db',
            MASTER_USER='replication_user',
            MASTER_PASSWORD='replication_password',
            MASTER_AUTO_POSITION = 1;
        ### ...and starts the slave.
        START SLAVE;
END;
    STOP SLAVE;
CREATE TABLE IF NOT EXISTS replicationStatusTable (status BOOLEAN);
SET replicationStatus = TRUE;
    ### Throws an exception if this sql server is a replication server.
    START SLAVE;
INSERT INTO replicationStatusTable (status) VALUES (replicationStatus);
END//
delimiter ;
CALL SetupReplicationIfNotRunning();
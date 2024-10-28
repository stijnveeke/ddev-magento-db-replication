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
            MASTER_HOST='mysql-master',
            MASTER_USER='replication_user',
            MASTER_PASSWORD='replication_password',
            MASTER_LOG_FILE='mysql-bin.000003',
            MASTER_LOG_POS=157,
            GET_MASTER_PUBLIC_KEY=1;
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
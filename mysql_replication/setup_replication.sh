#!/bin/bash
#ddev-generated

#Master slave information details
MASTER_HOST="db"
MASTER_USER="db"
MASTER_PASSWORD="db"

#Step 1: Get Master Status
MASTER_STATUS=$(mysql -h $MASTER_HOST -u $MASTER_USER -p$MASTER_PASSWORD -e "SHOW MASTER STATUS\G")

#Step 2: Get Master Log File and Position
MASTER_LOG_FILE=$(echo "$MASTER_STATUS" | grep File | awk '{print $2}')
MASTER_LOG_POS=$(echo "$MASTER_STATUS" | grep Position | awk '{print $2}')

echo "Master Log File: $MASTER_LOG_FILE"
echo "Master Log Position: $MASTER_LOG_POS"

#Step 3: Configure and Start Slave
mysql -u root -proot -e "
  STOP SLAVE;
  CHANGE MASTER TO
    MASTER_HOST='$MASTER_HOST',
    MASTER_USER='$MASTER_USER',
    MASTER_PASSWORD='$MASTER_PASSWORD',
    MASTER_LOG_FILE='$MASTER_LOG_FILE',
    MASTER_LOG_POS=$MASTER_LOG_POS;
  START SLAVE;
"

#Step 4: Check Slave Status
SLAVE_STATUS=$(mysql -u root -proot -e "SHOW SLAVE STATUS\G")
echo "$SLAVE_STATUS"
#!/bin/bash
#ddev-generated

# Check if enough arguments are passed
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <master_host> <slave_host> [master_user] [master_password] [slave_user] [slave_password]"
    exit 1
fi

#Master slave information details
MASTER_HOST="$1"
MASTER_USER="${3:-root}"
MASTER_PASSWORD="${4:-root}"

SLAVE_HOST="$2"
SLAVE_USER="${5:-root}"
SLAVE_PASSWORD="${6:-root}"

echo "MASTER HOST: $MASTER_HOST"
echo "SLAVE HOST: $SLAVE_HOST"

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
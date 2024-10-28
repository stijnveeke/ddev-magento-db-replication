setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-magento-proxysql
  mkdir -p $TESTDIR
  export PROJNAME=test-magento-proxysql
  export DDEV_NONINTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null
}

health_checks() {
  # Do something useful here that verifies the add-on
  # ddev exec "curl -s elasticsearch:9200" | grep "${PROJNAME}-elasticsearch"
  # ddev exec "curl -s https://localhost:443/"
  ddev exec "curl -s https://localhost:443/"
}

@test "GTID-based replication is enabled on the primary server" {
  run ddev exec db-primary mysql -uroot -proot -e "SHOW VARIABLES LIKE 'gtid_mode';"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "ON" ]]
}

@test "GTID-based replication is enabled on the replica server" {
  run ddev exec db-replica mysql -uroot -proot -e "SHOW VARIABLES LIKE 'gtid_mode';"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "ON" ]]
}

@test "Replica is connected to the primary and replicating" {
  # Configure replication on the replica
  ddev exec db-replica mysql -uroot -proot -e "CHANGE MASTER TO MASTER_HOST='db', MASTER_USER='root', MASTER_PASSWORD='root', MASTER_AUTO_POSITION=1; START SLAVE;"
  run ddev exec db-replica mysql -uroot -proot -e "SHOW SLAVE STATUS\G"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Slave_IO_Running: Yes" ]]
  [[ "$output" =~ "Slave_SQL_Running: Yes" ]]
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get ${DIR}
  ddev restart
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev add-on get ddev/ddev-magento-proxysql with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get ddev/ddev-magento-proxysql
  ddev restart >/dev/null
  health_checks
}

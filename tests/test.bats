export BATS_DEBUG=1

setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-magento2-db-replication
  mkdir -p $TESTDIR
  export PROJNAME=test-magento2-db-replication
  export DDEV_NONINTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null
}

health_checks() {
  check_if_replicas_running "$@"
  check_if_replicas_are_setup "$@"
  create_and_drop_table_is_succesfully_replicated "$@"
  insert_statement_is_succesful "$@"
  select_statement_is_succesful "$@"
}

select_statement_is_succesful() {
  create_table ddev_testing_table
  
  value="test"
  insert ddev_testing_table "$value"
  select_from_container ddev_testing_table name ddev-${PROJNAME}-db
  if echo "$output" | grep -q "$value"; then
    echo "Select statement is successful in ddev-${PROJNAME}-db"
  else
    echo "ERROR: Select statement is not successful in ddev-${PROJNAME}-db"
    error_column=$(echo "$output" | awk 'NR==1{print}')
    error_value=$(echo "$output" | awk 'END{print}')
    echo "ERROR: Unexpected output from column: $error_column, expected: $value | recieved: $error_value"
    return 1  # Exit with error if select statement is not successful
  fi

  for container in "$@"; do
    select_from_container ddev_testing_table name "${container}"
    if echo "$output" | grep -q "$value"; then
      echo "Select statement is successful in $container"
    else
      echo "ERROR: Select statement is not successful in $container"
      error_column=$(echo "$output" | awk 'NR==1{print}')
      error_value=$(echo "$output" | awk 'END{print}')
      echo "ERROR: Unexpected output from column: $error_column, expected: $value | recieved: $error_value"
      return 1  # Exit with error if select statement is not successful
    fi
  done
  drop_table ddev_testing_table
}

select_from_container() {
  table="${1:-ddev_testing_table}"
  argument="${2:-name}"
  container="${3:-ddev-${PROJNAME}-db}"
  run docker exec "$container" mysql -uroot -proot -e "SELECT \`$argument\` FROM \`$table\`;"
}

# Check if insert statement is successful
insert_statement_is_succesful() {
  create_table ddev_testing_table

  run docker exec "ddev-${PROJNAME}-db" mysql -uroot -proot -e "INSERT INTO \`ddev_testing_table\` (name) VALUES ('test');"
  if [ -z "$output" ]; then
    echo "Insert statement is successful in ddev-${PROJNAME}-db"
  else
    echo "ERROR: Insert statement is not successful in ddev-${PROJNAME}-db"
    echo "output: $output"
    return 1  # Exit with error if insert statement is not successful
  fi

  for container in "$@"; do
    run docker exec "${container}" mysql -uroot -proot -D db -e "SELECT * FROM ddev_testing_table;"
    if echo "$output" | grep -q "test"; then
      echo "Insert statement is successful in $container"
    else
      echo "ERROR: Insert statement is not successful in $container"
      echo "output: $output"
      return 1  # Exit with error if insert statement is not successful
    fi
  done

  drop_table ddev_testing_table
}

insert() {
  value="${2:-test}"
  table="${1:-ddev_testing_table}"
  run docker exec "ddev-${PROJNAME}-db" mysql -uroot -proot -e "INSERT INTO \`$table\` (name) VALUES ('$value');"
}

# Check if inserts are replicated
create_and_drop_table_is_succesfully_replicated() {
  create_table ddev_testing_table

  run docker exec "ddev-${PROJNAME}-db" mysql -uroot -proot -e "SHOW TABLES LIKE 'ddev_testing_table';"
  if echo "$output" | grep -q "ddev_testing_table"; then
    echo "Table ddev_testing_table exists in ddev-${PROJNAME}-db"
  else
    echo "ERROR: Table ddev_testing_table does not exist in ddev-${PROJNAME}-db"
    return 1  # Exit with error if table does not exist
  fi

  for container in "$@"; do
    run docker exec "${container}" mysql -uroot -proot -D db -e "SHOW TABLES LIKE 'ddev_testing_table';"
    if echo "$output" | grep -q "ddev_testing_table"; then
      echo "Table ddev_testing_table exists in $container"
    else
      echo "ERROR: Table ddev_testing_table does not exist in $container"
      return 1  # Exit with error if table does not exist
    fi
  done

  drop_table ddev_testing_table
}

create_table() {
  run docker exec "ddev-${PROJNAME}-db" mysql -uroot -proot -e "
    CREATE TABLE IF NOT EXISTS \`$@\` (
      \`id\` int(11) NOT NULL AUTO_INCREMENT,
      \`name\` varchar(255) DEFAULT NULL,
      PRIMARY KEY (\`id\`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  "
}

drop_table() {
  run docker exec "ddev-${PROJNAME}-db" mysql -uroot -proot -e "DROP TABLE IF EXISTS \`$@\`;"
}

# Check if replicas are setup
check_if_replicas_are_setup() {
  for container in "$@"; do
    run docker exec "${container}" mysql -uroot -proot -e "SHOW SLAVE STATUS\G"
    echo "status: $output"
    
    if echo "$output" | grep -q "Slave_IO_Running: Yes"; then
      echo "Slave_IO_Running is Yes for $container"
    else
      echo "ERROR: Slave_IO_Running is not Yes for $container"
      return 1  # Exit with error if Slave_IO_Running is not Yes
    fi
    if echo "$output" | grep -q "Slave_SQL_Running: Yes"; then
      echo "Slave_SQL_Running is Yes for $container"
    else
      echo "ERROR: Slave_SQL_Running is not Yes for $container"
      return 1  # Exit with error if Slave_IO_Running is not Yes
    fi
  done
}

check_if_replicas_running() {
  for container in "$@"; do
    run docker inspect -f '{{.State.Status}}' "${container}"
    echo "status: $output"
    [[ "$output" == "running" ]]
  done
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

  containers=("ddev-${PROJNAME}-replica-1" "ddev-${PROJNAME}-replica-2")
  health_checks "${containers[@]}"
}

# bats test_tags=release
# @test "install from release" {
#   set -eu -o pipefail
#   cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
#   echo "# ddev add-on get ddev/ddev-magento-proxysql with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
#   # ddev get ddev/ddev-magento-proxysql
#   ddev get ddev/ddev-magento2-db-replication
#   ddev restart >/dev/null
#   health_checks
# }

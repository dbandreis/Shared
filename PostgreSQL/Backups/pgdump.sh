#!/bin/bash
#HELP
usage() {
    echo "Usage: $0 [--dry-run] [--help]"
    echo
    echo "Options:"
    echo "  --dry-run   Output the commands without executing them."
    echo "  --help      Display this help message."
    exit 1
}

#ARG PARSE
for arg in "$@"; do
  case $arg in
    --dry-run) declare -r dryRun=true ; shift ;;
       --help) usage ;;
            *) echo "Invalid option: $arg" ; usage ;;
  esac
done

Log(){
  local message=$*
  [ ${dryRun} ] && printf "[DEBUG]: "
  echo "$(date '+%F %T') - ${message}"
}

Run(){
  local command=$*
  [ ${dryRun} ] && echo "[DEBUG]: ${command} <- Dry Run. NO COMMANDS EXECUTED!!!" || eval ${command}; E=$?
}

# Settings #
pgHost="" #Set postgres server hostname for remote backup
fsHost=$(hostname) #Hostname 
cpus=$(nproc) #Get number of cores
dumpRootDir=/path/to/dir/${pgHost}-$(date "+%A_%F")

"psql --user=pgbackup --no-align --tuples-only --host=${pgHost} postgres"
# Counters #
success=0
error=0
errList=" "

# Pre Backup #
# Delete previous weekday folder #
rm -rf ${dumpRootDir%%_*}*
mkdir ${dumpRootDir}

# List databases #
query="SELECT datname FROM pg_database WHERE datname LIKE '%name_pattern%'"
query="${query} ORDER BY CAST(REGEXP_REPLACE(datname, '.*_(\\d+).*', '\\1') AS INTEGER), datname" #use it in case of numeric database name sufix.
dbList=($(echo ${query} | "psql --user=pgbackup --no-align --tuples-only --host=${pgHost} postgres"))

beginTS=$(date +%s)
# Main #
for dbName in ${dbList[@]}
do
    dumpDir="${dumpRootDir}/${dbName}"
    Run "pg_dump --user=pgbackup --host=${pgHost} --format=directory --create --jobs=${cpus} --compress=9 --verbose --dbname=${dbName} --file=${dumpDir}"
    # Check return code # 0 is good #
    [ ${E} -eq 0 ] && {
      let success++
      sync
    } || {
      # Fail #
      let error++
      errList="${errList}''${dbName}''"
      # Remove failed database dump directory #
      rm -rf ${dumpDir}
    }
    unset dumpDir
done

# Post backup #
endTS=$(date +%s)
copyTime=$(date -d@$(( $endTime - $beginTime )) -u +%T)
bytes=$(du -sB1 ${dumpRootDir})

# Check for error #
[ ${error} -eq 0 ] && {
    # FULL Success #
    status="OK"
    info="Done/Total(${success}/${#dbList[@]})"
} || {
    [ ${success} -eq 0 ] && {
         # FULL failed #
         status="FAILED"
         info="Error/Total(${error}/${#dbList[@]})"
    } || {
         # Any failed #
         status="WARNING"
         info="Done/Total/Errors(${success}/${#dbList[@]}/${error}) Failed DBs(${errList})"
    }
    sync
}
# Update monitor table #
query="INSERT INTO backup_status (begin_time, end_time, copy_time, status, info, base_dir, bytes)"
query="${query} VALUES (TO_TIMESTAMP(${beginTime}), TO_TIMESTAMP(${endTime}),"
query="${query} '${copyTime}', '${status}', '${info}', '${fsHost}:${dumpRootDir}', ${bytes%%[ /]*})"

Run "echo ${query} | psql --user=pgbackup --host=${pgHost} postgres"

# EOF #

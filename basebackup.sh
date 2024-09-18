#!/bin/bash
#HELP
usage() {
    echo "Usage: $0 [--dry-run] [--help]"
    echo
    echo "Options:"
    echo "  --dry-run   Simulate the actions without executing them."
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

#PARAMETERS
declare -r baseDir=/backup/pgbase/
declare -r walsDir=/backup/pgwal/
declare -r label=$(date +%A)
declare -r currentBackupDir=${baseDir}${label}
declare -r previousBackupDir=${baseDir}$(date --date=yesterday +%A)
declare -r beginTS=$(date +%s)
Log "Starting Base Backup Job"
Run "pg_basebackup --pgdata=${currentBackupDir} --verbose --label=${label} --format=t --gzip"
[ ${E} -eq 0 ] && {
  Log "Base Backup finished."
  sync
  Log "Starting Housekeeping."
  declare -ar walFiles=($(ls ${walsDir}*.backup))
  [ ${#walFile[@]} -eq 0 ] && { 
    Log "No wals to delete."
  } || {
    Log "Deleting older Wals:"
    Run "pg_archivecleanup -d ${walsDir} ${walFile[-1]/${walsDir}/}"
  }
  sync
  Log "Deleting older Backups."
  Run "rm -rfv ${previousBackupDir}"
  [ ${E} -eq 0 ] || Log "No backups to delete."
  sync
  Log "Backup Job OK."
} || Log "Backup Job FAILED. Error: ${E}"

sync
declare -r endTS=$(date +%s)
echo "Total run time: $(date -d@$(( ${endTS} - ${beginTS} )) -u +%T)"
#EOF

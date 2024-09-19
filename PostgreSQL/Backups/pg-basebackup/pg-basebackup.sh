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
        --help)    usage ;;
        *)         echo "Invalid option: $arg" ; usage ;;
    esac
done

#FUNC
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
baseDir=/backup/pgbase/
walsDir=/backup/pgwal/
label=$(date +%A)
currentBackupDir=${baseDir}${label}
previousBackupDir=${baseDir}$(date --date=yesterday +%A)
beginTS=$(date +%s)

#MAIN
Log "Starting Base Backup Job"
Run "pg_basebackup --pgdata=${currentBackupDir} --verbose --label=${label} --format=t --gzip"
[ ${E} -eq 0 ] && {
    Log "Base Backup finished."
    sync
    Log "Starting Housekeeping."
    backupHistoryFiles=($(ls ${walsDir}*.backup))
    [ ${#backupHistoryFiles[@]} -eq 0 ] && {
        Log "No wals to delete."
    } || {
        Log "Deleting older Wals:"
        Run "pg_archivecleanup -d ${walsDir} ${backupHistoryFiles[-1]/${walsDir}/}"
	Run "rm -fv ${backupHistoryFiles[@]:0:${#backupHistoryFiles[@]}-1}"
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

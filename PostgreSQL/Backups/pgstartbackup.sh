#!/bin/bash
#
walsDir=/backup/pgwal
label=$(date --iso)
log=/backup/log/pgBackup_${label}.log
pgStopBackup=/backup/bin/.pgStopBackup
test -f  ${pgStopBackup} && pgLastWal=$(cat ${pgStopBackup})
pgLastWalFile=$(find ${walsDir}/${pgLastWal}.*.backup)
#
echo "select pg_stop_backup()"|psql
#
sleep 10
#
echo -e "
select now(),pg_start_backup('${label}',true);
select now(),pg_is_in_backup();
select now(),pg_sleep(4*60*60); --4 horas
select now(),pg_stop_backup();
select now(),pg_is_in_backup();
select now(),pg_switch_xlog();
" |psql -ext -o ${log}
#
echo Old Wals Cleanup >> ${log}
#
test -f ${pgLastWalFile} && pg_archivecleanup -d ${walsDir} ${pgLastWalFile/${walsDir}\//} >> ${log} 2>&1 || echo No files found >> ${log}
echo "select pg_xlogfile_name('$(awk '/pg_stop_backup/{print $NF}' ${log})')"|psql -tA -o ${pgStopBackup}
#
find ${walsDir} -name "*.backup" ! -newer ${pgLastWalFile}  ! -samefile ${pgLastWalFile} -delete
#EOF

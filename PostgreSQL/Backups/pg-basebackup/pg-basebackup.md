
***
||PG BASE BACKUP|
|:-:|:-|
|LINK|[pg-basebackup.sh](./pg-basebackup.sh)|
|USAGE|`/path/to/pg-basebackup.sh [--dry-run] > /path/to/log 2>&1`|
|ARGS|`--dry-run` Use to debug. Print the commands without run it|
|🇧🇷|Utilizar este script via crontab apontando a saida padrão (`stdout`) e de erros (`stderr`) para um arquivo de log. É esperado o uso deste script quando o arquivo de backup e os wals forem copiados para outro repositório (bucket ou ferramenta de backup). Opcionalmente executar com a flag `--dry-run` para que este printe os comandos a serem executados sem que sejam efetivados.|
|🇺🇸|Use this script via crontab, directing the standard output (`stdout`) and error output (`stderr`) to a log file. This script is expected to be used when the backup file and WALs are copied to another repository (bucket or external backup tool). Optionally, run with the `--dry-run` flag so that it prints the commands to be executed without actually applying them.|

***
## REQS

postgresql.conf
> ```
> archive_mode = on
> archive_command = 'cp %p /backup/pgwal'
> max_wal_senders = 5
> wal_level = hot_standby # PG 9.3-
> > wal_level = replica     # PG 9.5+
> ```

***

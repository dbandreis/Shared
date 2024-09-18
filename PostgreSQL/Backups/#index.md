# PostgreSQL Backup Scripts
***
|Script|[basebackup.sh](./basebackup.sh)|
|----------:|:---|
|PG Versions|Any|
|BR|Script para executar pg_basebackup em diretório local. Utilizar este script quando for executar backups diários (crontab).| 
|EN|Script to perform pg_basebackup locally. Use it to perform daily backups (crontab).|
|USAGE|`/path/to/basebackup.sh [--dry-run] > /path/to/log 2>&1`|
|ARGS|`--dry-run` Use to debug. Print the commands without run it|
***

# PostgreSQL Backup Scripts
***
|SCRIPT|[basebackup.sh](./basebackup.sh)|
|----------:|:---|
|RESUMO|Script para executar pg_basebackup em diretório local.| 
|USO|`/path/to/basebackup.sh [--dry-run] > /path/to/log 2>&1`|
|ARGS|`--dry-run` Use to debug. Print the commands without run it|

Utilizar este script via crontab apontando a saida padrão `stdout`e de erros `stderr` para um arquivo de log.
É esperado o uso deste script quando o arquivo de backup e os wals forem copiados para outro repositório (bucket ou ferramenta de backup).
Opcionalmente executar com a flag `--dry-run` para que este printe os comandos a serem executados sem que sejam efetivados.

## Requisitos.
postgresql.conf
> ```
> archive_mode = on
> archive_command = 'cp %p /backup/pgwal'
> max_wal_senders = 5
> wal_level = replica     # PG 9.5+
> wal_level = hot_standby # PG 9.3-
> ```

***

|SCRIPT|[pgdump_dbs.sh](./pgdump_dbs.sh)|
|----------:|:---|
|RESUMO|Script para executar pg_dump em formato diretório através de servidor remoto, sendo que cada database será exportada de forma individual.| 
|USO|`/path/to/pgdump.sh [--dry-run] [--help]`|
|ARGS|`--help` Display usage<br>`--dry-run` Use to debug. Print the commands without run it|

Utilizar este script via crontab.
É esperado o uso deste script quando a estratégia de backup utilizada seja o pg_dump e há necessidade de monitorar a execução do job.
Opcionalmente executar com a flag `--dry-run` para que este printe os comandos a serem executados sem que sejam efetivados.

## Requisitos
Criação de um usuário específico para o backup no PostgreSQL.
|User|`pgbackup`|
|---:|:---|
|Grants|`pg_read_all_data`<br>`pg_read_all_settings`<br>`pg_read_all_stats`<br>`pg_read_server_files`|

Criar arquivo `.pgpass` na home do usuário que irá executar o backup (servidor remoto)
> `pghostname:*:*:pgbackup:senha`
Criação de uma tabela para armazenar as informações do backup.
> ```
> CREATE TABLE backup_status (
>   backup_id integer NOT NULL,
>   begin_time timestamp with time zone,
>   end_time timestamp with time zone,
>   copy_time interval,
>   status text,
>   info text,
>   base_dir text,
>   bytes bigint);
> CREATE SEQUENCE backup_status_backup_id_seq
>   AS integer
>   START WITH 1
>   INCREMENT BY 1
>   NO MINVALUE
>   NO MAXVALUE
>   CACHE 1;
> ALTER TABLE ONLY backup_status ALTER COLUMN backup_id SET DEFAULT nextval('backup_status_backup_id_seq'::regclass);
> ALTER TABLE ONLY backup_status ADD CONSTRAINT backup_status_pkey PRIMARY KEY (backup_id);
> GRANT ALL ON TABLE backup_status TO pgbackup;
> GRANT ALL ON SEQUENCE backup_status_backup_id_seq TO pgbackup;
> ```

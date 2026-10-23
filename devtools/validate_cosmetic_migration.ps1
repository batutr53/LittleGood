$ErrorActionPreference='Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
$values=@{}
Get-Content server/.env | ForEach-Object {if($_ -match '^([^#=]+)=(.*)$'){$values[$matches[1]]=$matches[2]}}
$pg='D:/LittleGod/tools/postgres/pgsql/bin'
$dbArgs=@('-h','127.0.0.1','-p','55437','-U',$values.POSTGRES_USER,'-d','littlegod')
$env:PGPASSWORD=$values.POSTGRES_PASSWORD
try {
    if(-not (Test-Path -LiteralPath server/.local/pre-phase8.dump)) {
        & "$pg/pg_dump.exe" @dbArgs -Fc -f server/.local/pre-phase8.dump
        if($LASTEXITCODE){throw 'Backup failed; migration was not applied'}
    }
    foreach($attempt in 1..2){
        & "$pg/psql.exe" @dbArgs -v ON_ERROR_STOP=1 -f server/migrate.sql
        if($LASTEXITCODE){throw 'Migration failed'}
    }
    $sql=@'
BEGIN;
INSERT INTO "AspNetUsers" ("Id","UserName","NormalizedUserName","EmailConfirmed","PhoneNumberConfirmed","TwoFactorEnabled","LockoutEnabled","AccessFailedCount")
VALUES ('phase8-schema-qa','phase8-schema-qa','PHASE8-SCHEMA-QA',false,false,false,false,0);
INSERT INTO "PurchaseReceipt" VALUES ('google','phase8-tx','phase8-schema-qa','org.littlegod.cosmetics.astral_heirloom.v1','pending',now());
DO $qa$ BEGIN
  BEGIN
    INSERT INTO "PurchaseReceipt" VALUES ('google','phase8-tx','phase8-schema-qa','product','completed',now());
    RAISE EXCEPTION 'Duplicate transaction was accepted';
  EXCEPTION WHEN unique_violation THEN NULL; END;
  BEGIN
    INSERT INTO "PurchaseReceipt" VALUES ('google','phase8-badstate','phase8-schema-qa','product','client_true',now());
    RAISE EXCEPTION 'Invalid state was accepted';
  EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN
    INSERT INTO "PurchaseReceipt" VALUES ('google','phase8-badowner','absent-owner','product','completed',now());
    RAISE EXCEPTION 'Dangling owner was accepted';
  EXCEPTION WHEN foreign_key_violation THEN NULL; END;
END $qa$;
DELETE FROM "AspNetUsers" WHERE "Id"='phase8-schema-qa';
DO $qa$ BEGIN
 IF EXISTS(SELECT 1 FROM "PurchaseReceipt" WHERE "Transaction"='phase8-tx') THEN RAISE EXCEPTION 'Account cascade failed'; END IF;
END $qa$;
ROLLBACK;
SELECT 'PHASE8_SCHEMA_OK';
'@
    $sql | & "$pg/psql.exe" @dbArgs -v ON_ERROR_STOP=1
    if($LASTEXITCODE){throw 'Schema checks failed'}
    '{"source":"real_postgresql_sql_not_http","migration_applied_twice":true,"backup_created":true,"transaction_unique":true,"state_constraint":true,"owner_foreign_key":true,"account_cascade":true,"test_rows_rolled_back":true}' | Set-Content builds/phase8/schema.json -Encoding utf8
} finally {Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue}

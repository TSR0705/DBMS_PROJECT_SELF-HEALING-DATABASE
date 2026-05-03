@echo off
set DB_NAME=dbms_self_healing
set DB_USER=root
set DB_PASS=Tsr@2007

echo Deploying SQL files to %DB_NAME%...

echo [1/2] Deploying AI Engine...
for %%f in (app\database\sql\ai_engine\*.sql) do (
    echo Applying %%f...
    mysql -h localhost -u %DB_USER% -p%DB_PASS% %DB_NAME% < %%f
)

echo [2/2] Deploying Decision Engine...
for %%f in (app\database\sql\step2_engine\*.sql) do (
    echo Applying %%f...
    mysql -h localhost -u %DB_USER% -p%DB_PASS% %DB_NAME% < %%f
)

echo Deployment complete.

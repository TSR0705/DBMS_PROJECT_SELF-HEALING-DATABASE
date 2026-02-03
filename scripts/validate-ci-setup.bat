@echo off
REM DBMS Project CI Setup Validation Script (Windows)
REM Run this script to validate CI configuration before pushing

echo 🔍 DBMS Project CI Setup Validation
echo ==================================
echo.

REM Function to check if command exists
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js not found - required for frontend checks
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo ✅ Node.js found: %NODE_VERSION%
)

where python >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python not found - required for backend checks
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('python --version') do set PYTHON_VERSION=%%i
    echo ✅ Python found: %PYTHON_VERSION%
)

echo.
echo 2️⃣ Validating Project Structure...
echo --------------------------------

REM Check required directories
if exist "dbms-self-healing-ui" (
    echo ✅ Directory exists: dbms-self-healing-ui
) else (
    echo ❌ Missing directory: dbms-self-healing-ui
    exit /b 1
)

if exist "dbms-backend" (
    echo ✅ Directory exists: dbms-backend
) else (
    echo ❌ Missing directory: dbms-backend
    exit /b 1
)

if exist "DATABASE_THINGS" (
    echo ✅ Directory exists: DATABASE_THINGS
) else (
    echo ❌ Missing directory: DATABASE_THINGS
    exit /b 1
)

if exist ".github\workflows" (
    echo ✅ Directory exists: .github\workflows
) else (
    echo ❌ Missing directory: .github\workflows
    exit /b 1
)

REM Check required files
if exist "dbms-self-healing-ui\package.json" (
    echo ✅ File exists: dbms-self-healing-ui\package.json
) else (
    echo ❌ Missing file: dbms-self-healing-ui\package.json
    exit /b 1
)

if exist "dbms-backend\requirements.txt" (
    echo ✅ File exists: dbms-backend\requirements.txt
) else (
    echo ❌ Missing file: dbms-backend\requirements.txt
    exit /b 1
)

if exist "DATABASE_THINGS\schema_refactored.sql" (
    echo ✅ File exists: DATABASE_THINGS\schema_refactored.sql
) else (
    echo ❌ Missing file: DATABASE_THINGS\schema_refactored.sql
    exit /b 1
)

if exist ".github\workflows\ci.yml" (
    echo ✅ File exists: .github\workflows\ci.yml
) else (
    echo ❌ Missing file: .github\workflows\ci.yml
    exit /b 1
)

echo.
echo 🎉 CI Setup Validation Complete!
echo ===============================
echo.
echo ✅ Basic checks passed - your CI setup looks ready!
echo.
echo Next steps:
echo 1. Commit your changes
echo 2. Push to trigger CI pipeline
echo 3. Monitor CI results in GitHub Actions
echo.
echo 📚 For more information, see .github\CI_README.md

pause
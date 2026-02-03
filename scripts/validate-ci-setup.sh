#!/bin/bash

# DBMS Project CI Setup Validation Script
# Run this script to validate CI configuration before pushing

set -e  # Exit on any error

echo "🔍 DBMS Project CI Setup Validation"
echo "=================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ "$2" = "SUCCESS" ]; then
        echo -e "${GREEN}✅ $1${NC}"
    elif [ "$2" = "WARNING" ]; then
        echo -e "${YELLOW}⚠️  $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "1️⃣ Checking Prerequisites..."
echo "----------------------------"

# Check Node.js
if command_exists node; then
    NODE_VERSION=$(node --version)
    print_status "Node.js found: $NODE_VERSION" "SUCCESS"
else
    print_status "Node.js not found - required for frontend checks" "ERROR"
    exit 1
fi

# Check Python
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version)
    print_status "Python found: $PYTHON_VERSION" "SUCCESS"
else
    print_status "Python3 not found - required for backend checks" "ERROR"
    exit 1
fi

# Check MySQL (optional for local testing)
if command_exists mysql; then
    MYSQL_VERSION=$(mysql --version | cut -d' ' -f3)
    print_status "MySQL found: $MYSQL_VERSION" "SUCCESS"
else
    print_status "MySQL not found - CI will use Docker container" "WARNING"
fi

echo ""
echo "2️⃣ Validating Project Structure..."
echo "--------------------------------"

# Check required directories
REQUIRED_DIRS=("dbms-self-healing-ui" "dbms-backend" "DATABASE_THINGS" ".github/workflows")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        print_status "Directory exists: $dir" "SUCCESS"
    else
        print_status "Missing directory: $dir" "ERROR"
        exit 1
    fi
done

# Check required files
REQUIRED_FILES=(
    "dbms-self-healing-ui/package.json"
    "dbms-backend/requirements.txt"
    "DATABASE_THINGS/schema_refactored.sql"
    ".github/workflows/ci.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_status "File exists: $file" "SUCCESS"
    else
        print_status "Missing file: $file" "ERROR"
        exit 1
    fi
done

echo ""
echo "3️⃣ Validating CI Configuration..."
echo "-------------------------------"

# Check CI workflow file
if grep -q "DBMS Project CI Pipeline" .github/workflows/ci.yml; then
    print_status "CI workflow file is properly configured" "SUCCESS"
else
    print_status "CI workflow file may be corrupted" "ERROR"
    exit 1
fi

# Check for required CI jobs
REQUIRED_JOBS=("frontend-checks" "backend-checks" "database-schema-validation" "security-checks")
for job in "${REQUIRED_JOBS[@]}"; do
    if grep -q "$job:" .github/workflows/ci.yml; then
        print_status "CI job defined: $job" "SUCCESS"
    else
        print_status "Missing CI job: $job" "ERROR"
        exit 1
    fi
done

echo ""
echo "4️⃣ Testing Frontend Setup..."
echo "---------------------------"

cd dbms-self-healing-ui

# Check if package.json has required scripts
if grep -q '"lint"' package.json && grep -q '"build"' package.json; then
    print_status "Frontend scripts configured correctly" "SUCCESS"
else
    print_status "Missing required frontend scripts" "ERROR"
    exit 1
fi

# Check if dependencies can be installed (quick check)
if [ -f "package-lock.json" ]; then
    print_status "package-lock.json exists - dependencies locked" "SUCCESS"
else
    print_status "package-lock.json missing - run 'npm install'" "WARNING"
fi

cd ..

echo ""
echo "5️⃣ Testing Backend Setup..."
echo "-------------------------"

cd dbms-backend

# Check Python requirements
if python3 -c "import sys; print('Python version check passed')" 2>/dev/null; then
    print_status "Python environment is functional" "SUCCESS"
else
    print_status "Python environment issues detected" "ERROR"
    exit 1
fi

# Check if pytest configuration exists
if [ -f "pytest.ini" ]; then
    print_status "pytest configuration found" "SUCCESS"
else
    print_status "pytest configuration missing" "WARNING"
fi

cd ..

echo ""
echo "6️⃣ Validating Database Schema..."
echo "------------------------------"

# Check schema file syntax (basic)
if sql_syntax_check=$(python3 -c "
import re
with open('DATABASE_THINGS/schema_refactored.sql', 'r') as f:
    content = f.read()
    if 'CREATE TABLE' in content and 'FOREIGN KEY' in content:
        print('Schema file contains expected SQL structures')
    else:
        raise Exception('Schema file may be incomplete')
" 2>&1); then
    print_status "Schema file structure validation passed" "SUCCESS"
else
    print_status "Schema file validation failed: $sql_syntax_check" "ERROR"
    exit 1
fi

echo ""
echo "7️⃣ Security Validation..."
echo "-----------------------"

# Check for common secret patterns (basic check)
if grep -r -i "password.*=" --include="*.py" --include="*.js" --include="*.ts" . | grep -v ".env.example" | grep -v "ci_test_password" | grep -v "validate-ci-setup.sh" >/dev/null; then
    print_status "Potential hardcoded passwords detected" "ERROR"
    echo "Run: grep -r -i 'password.*=' --include='*.py' --include='*.js' --include='*.ts' ."
    exit 1
else
    print_status "No obvious hardcoded passwords found" "SUCCESS"
fi

# Check .env file handling
if [ -f "dbms-backend/.env" ]; then
    print_status ".env file exists - ensure it's in .gitignore" "WARNING"
else
    print_status "No .env file committed (good)" "SUCCESS"
fi

echo ""
echo "🎉 CI Setup Validation Complete!"
echo "==============================="
echo ""
echo "✅ All checks passed - your CI setup is ready!"
echo ""
echo "Next steps:"
echo "1. Commit your changes"
echo "2. Push to trigger CI pipeline"
echo "3. Monitor CI results in GitHub Actions"
echo ""
echo "📚 For more information, see .github/CI_README.md"
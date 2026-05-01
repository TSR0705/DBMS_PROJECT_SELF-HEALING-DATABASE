# CI/CD Pipeline Guide

## 🔍 Problem Identified

**Issue**: Only 2 out of 7 CI/CD jobs were executing

**Root Cause**: Branch naming mismatch
- CI workflow configured to trigger on: `feature/*`
- Your branch named: `feat/hardened-phase5-architecture`
- Pattern `feature/*` does NOT match `feat/*`

**Fix Applied**: Added `feat/*` to workflow triggers

---

## 📊 CI/CD Pipeline Structure

The pipeline consists of **7 jobs** with dependencies:

```
┌─────────────────────┐
│  1. frontend-checks │ (Independent)
└─────────────────────┘

┌─────────────────────┐
│  2. backend-checks  │ (Independent)
└──────────┬──────────┘
           │
           ├──────────────────────┐
           │                      │
           ▼                      ▼
┌─────────────────────┐  ┌──────────────────────────┐
│  4. api-validation  │  │ 3. database-schema-val   │ (Independent)
└──────────┬──────────┘  └────────────┬─────────────┘
           │                          │
           └──────────┬───────────────┘
                      │
                      ▼
           ┌──────────────────────┐
           │ 6. integration-test  │
           └──────────┬───────────┘
                      │
┌─────────────────────┤
│  5. security-checks │ (Independent)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────┐
│ 7. integration-check    │ (Depends on ALL)
└─────────────────────────┘
```

---

## 🎯 Job Details

### 1️⃣ Frontend Checks (Independent)
**Purpose**: Validate Next.js + TypeScript frontend

**Steps**:
- ✅ Install dependencies (`npm ci`)
- ✅ TypeScript type check (`tsc --noEmit`)
- ✅ ESLint code quality check
- ✅ Production build test

**Runtime**: ~2-3 minutes

---

### 2️⃣ Backend Checks (Independent)
**Purpose**: Validate Python + FastAPI backend

**Steps**:
- ✅ Install Python dependencies
- ✅ Python syntax validation
- ✅ Flake8 code quality check
- ✅ Pytest unit tests

**Runtime**: ~1-2 minutes

---

### 3️⃣ Database Schema Validation (Independent)
**Purpose**: Validate MySQL schema and stored procedures

**Steps**:
- ✅ Start MySQL 8.0 service
- ✅ Load main schema (`dbms_self_healing.sql`)
- ✅ Load AI engine procedures
- ✅ Load decision engine procedures
- ✅ Validate table structure
- ✅ Validate stored procedures (min 8 expected)
- ✅ Validate foreign key constraints (min 4 expected)
- ✅ Schema integrity check

**Runtime**: ~3-4 minutes

---

### 4️⃣ API Validation (Depends on: backend-checks)
**Purpose**: Validate FastAPI endpoints

**Steps**:
- ✅ Start FastAPI server
- ✅ Test root endpoint (`/`)
- ✅ Test health endpoint (`/health/`)
- ✅ Test OpenAPI docs (`/docs`)
- ✅ Validate JSON response structure

**Runtime**: ~1-2 minutes

**Why it depends on backend-checks**: Ensures Python code is valid before starting server

---

### 5️⃣ Security Checks (Independent)
**Purpose**: Scan for security vulnerabilities

**Steps**:
- ✅ Scan for hardcoded passwords
- ✅ Scan for hardcoded API keys
- ✅ Scan for hardcoded secrets
- ✅ Validate environment file structure
- ✅ SQL injection vulnerability check

**Runtime**: ~30 seconds

---

### 6️⃣ Integration Test (Depends on: database-schema-validation, api-validation)
**Purpose**: Test full system flow end-to-end

**Steps**:
- ✅ Start MySQL service
- ✅ Load schema and procedures
- ✅ Start FastAPI server
- ✅ Insert test issue via SQL
- ✅ Verify issue appears in API
- ✅ Check analysis, decisions, actions, learning

**Runtime**: ~3-4 minutes

**Why it depends on both**: Needs validated database schema AND working API

---

### 7️⃣ Integration Check (Depends on: ALL previous jobs)
**Purpose**: Final validation and summary

**Steps**:
- ✅ Validate project structure
- ✅ Validate API endpoint consistency
- ✅ Generate CI pipeline summary

**Runtime**: ~30 seconds

**Why it depends on all**: Final gate - only runs if everything else passes

---

## 🔧 Trigger Configuration

### Before Fix:
```yaml
on:
  push:
    branches: [ main, develop, feature/* ]
  pull_request:
    branches: [ main, develop ]
```

### After Fix:
```yaml
on:
  push:
    branches: [ main, develop, feature/*, feat/* ]
  pull_request:
    branches: [ main, develop ]
```

---

## 🚨 Common Issues & Solutions

### Issue 1: Jobs Not Running
**Symptom**: Only 2 jobs execute, rest are skipped

**Causes**:
1. ❌ Branch name doesn't match trigger pattern
2. ❌ Previous job failed (dependency not met)
3. ❌ Workflow file syntax error

**Solutions**:
1. ✅ Ensure branch matches `main`, `develop`, `feature/*`, or `feat/*`
2. ✅ Check logs of dependent jobs for failures
3. ✅ Validate YAML syntax

---

### Issue 2: Database Schema Validation Fails
**Symptom**: "Error 1064" or "syntax error"

**Causes**:
1. ❌ SQL file has syntax errors
2. ❌ `DELIMITER //` not supported in piped input
3. ❌ `IF NOT EXISTS` syntax not supported in MySQL version

**Solutions**:
1. ✅ Test SQL files locally first
2. ✅ Use `mysql < file.sql` (not `cat file.sql | mysql`)
3. ✅ Add columns to base schema, not in procedure files

---

### Issue 3: Integration Test Fails
**Symptom**: "Issue not found in API"

**Causes**:
1. ❌ Database connection failed
2. ❌ Procedures not loaded correctly
3. ❌ API server not started

**Solutions**:
1. ✅ Check MySQL service health
2. ✅ Verify procedure count (should be ≥8)
3. ✅ Add sleep delay after server start

---

## 📈 Expected Results

### ✅ All Jobs Pass
```
✅ frontend-checks (2-3 min)
✅ backend-checks (1-2 min)
✅ database-schema-validation (3-4 min)
✅ api-validation (1-2 min)
✅ security-checks (30 sec)
✅ integration-test (3-4 min)
✅ integration-check (30 sec)

Total: ~12-15 minutes
```

### ❌ Partial Failure Example
```
✅ frontend-checks
❌ backend-checks (Python syntax error)
✅ database-schema-validation
⏸️ api-validation (skipped - depends on backend-checks)
✅ security-checks
⏸️ integration-test (skipped - depends on api-validation)
⏸️ integration-check (skipped - depends on all)
```

---

## 🎯 Best Practices

1. **Branch Naming**: Use `feature/*` or `feat/*` for feature branches
2. **Local Testing**: Run tests locally before pushing
3. **Incremental Commits**: Commit small changes to isolate failures
4. **Check Logs**: Always check failed job logs for details
5. **Dependencies**: Understand job dependencies to debug skipped jobs

---

## 🔗 Useful Commands

### Check CI Status (requires GitHub CLI)
```bash
gh run list --limit 5
gh run view <run-id>
gh run watch
```

### Local Testing
```bash
# Frontend
cd dbms-self-healing-ui
npm ci
npx tsc --noEmit
npm run lint
npm run build

# Backend
cd dbms-backend
pip install -r requirements.txt
python -m compileall . -f -q
flake8 .
python -m pytest -v

# Database
mysql -u root -p < dbms_self_healing.sql
```

---

**Last Updated**: April 25, 2026  
**Status**: ✅ All 7 jobs now configured to run on `feat/*` branches

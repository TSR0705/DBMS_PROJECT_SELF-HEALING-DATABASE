# Getting Started Guide

Follow this guide to spin up the local development environment for the Self Healing Database Interface.

## Prerequisites
- Node.js (v18+)
- Python (v3.10+)
- MySQL Server 8.0

## 1. Local Database Setup
1. Launch your MySQL server instance.
2. Ensure you have executed `dbms_self_healing.sql` at the root folder against your database.
3. This will create and seed all the `ai_analysis`, `health_metrics`, and `detected_issues` tables required.

## 2. API Backend
The backend runs on Python + FastAPI. It is strictly tested with Python versions `<3.14`. You must spawn the environment exactly like this:

```bash
cd dbms-backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8002 --reload
```

## 3. Web Dashboard (UI)
The web dashboard relies on the environment to be correctly pathed. Copy `.env.example` to `.env` if necessary.

```bash
cd dbms-self-healing-ui
npm install
npm run dev
```

The interface will be running locally at `localhost:3000`. Navigate to `localhost:3000/dashboard/overview` to view the control center directly.

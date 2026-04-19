# 🚀 Setup & Installation Guide

Follow this definitive guide to set up the **AI-Powered DBMS Self-Healing Engine** in your local development environment.

---

## 📋 Prerequisites

Ensure you have the following installed on your system:
- **Python 3.10+**: Core engine runtime.
- **Node.js 18+**: Frontend dashboard runtime.
- **MySQL 8.0+**: Primary relational storage.
- **Git**: Version control.

---

## 🗄️ 1. Database Initialization

The self-healing logic relies on specific triggers and metadata tables defined in the schema.

1.  **Launch MySQL Service**: Ensure your local or remote instance is running.
2.  **Create Database**:
    ```sql
    CREATE DATABASE dbms_self_healing;
    ```
3.  **Execute Schema**: Run the provided `dbms_self_healing.sql` located at the root of the project.
    ```bash
    mysql -u root -p dbms_self_healing < dbms_self_healing.sql
    ```
    *This will create all 7 core tables and the specialized triggers.*

---

## 🐍 2. Backend API Setup (FastAPI)

Navigate to the backend directory and install dependencies.

1.  **Change Directory**: `cd dbms-backend`
2.  **Virtual Env (Recommended)**:
    ```bash
    python -m venv venv
    source venv/bin/activate  # Windows: venv\Scripts\activate
    ```
3.  **Install Requirements**:
    ```bash
    pip install fastapi uvicorn mysql-connector-python sqlalchemy pydantic
    ```
4.  **Launch Server**:
    ```bash
    python -m uvicorn app.main:app --host 0.0.0.0 --port 8002 --reload
    ```
    *Open `http://localhost:8002/health/database` to verify. Status should be `healthy`.*

---

## ⚛️ 3. Frontend UI Setup (Next.js)

The dashboard is a modern Next.js application that visuals the health logic.

1.  **Change Directory**: `cd dbms-self-healing-ui`
2.  **Install Dependencies**:
    ```bash
    npm install
    ```
3.  **Configure Environment**: (If applicable) Update `lib/api.ts` to ensure the `BASE_URL` points to `http://localhost:8002`.
4.  **Start Development Server**:
    ```bash
    npm run dev
    ```
    *Access the dashboard at `http://localhost:3000/dashboard/overview`.*

---

## 🧪 4. Simulating an Anomaly

To see the system in action, manually insert a "Deadlock" issue into the database:

```sql
INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit)
VALUES ('DEADLOCK', 'INNODB', 1.00, 'transaction');
```

1.  Watch the **Backend Terminal**: You will see the Decision Engine classifying the issue.
2.  Refresh the **UI Dashboard**: The anomaly will appear in the "Admin Control Center" or "Learning Ecosystem" tables based on the confidence score assigned.

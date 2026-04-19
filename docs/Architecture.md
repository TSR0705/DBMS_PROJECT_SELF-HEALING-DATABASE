# System Architecture

The AI-Powered Self-Healing Database project is composed of a decoupled Frontend, Backend, and Relational Database layer.

## High-Level Diagram
1. **dbms-self-healing-ui** (Next.js + TailwindCSS)
2. **dbms-backend** (FastAPI)
3. **Database** (MySQL 8.0)

## 1. Frontend: Admin Control Center UI
The user interface provides live dashboard analytics representing the backend health.
- **Framework**: Built on React and Next.js 14.
- **Styling**: Tailwind CSS utilizing deep glassmorphism aesthetics.
- **Components**: Shadcn UI generic data tables enhanced with custom renderers.
- **Endpoints Interfaced**: Fetches payload periodically from the FastAPI backend to visualize real-time resolutions.

## 2. Backend: FastAPI Resolution Engine
Python 3.12+ drives the logic behind the application. 
- **Framework**: FastAPI (Asynchronous endpoints).
- **ORM**: MySQL Connector matching native Database Triggers and logic.
- **Validation**: Pydantic strictly validates DB records before resolving.
- **Modules**:
  - `routers/admin_reviews.py` - Connects the React approval grid.
  - `routers/analysis.py` - Fetches overall stats.

## 3. Database: Relational Self-Healing Schema
The backend natively attempts to log failures utilizing event triggers.
- **Triggers**: Natively set to observe specific log conditions.
- **Tables**: `decision_log`, `admin_reviews`, `ai_analysis`, `detected_issues`, `healing_actions`.

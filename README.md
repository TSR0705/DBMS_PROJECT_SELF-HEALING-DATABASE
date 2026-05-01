<div align="center">
 

  <h1>🔮 AI-Powered DBMS Self-Healing Engine</h1>

  <p><b>The state-of-the-art anomaly resolution framework bridging modern web technologies and a self-repairing SQL transaction pipeline.</b></p>

  <p>
    <img src="https://img.shields.io/badge/build-passing-brightgreen" alt="Build Status">
    <img src="https://img.shields.io/badge/Next.js-14-black" alt="Next.js">
    <img src="https://img.shields.io/badge/FastAPI-0.100+-00a393" alt="FastAPI">
    <img src="https://img.shields.io/badge/MySQL-8.0-blue" alt="MySQL">
    <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License">
  </p>
</div>

---

## 🌟 The Vision

Manual database administration is a bottleneck. In high-concurrency environments, deadlocks, connection overloads, and slow queries can cascade into system-wide outages before a DBA even receives an alert. 

Our **Self-Healing Engine** monitors the database pulse and takes **autonomous, zero-latency corrective action** before minor issues become catastrophic failures.

---

## ✨ System Showcase

<table>
  <tr>
    <td width="50%" align="center">
      <img src="docs/PHOTOS/Screenshot 2026-05-01 140537.png" alt="Real-Time Dashboard" width="100%">
      <br>
      <sub><b>Real-Time Command Center</b></sub>
      <br>
      <sub>Live metrics, issue detection, and system health monitoring</sub>
    </td>
    <td width="50%" align="center">
      <img src="docs/PHOTOS/Screenshot 2026-05-01 210613.png" alt="Issue Detection Pipeline" width="100%">
      <br>
      <sub><b>Intelligent Issue Detection</b></sub>
      <br>
      <sub>Automated anomaly classification with severity scoring</sub>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="docs/PHOTOS/Screenshot 2026-05-01 210643.png" alt="AI Analysis Engine" width="100%">
      <br>
      <sub><b>AI-Powered Analysis</b></sub>
      <br>
      <sub>Z-score confidence and risk assessment in real-time</sub>
    </td>
    <td width="50%" align="center">
      <img src="docs/PHOTOS/Screenshot 2026-05-01 210701.png" alt="Decision System" width="100%">
      <br>
      <sub><b>Autonomous Decision Engine</b></sub>
      <br>
      <sub>Auto-heal vs. admin review routing with confidence thresholds</sub>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="docs/PHOTOS/healing-actions.png" alt="Healing Actions" width="100%">
      <br>
      <sub><b>Surgical Healing Execution</b></sub>
      <br>
      <sub>Real-time action tracking with verification status</sub>
    </td>
    <td width="50%" align="center">
      <img src="docs/PHOTOS/admin-review.png" alt="Admin Control" width="100%">
      <br>
      <sub><b>Human-in-the-Loop Control</b></sub>
      <br>
      <sub>Admin review queue for ambiguous cases requiring validation</sub>
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <img src="docs/PHOTOS/learning-ecosystem.png" alt="Learning Ecosystem" width="70%">
      <br>
      <sub><b>Continuous Learning Ecosystem</b></sub>
      <br>
      <sub>Feedback loop tracking outcomes and improving decision confidence over time</sub>
    </td>
  </tr>
</table>

---

## 🎯 Key Features

<table>
  <tr>
    <td width="33%" align="center">
      <h3>⚡ Sub-Second Detection</h3>
      <p>MySQL Event Scheduler polls every 1 second, detecting anomalies before they cascade into system failures</p>
    </td>
    <td width="33%" align="center">
      <h3>🧠 AI-Driven Decisions</h3>
      <p>Z-score confidence scoring and baseline analysis determine auto-heal vs. human review routing</p>
    </td>
    <td width="33%" align="center">
      <h3>🔧 Surgical Execution</h3>
      <p>Targeted process kills using sys.innodb_lock_waits mapping—no blind terminations</p>
    </td>
  </tr>
  <tr>
    <td width="33%" align="center">
      <h3>🛡️ Safety Guards</h3>
      <p>10-second race condition protection and iterative relief loops prevent over-correction</p>
    </td>
    <td width="33%" align="center">
      <h3>📊 Real-Time Dashboard</h3>
      <p>Glassmorphism UI with live metrics, pipeline visualization, and admin override controls</p>
    </td>
    <td width="33%" align="center">
      <h3>🔄 Continuous Learning</h3>
      <p>Feedback loop tracks outcomes and adjusts confidence thresholds over time</p>
    </td>
  </tr>
</table>

---

## 🚀 Quick Navigation

Explore our comprehensive documentation suite for deep technical insights:

| 📍 Topic | 📁 Documentation Link |
| :--- | :--- |
| **Blueprint** | [System Architecture](./docs/Architecture.md) |
| **Logic** | [The Self-Healing Engine](./docs/Healing_Engine_Design.md) |
| **Database** | [Database Design & ERD](./docs/Database_Design.md) |
| **Guides** | [Setup & Installation Guide](./docs/Setup_Guide.md) |
| **API** | [Technical API Reference](./docs/API_Documentation.md) |

---

## 📊 Event-Driven Architecture

Our Phase 7 architecture utilizes a pure SQL Event-Driven model, ensuring maximum performance without the latency of external Python orchestration.

```mermaid
graph TD
    subgraph "Admin Interface"
        UI[Next.js Glassmorphism Dashboard]
    end

    subgraph "Intelligence & API Layer"
        Backend[FastAPI REST Bridge]
    end

    subgraph "Data & Active SQL Engine"
        DB[(MySQL Production)]
        Orchestrator[1s Event Scheduler]
        DecisionEng[Decision & Execution SPs]
    end

    %% Flow
    DB -- "1. Anomaly Captured" --> DB
    Orchestrator -- "2. Trigger Analysis" --> DecisionEng
    DecisionEng -- "3. Z-Score Priority Scoring" --> DecisionEng
    
    DecisionEng -- "4a. Auto-Action (Immediate Surgical Kill)" --> DB
    DecisionEng -- "4b. Flag for Review (Low Impact)" --> DB
    
    Backend -- "5. Polling State" --> DB
    Backend -- "6. JSON State Sync" --> UI
    
    UI -- "7. Human Override" --> Backend
    Backend -- "8. Trigger Action" --> DB
```

---

## 🛠️ Tech Stack

*   **Frontend**: Next.js 14, Tailwind CSS, Recharts, Lucide Icons.
*   **Backend**: Python 3.14, FastAPI, SQLAlchemy, Pydantic.
*   **Database**: MySQL 8.0 with Native Event Scheduler and Stored Procedures.

---

## 🛡️ Safety & Security Guarantees

To prevent accidental data loss, the engine operates under strict **Safety Guards**:
- **Surgical Process Kills**: Deadlock and overload resolutions specifically target blocking `trx_mysql_thread_id` PIDs, never blindly terminating threads.
- **Iterative Relief Loops**: Overload reductions happen iteratively until the system stabilizes beneath safe thresholds.
- **10-Second Race Guard**: Aborts healing executions if the anomaly is older than 10 seconds to avoid fighting "ghost" issues.

---

<div align="center">
  <p>© 2026 DBMS Self-Healing Team. Built for performance, designed for resilience.</p>
</div>

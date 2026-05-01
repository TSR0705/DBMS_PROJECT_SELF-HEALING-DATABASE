# 🔌 API Documentation

This project utilizes [FastAPI](https://fastapi.tiangolo.com/) for high-performance orchestration. All endpoints return strictly validated JSON structures matching our Pydantic models.

---

## 🛰️ Base Configuration
- **Host**: `0.0.0.0` (accessible via localhost)
- **Port**: `8002`
- **Documentation**: Swagger UI is available at `/docs` when the server is running.

---

## 🛠️ Endpoints

### 🟢 1. Health & Status
Checks the heartbeat of the self-healing engine and its connectivity to the MySQL instance.

- **URL**: `/health/database`
- **Method**: `GET`
- **Response Shape**:
  ```json
  {
    "status": "healthy",
    "database_connected": true,
    "engines_active": ["decision", "healing", "admin"]
  }
  ```

### 📊 2. Dashboard Overview
Fetches aggregated statistics and the latest 10 anomalies for the high-level monitor.

- **URL**: `/dashboard/overview/`
- **Method**: `GET`
- **Logic**: Joins `detected_issues`, `ai_analysis`, and `decision_log` to provide a holistic view of recent database health.

### ⚖️ 3. Admin Reviews
Provides CRUD operations for human-in-the-loop decisions.

#### List Reviews
- **URL**: `/admin-reviews/`
- **Method**: `GET`
- **Query Params**: `status` (Optional: PENDING, APPROVED, REJECTED)

#### Update Review (Approval Workflow)
- **URL**: `/admin-reviews/{review_id}`
- **Method**: `PUT`
- **Body**:
  ```json
  {
    "action": "APPROVED",
    "comment": "Safe to rollback.",
    "override": true
  }
  ```

---

## 🧩 Data Schemas (Pydantic)

The system enforces strict typing to ensure the Frontend receives consistent data formats, especially for complex MySQL `Decimal` and `Timestamp` types.

### `IssueResponse`
| Field | Type | Description |
| :--- | :--- | :--- |
| `issue_id` | `int` | Unique ID from `detected_issues`. |
| `issue_type` | `string` | Classification (e.g., DEADLOCK). |
| `confidence` | `float` | AI-assigned confidence (0.0 - 1.0). |

---

## 🧪 Testing with Postman/cURL
A pre-configured `postman-collection.json` is available in the `docs/` directory for standard testing. Alternatively, you can use:

```bash
curl -X GET "http://localhost:8002/admin-reviews/"
```

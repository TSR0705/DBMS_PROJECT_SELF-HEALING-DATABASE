# ⚠️ DEPRECATED - API Reference (FastAPI)

> **This document has been superseded by [API_Documentation.md](../API_Documentation.md)**  
> **Last Updated:** Legacy (Pre-Phase 7)  
> **Status:** Archived for historical reference only  
> **Use Instead:** [docs/API_Documentation.md](../API_Documentation.md) for current, comprehensive API documentation

---

# API Reference (FastAPI)

The Database strictly limits external interactions to endpoints strictly tied to validation and metric resolution.

## Base URL
> `http://localhost:8002`

## Endpoint: GET `/admin-reviews/`
Fetches a list of pending, rejected, and approved administrator decisions to populate the Admin Control UI.

- **Returns**: A JSON payload consisting of multiple array entities mapped from raw SQLAlchemy validation items.
- **Data Shape Considerations**: `confidence_score`, `baseline_metric` are transformed correctly from Decimal values native to MySQL, explicitly preventing `Nan` data corruption on Pydantic's endpoint evaluation. 

## Endpoint: GET `/health/database`
Returns 200 HTTP OK if the engine can successfully execute read, write, and AI validation operations. It implicitly returns false if connection is lost.

## Security Practices
No Authentication layer exists locally, intended to run behind an external OAuth network ingress.

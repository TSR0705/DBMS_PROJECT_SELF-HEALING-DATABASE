@echo off
echo Starting DBMS Self-Healing Dashboard...
echo.

echo Starting Backend API Server...
start "Backend API" cmd /k "cd dbms-backend && python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8002"

echo Waiting for backend to start...
timeout /t 3 /nobreak > nul

echo Starting Frontend Development Server...
start "Frontend UI" cmd /k "cd dbms-self-healing-ui && npm run dev"

echo.
echo Both servers are starting...
echo Backend API: http://localhost:8002
echo Frontend UI: http://localhost:3000
echo API Docs: http://localhost:8002/docs
echo.
pause
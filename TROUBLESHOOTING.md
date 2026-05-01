# 🔧 Troubleshooting Guide

## Frontend Showing "Offline" / Cannot Connect to Backend

### Quick Diagnosis Checklist

#### 1. **Is the Backend Running?**
```bash
# Check if backend is running on port 8002
curl http://localhost:8002/

# Expected response:
# {"name":"DBMS Self-Healing API","version":"1.0.0","status":"operational"}
```

**If this fails:**
- Backend is not running
- Backend is running on a different port
- Firewall is blocking the connection

---

#### 2. **Start the Backend**

**Option A: Using Python directly**
```bash
cd dbms-backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8002 --reload
```

**Option B: Using the main.py script**
```bash
cd dbms-backend
python app/main.py
```

**Expected Output:**
```
INFO:     Uvicorn running on http://0.0.0.0:8002 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

---

#### 3. **Check Database Connection**

The backend needs MySQL running:

```bash
# Check if MySQL is running
mysql -u root -p -e "SELECT 1;"

# Check if database exists
mysql -u root -p -e "SHOW DATABASES LIKE 'dbms_self_healing%';"
```

**If database doesn't exist:**
```bash
# Create database
mysql -u root -p < dbms_self_healing.sql

# Load procedures
cd dbms-backend/app/database/sql
mysql -u root -p dbms_self_healing < ai_engine/*.sql
mysql -u root -p dbms_self_healing < step2_engine/*.sql
```

---

#### 4. **Configure Environment Variables**

**Backend (.env file):**
```bash
cd dbms-backend
cp .env.example .env
```

Edit `.env` with your actual credentials:
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_actual_password
DB_NAME=dbms_self_healing

API_HOST=0.0.0.0
API_PORT=8002
```

**Frontend (optional .env.local):**
```bash
cd dbms-self-healing-ui
```

Create `.env.local` (optional, defaults to localhost:8002):
```env
NEXT_PUBLIC_API_URL=http://localhost:8002
NEXT_PUBLIC_ADMIN_TOKEN=your-api-key-change-in-production-use-strong-random-key
```

---

#### 5. **Start the Frontend**

```bash
cd dbms-self-healing-ui
npm install
npm run dev
```

**Expected Output:**
```
▲ Next.js 14.x.x
- Local:        http://localhost:3000
- Ready in 2.5s
```

---

#### 6. **Verify Connection**

Open browser to `http://localhost:3000`

**Check Browser Console (F12):**
```
API Client initialized with URL: http://localhost:8002
```

**If you see errors:**
- `Network error - Cannot connect to API server` → Backend not running
- `CORS error` → Backend CORS misconfigured
- `404 Not Found` → Wrong API URL

---

### Common Issues & Solutions

#### Issue 1: Port Already in Use

**Error:**
```
ERROR: [Errno 48] Address already in use
```

**Solution:**
```bash
# Find process using port 8002
lsof -i :8002  # Mac/Linux
netstat -ano | findstr :8002  # Windows

# Kill the process
kill -9 <PID>  # Mac/Linux
taskkill /PID <PID> /F  # Windows

# Or use a different port
python -m uvicorn app.main:app --port 8003
```

---

#### Issue 2: CORS Error

**Error in Browser Console:**
```
Access to fetch at 'http://localhost:8002' from origin 'http://localhost:3000' 
has been blocked by CORS policy
```

**Solution:**

Check `dbms-backend/.env`:
```env
FRONTEND_URL=http://localhost:3000
```

Restart backend after changing `.env`

---

#### Issue 3: Database Connection Failed

**Error:**
```
ERROR: Can't connect to MySQL server on 'localhost'
```

**Solution:**

1. **Start MySQL:**
```bash
# Mac
brew services start mysql

# Linux
sudo systemctl start mysql

# Windows
net start MySQL80
```

2. **Check credentials in `.env`:**
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=dbms_self_healing
```

3. **Test connection:**
```bash
mysql -h localhost -P 3306 -u root -p
```

---

#### Issue 4: Frontend Shows "Disconnected"

**Symptoms:**
- Red "Disconnected" badge in dashboard
- No data loading
- Console shows repeated fetch errors

**Solution:**

1. **Verify backend is responding:**
```bash
curl http://localhost:8002/health/
```

2. **Check backend logs** for errors

3. **Clear browser cache** and reload (Ctrl+Shift+R)

4. **Check if database has data:**
```sql
USE dbms_self_healing;
SELECT COUNT(*) FROM detected_issues;
SELECT COUNT(*) FROM ai_analysis;
```

---

### Port Configuration Summary

| Service | Default Port | Configuration File |
|---------|-------------|-------------------|
| **Frontend** | 3000 | `package.json` (Next.js default) |
| **Backend** | 8002 | `dbms-backend/.env` (API_PORT) |
| **MySQL** | 3306 | MySQL default |

---

### Testing the Full Stack

**1. Test Backend Health:**
```bash
curl http://localhost:8002/health/
```

**2. Test Database Connection:**
```bash
curl http://localhost:8002/health/database
```

**3. Test API Endpoints:**
```bash
curl http://localhost:8002/issues/
curl http://localhost:8002/analysis/
curl http://localhost:8002/decisions/
```

**4. Test Frontend:**
- Open `http://localhost:3000`
- Check browser console for errors
- Verify "Connected" badge shows green

---

### Still Having Issues?

**Enable Debug Mode:**

**Backend:**
```env
# In .env
DEBUG=True
```

**Frontend:**
```bash
# Check browser console (F12)
# Look for detailed error messages
```

**Check Logs:**
```bash
# Backend logs (if running in terminal)
# Look for ERROR or WARNING messages

# Frontend logs (browser console)
# Look for red error messages
```

---

### Quick Start Script

Create `start.sh` (Mac/Linux) or `start.bat` (Windows):

```bash
#!/bin/bash
# Start backend
cd dbms-backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8002 --reload &
BACKEND_PID=$!

# Wait for backend to start
sleep 3

# Start frontend
cd ../dbms-self-healing-ui
npm run dev &
FRONTEND_PID=$!

echo "Backend PID: $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"
echo ""
echo "Backend: http://localhost:8002"
echo "Frontend: http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop both services"

# Wait for Ctrl+C
trap "kill $BACKEND_PID $FRONTEND_PID" EXIT
wait
```

Make it executable:
```bash
chmod +x start.sh
./start.sh
```

---

## Need More Help?

1. Check the [Setup Guide](docs/Setup_Guide.md)
2. Review [API Documentation](docs/API_Documentation.md)
3. Check GitHub Issues for similar problems

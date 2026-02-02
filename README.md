# DBMS Self-Healing Dashboard

A modern, real-time dashboard for monitoring and managing a self-healing database management system. Built with Next.js frontend and FastAPI backend.

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- Node.js 18+
- MySQL database (for production data)

### 1. Backend Setup

```bash
cd dbms-backend

# Install Python dependencies
pip install -r requirements.txt

# Configure environment (copy and edit .env.example)
cp .env.example .env

# Start the API server
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Frontend Setup

```bash
cd dbms-self-healing-ui

# Install Node.js dependencies
npm install

# Start the development server
npm run dev
```

### 3. Quick Start (Windows)

Run both servers with one command:
```bash
start-dev.bat
```

## 🌐 Access Points

- **Frontend Dashboard**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **API Health Check**: http://localhost:8000/health

## 📊 Features

### Real-time Monitoring
- **Issues Dashboard**: Live detection and monitoring of database issues
- **System Health**: Real-time API and database connectivity status
- **Auto-refresh**: Automatic data updates every 30 seconds (issues) / 10 seconds (health)

### API Integration
- **RESTful API**: FastAPI backend with automatic OpenAPI documentation
- **Type Safety**: Full TypeScript integration with Pydantic models
- **Error Handling**: Comprehensive error handling and user feedback
- **CORS Support**: Configured for local development

### Modern UI/UX
- **Responsive Design**: Works on desktop and mobile devices
- **Loading States**: Skeleton loading and smooth transitions
- **Error States**: Clear error messages and connection status
- **Real-time Updates**: Live data polling with visual indicators

## 🏗️ Architecture

### Backend (FastAPI)
```
dbms-backend/
├── app/
│   ├── main.py              # FastAPI application
│   ├── database/
│   │   └── connection.py    # Database connection layer
│   ├── models/
│   │   └── schemas.py       # Pydantic data models
│   └── routers/
│       ├── issues.py        # Issues API endpoints
│       ├── actions.py       # Healing actions API
│       └── health.py        # Health check endpoints
├── requirements.txt         # Python dependencies
└── .env.example            # Environment configuration
```

### Frontend (Next.js)
```
dbms-self-healing-ui/
├── app/
│   ├── dashboard/          # Dashboard pages
│   │   ├── issues/         # Issues monitoring
│   │   └── system-health/  # Health monitoring
│   └── layout.tsx          # Root layout
├── components/
│   ├── ui-dbms/           # Custom DBMS components
│   └── layout/            # Layout components
├── lib/
│   └── api.ts             # API client
└── .env.local             # Environment variables
```

## 🔧 Configuration

### Backend Environment (.env)
```env
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=dbms_healing
DB_USER=your_username
DB_PASSWORD=your_password

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
```

### Frontend Environment (.env.local)
```env
# Backend API URL
NEXT_PUBLIC_API_URL=http://localhost:8000
```

## 📡 API Endpoints

### Issues
- `GET /issues/` - Get all detected issues
- `GET /issues/{issue_id}/analysis` - Get AI analysis for specific issue
- `GET /issues/{issue_id}/decision` - Get decision for specific issue

### Health
- `GET /health/` - Basic health check
- `GET /health/database` - Database connectivity check

### Actions
- `GET /actions/` - Get healing actions
- `GET /actions/{action_id}` - Get specific healing action

## 🔄 Real-time Features

### Auto-refresh Intervals
- **Issues Page**: 30 seconds
- **System Health**: 10 seconds
- **Visual Indicators**: Pulse animations for live data

### Connection Handling
- **Error States**: Clear error messages when backend is unavailable
- **Loading States**: Skeleton loading during data fetch
- **Retry Logic**: Automatic reconnection attempts

## 🛠️ Development

### Adding New Pages
1. Create page component in `app/dashboard/[page-name]/page.tsx`
2. Add route to sidebar structure in `components/layout/sidebar-structure.ts`
3. Implement API integration using `lib/api.ts`

### Adding New API Endpoints
1. Create router in `dbms-backend/app/routers/`
2. Define Pydantic models in `app/models/schemas.py`
3. Add database queries in router functions
4. Update API client in frontend `lib/api.ts`

## 🚨 Troubleshooting

### Backend Issues
- **Port 8000 in use**: Change port in uvicorn command
- **Database connection**: Check MySQL server and credentials
- **Import errors**: Ensure all `__init__.py` files exist

### Frontend Issues
- **API connection**: Verify backend is running on port 8000
- **CORS errors**: Check CORS configuration in backend
- **Build errors**: Run `npm install` to update dependencies

## 📈 Performance

### Optimization Features
- **Efficient Polling**: Smart refresh intervals based on data type
- **Error Boundaries**: Graceful error handling without crashes
- **Lazy Loading**: Components load only when needed
- **Caching**: Browser caching for static assets

## 🔐 Security

### Current Implementation
- **Read-only API**: All endpoints are GET requests only
- **Input Validation**: Pydantic models validate all inputs
- **Error Sanitization**: No sensitive data in error messages
- **CORS Configuration**: Restricted to development origins

## 📝 License

This project is part of a DBMS course project and is intended for educational purposes.
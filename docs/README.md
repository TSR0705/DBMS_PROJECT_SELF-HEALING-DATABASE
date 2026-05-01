# 📚 Documentation Index

Welcome to the **AI-Powered DBMS Self-Healing Engine** documentation. This index provides a clear path through all available documentation.

---

## 🚀 Getting Started

**New to the project?** Start here:

1. **[Setup Guide](Setup_Guide.md)** - Installation, prerequisites, and configuration
2. **[Architecture Overview](Architecture.md)** - High-level system design and components
3. **[API Documentation](API_Documentation.md)** - Complete API reference with examples

---

## 📖 Core Documentation

### System Design & Architecture

- **[Architecture.md](Architecture.md)**
  - System overview and component interactions
  - High-level design decisions
  - Technology stack
  - Deployment architecture

- **[Database Design](Database_Design.md)**
  - Complete schema reference
  - Table relationships and indexes
  - Stored procedures documentation
  - Trigger logic

- **[Healing Engine Design](Healing_Engine_Design.md)**
  - Phase 7 self-healing architecture
  - State machine diagrams
  - Decision engine logic
  - Execution and verification flow
  - **Latest:** SLOW_QUERY auto-healing implementation

### Development

- **[Setup Guide](Setup_Guide.md)**
  - Prerequisites (Python 3.10+, Node.js 18+, MySQL 8.0+)
  - Database initialization
  - Backend API setup (FastAPI)
  - Frontend dashboard setup (Next.js)
  - Environment configuration

- **[API Documentation](API_Documentation.md)**
  - Base configuration and endpoints
  - Health & status checks
  - Dashboard overview API
  - Admin review workflows
  - Request/response schemas
  - Authentication & security

### User Interface

- **[UI Design System](UI_Design_System.md)**
  - Component library
  - Design patterns
  - Styling guidelines
  - Dashboard layouts

---

## 🔧 Tools & Resources

- **[Postman Collection](postman-collection.json)** - API testing collection for all endpoints

---

## 📦 Recent Updates

### SLOW_QUERY Auto-Healing (Latest)
The system now automatically heals single slow queries without requiring manual review:

- **Validation Fix:** Single slow queries pass validation (previously required system pressure)
- **Action Mapping:** `SLOW_QUERY → KILL_SLOW_QUERY` rule added
- **Execution Engine:** Updated to handle KILL_SLOW_QUERY action type
- **Documentation:** See root-level markdown files for detailed implementation

**Related Files:**
- `SLOW_QUERY_VALIDATION_FIX.md` - Technical details
- `ACTION_MAPPING_FIX_SUMMARY.md` - Action mapping implementation
- `FULL_PIPELINE_TEST_RESULTS.md` - Test results and verification

---

## 🗂️ Documentation Structure

```
docs/
├── README.md                    ← You are here
├── Architecture.md              ← System design
├── Database_Design.md           ← Schema & procedures
├── Healing_Engine_Design.md     ← Self-healing logic
├── API_Documentation.md         ← API reference
├── Setup_Guide.md               ← Installation guide
├── UI_Design_System.md          ← Frontend design
├── postman-collection.json      ← API testing
└── archive/                     ← Deprecated docs
    ├── API_Reference.md         (superseded by API_Documentation.md)
    ├── GettingStarted.md        (superseded by Setup_Guide.md)
    └── SelfHealingEngine.md     (superseded by Healing_Engine_Design.md)
```

---

## 🎯 Quick Links by Role

### For Developers
1. [Setup Guide](Setup_Guide.md) - Get the system running
2. [API Documentation](API_Documentation.md) - Integrate with the API
3. [Database Design](Database_Design.md) - Understand the schema

### For Architects
1. [Architecture](Architecture.md) - System design overview
2. [Healing Engine Design](Healing_Engine_Design.md) - Self-healing logic
3. [Database Design](Database_Design.md) - Data model

### For Operators
1. [Setup Guide](Setup_Guide.md) - Deployment instructions
2. [API Documentation](API_Documentation.md) - Health checks and monitoring
3. [Healing Engine Design](Healing_Engine_Design.md) - Understanding auto-healing behavior

---

## 📝 Contributing to Documentation

When updating documentation:

1. **Single Source of Truth:** Each topic should have ONE authoritative document
2. **Cross-Reference:** Link to related documents instead of duplicating content
3. **Keep Current:** Update docs when code changes
4. **Archive, Don't Delete:** Move outdated docs to `archive/` with deprecation notice

---

## ⚠️ Archived Documentation

The `archive/` directory contains deprecated documentation for historical reference:

- **API_Reference.md** - Replaced by more comprehensive API_Documentation.md
- **GettingStarted.md** - Replaced by detailed Setup_Guide.md
- **SelfHealingEngine.md** - Contains legacy Phase 1 logic, replaced by Healing_Engine_Design.md

**Note:** Archived files may contain outdated information. Always refer to the current documentation.

---

## 🆘 Need Help?

- **Setup Issues:** See [Setup Guide](Setup_Guide.md) troubleshooting section
- **API Questions:** Check [API Documentation](API_Documentation.md)
- **Architecture Questions:** Review [Architecture](Architecture.md) and [Healing Engine Design](Healing_Engine_Design.md)

---

**Last Updated:** 2026-05-01  
**Documentation Version:** 2.0 (Post-SLOW_QUERY Enhancement)

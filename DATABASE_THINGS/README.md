---
title: "Phase 2, Step 1 Deliverables Index"
subtitle: "AI-Assisted Self-Healing DBMS Schema Design"
date: "2026-01-30"
---

# Phase 2, Step 1: Complete Schema Design Package

## 📋 Deliverables Overview

This package contains everything you need for Phase 2, Step 1: Converting the conceptual design into a normalized MySQL schema.

### Files in This Package

| File | Purpose | Audience |
|------|---------|----------|
| **schema_phase2_step1.sql** | 8 CREATE TABLE statements with constraints | Implementation, Viva Examiner |
| **DESIGN_DOCUMENT.md** | 5,000+ words of architectural reasoning | Viva, Technical Justification |
| **ARCHITECTURE_DIAGRAMS.md** | Visual diagrams, state machines, ERD | Quick Reference, Understanding |
| **IMPLEMENTATION_CHECKLIST.md** | How to use the schema, query templates | Development Team |
| **VIVA_PREPARATION.md** | FAQ, expected questions, cheat sheet | Self-Preparation |
| **README.md** (this file) | Navigation guide | Everyone |

---

## 🚀 Quick Start

### For Running the Schema Immediately

```bash
# 1. Open MySQL CLI
mysql -u root -p

# 2. Run the SQL file
source schema_phase2_step1.sql;

# 3. Verify tables created
USE self_healing_dbms;
SHOW TABLES;
```

### For Understanding the Design

1. Start with **ARCHITECTURE_DIAGRAMS.md** (5 min read, visual)
2. Read **DESIGN_DOCUMENT.md** sections 1-3 (design philosophy, 10 min)
3. Skim **VIVA_PREPARATION.md** rapid-fire questions (5 min)
4. Reference **IMPLEMENTATION_CHECKLIST.md** for examples (as needed)

### For Viva Preparation

1. Memorize the "Viva Cheat Sheet" in **VIVA_PREPARATION.md**
2. Read all of **VIVA_PREPARATION.md** (1 hour)
3. Review **DESIGN_DOCUMENT.md** sections on viva questions (30 min)
4. Practice explaining each table in <1 minute
5. Draw the data flow diagram from **ARCHITECTURE_DIAGRAMS.md** from memory

---

## 📊 Schema Overview (60 Seconds)

**8 Tables, Strict Separation of Concerns:**

```
Detection (DBMS)
    ↓
detected_issues + ai_analysis (DBMS + AI interpretation)
    ↓
recovery_decisions (AI recommendations)
    ↓
admin_approvals (HUMAN APPROVAL - Mandatory Checkpoint)
    ↓
action_executions (Safe execution of predefined actions)
    ↓
learning_records (ML learns from outcomes; never executes)
```

**Key Guarantees:**
- ✅ AI cannot execute without approval (FK NOT NULL)
- ✅ Only predefined actions allowed (FK to whitelist)
- ✅ ML cannot bypass admin control (no write permission)
- ✅ Every action auditable (timestamps, user IDs, outcomes)

---

## 📖 File-by-File Guide

### 1. schema_phase2_step1.sql

**What:** 8 MySQL CREATE TABLE statements + optional audit_log

**Contains:**
- Full SQL with comments
- Foreign key constraints
- CHECK constraints for data integrity
- Indexes for performance
- Comprehensive inline documentation

**How to Use:**
```bash
mysql -u root -p < schema_phase2_step1.sql
```

**Key Tables:**
- `detection_events` (40 lines, well-commented)
- `detected_issues` (35 lines)
- `ai_analysis` (35 lines)
- `predefined_actions` (30 lines)
- `recovery_decisions` (30 lines)
- `admin_approvals` (25 lines)
- `action_executions` (35 lines)
- `learning_records` (40 lines)

**Total:** ~250 lines of SQL + 200 lines of comments + summary

---

### 2. DESIGN_DOCUMENT.md

**What:** Academic-style design justification

**Sections:**
1. **Executive Summary** — One-page overview
2. **Core Design Principle** — Separation of concerns diagram
3. **Table Design Rationale** — 8×5 explanation (why each table, key fields, constraints)
4. **Normalization Analysis** — 3NF justification + denormalization decisions
5. **Foreign Key Design** — Relationship graph + safety enforcement
6. **Auditability** — How schema prevents cheating, scenario-based
7. **Confidentiality & Integrity** — Constraints prevent invalid states
8. **Viva Readiness** — 8 expected questions + detailed answers
9. **Testing the Schema** — 3 test cases (happy path, safety boundaries)
10. **Performance Considerations** — Indexes, query patterns
11. **Conclusion** — Summary checklist

**Read Time:** 45-60 minutes (thorough)

**When to Reference:** During viva, when challenged on design decisions

---

### 3. ARCHITECTURE_DIAGRAMS.md

**What:** Visual representations (ASCII diagrams)

**Diagrams Included:**
1. **Data Flow Diagram** — Detection → Learning with feedback loop
2. **Entity-Relationship Diagram (ERD)** — Table structure + FK relationships
3. **State Machine** — Issue lifecycle (DETECTED → RESOLVED)
4. **Complete Example** — Real scenario traced through all tables
5. **Safety Barriers** — Risk matrix with prevention mechanisms
6. **Admin Dashboard View** — Conceptual UI (pending decisions, metrics, audit)
7. **Learning Loop Feedback** — How ML improves without executing

**Read Time:** 15-20 minutes (visual reference)

**When to Use:**
- Print and bring to viva (draw on whiteboard during exam)
- Reference when explaining design to others
- Quick mental model reminder

---

### 4. IMPLEMENTATION_CHECKLIST.md

**What:** Operational guide for using the schema

**Sections:**
1. **File Structure** — Where everything goes
2. **How to Use** — 3 steps (create DB, populate master data, simulate detection)
3. **Querying** — 6 real SQL queries (admin dashboard, audit trail, effectiveness)
4. **Schema Validation** — Queries to verify FK integrity, valid confidence scores
5. **Viva Key Points** — Table purposes, separation of concerns, safety guarantees
6. **Next Steps** — What comes in Phase 2, Step 2

**Read Time:** 20-30 minutes (with examples)

**When to Use:**
- When implementing the schema in a real MySQL database
- For example queries to understand the schema
- As a checklist before handing to dev team

---

### 5. VIVA_PREPARATION.md

**What:** Expected questions + complete answers + cheat sheet

**Sections:**
1. **Core Philosophy** — One-liner to memorize
2. **10 Expected Questions** — Detailed Q&A format
   - Q1: Why 8 tables?
   - Q2: How prevent AI execution without approval?
   - Q3: Prevent dangerous admin approvals?
   - Q4: Why DECIMAL(3,2) not FLOAT?
   - Q5: How ML learn without controlling?
   - Q6: Stale approvals?
   - Q7: JSON vs. normalization?
   - Q8: Persistent unsolved issues?
   - Q9: Undo approval?
   - Q10: Crash recovery?
3. **Rapid-Fire Questions** — 30-second answers to 10 more questions
4. **Viva Cheat Sheet** — Memorization guide (table purposes, safety barriers, workflow)

**Read Time:** 60-90 minutes (thorough preparation)

**When to Use:**
- 1 week before viva (read all)
- 1 day before viva (memorize cheat sheet)
- During viva (recall answers from memory)

---

## 🎯 Use Cases by Situation

### "I want to understand the design completely"
→ Read in this order:
1. ARCHITECTURE_DIAGRAMS.md (5 min)
2. DESIGN_DOCUMENT.md sections 1-3 (15 min)
3. DESIGN_DOCUMENT.md tables section (30 min)
4. IMPLEMENTATION_CHECKLIST.md examples (15 min)

**Total:** ~65 minutes

---

### "I need to implement this in MySQL right now"
→ Follow these steps:
1. Run `schema_phase2_step1.sql` (1 min)
2. Follow IMPLEMENTATION_CHECKLIST.md "How to Use" section (5 min)
3. Reference example queries from IMPLEMENTATION_CHECKLIST.md (as needed)

---

### "I have a viva in one week"
→ Study plan:
- **Day 1:** Read ARCHITECTURE_DIAGRAMS.md (understand visually)
- **Day 2:** Read DESIGN_DOCUMENT.md thoroughly (60 min)
- **Day 3:** Read VIVA_PREPARATION.md "Expected Questions" (90 min)
- **Day 4:** Practice answering Q1-Q10 out loud (30 min)
- **Day 5:** Memorize cheat sheet (30 min)
- **Day 6:** Review one more time (30 min)
- **Day 7:** Rest, confidence-build

**Total study time:** ~4 hours spread over a week

---

### "I have a viva in 2 hours"
→ Emergency prep:
1. Read VIVA_PREPARATION.md "Core Philosophy" (5 min)
2. Memorize "Viva Cheat Sheet" (10 min)
3. Read VIVA_PREPARATION.md top 3 expected questions (15 min)
4. Skim ARCHITECTURE_DIAGRAMS.md data flow (5 min)
5. Stay calm (25 min)

---

## ✅ Viva Success Criteria

**You will be asked ONE OF:**
1. "Why 8 tables instead of fewer?"
2. "How does AI never execute without approval?"
3. "Where is admin control built in?"
4. "How does ML learn safely?"
5. "Why normalized design matters?"

**You will be asked TO:**
1. Draw the data flow diagram
2. Explain a foreign key constraint
3. Write a query to find pending decisions
4. Justify a design choice

**You should be able to:**
- ✅ Explain each table in <1 minute
- ✅ Draw ERD from memory
- ✅ Answer any of 10 expected questions
- ✅ Defend DECIMAL(3,2) over FLOAT
- ✅ Explain why separation of concerns matters
- ✅ Point to specific rows/FKs that prevent cheating

---

## 🔗 Cross-References

### If examiner asks about...

| Topic | Where to Look |
|-------|---|
| **Table purposes** | VIVA_PREPARATION.md "Viva Cheat Sheet" |
| **Architectural reasoning** | DESIGN_DOCUMENT.md "Table Design Rationale" |
| **Visual overview** | ARCHITECTURE_DIAGRAMS.md "Data Flow Diagram" |
| **Query examples** | IMPLEMENTATION_CHECKLIST.md "Querying" |
| **Safety guarantees** | DESIGN_DOCUMENT.md "Auditability" |
| **Expected Q&A** | VIVA_PREPARATION.md "Expected Viva Questions" |
| **Data type choices** | VIVA_PREPARATION.md Q4 (DECIMAL vs FLOAT) |
| **Learning loop** | VIVA_PREPARATION.md Q5 + ARCHITECTURE_DIAGRAMS.md |

---

## 📝 Checklist Before Viva

- [ ] Read DESIGN_DOCUMENT.md completely (60 min)
- [ ] Memorize "Viva Cheat Sheet" from VIVA_PREPARATION.md (30 min)
- [ ] Practice explaining each table in 30 seconds (15 min)
- [ ] Draw ERD from memory on whiteboard (10 min)
- [ ] Read all 10 expected questions and answers (30 min)
- [ ] Prepare to code a query for "pending approvals" (10 min)
- [ ] Understand DECIMAL(3,2) vs FLOAT thoroughly (10 min)
- [ ] Print and bring ARCHITECTURE_DIAGRAMS.md to exam

**Total preparation:** ~3.5 hours

---

## 🎓 Academic Rigor Checklist

Your design demonstrates:

- ✅ **Normalization:** Proper 1NF, 3NF design with justified denormalization
- ✅ **Referential Integrity:** Foreign keys enforce valid state transitions
- ✅ **Auditability:** Every decision traced, timestamped, user-attributed
- ✅ **Safety:** Cryptographic prevention of unsafe execution (not just policy)
- ✅ **Data Types:** Appropriate choices (DECIMAL for precision, TIMESTAMP for audit)
- ✅ **Constraints:** CHECK constraints prevent invalid values
- ✅ **Separation of Concerns:** Database-enforced boundaries between stages
- ✅ **Explainability:** Clear justification for every design choice
- ✅ **Minimal:** 8 tables (not over-engineered)
- ✅ **MySQL-Appropriate:** InnoDB engine, native functions, no external hacks

---

## 📞 Troubleshooting

### "I don't understand the foreign keys"
→ Read: DESIGN_DOCUMENT.md "Foreign Key Design" + ARCHITECTURE_DIAGRAMS.md "ERD"

### "I can't explain why 8 tables"
→ Read: VIVA_PREPARATION.md Q1 + DESIGN_DOCUMENT.md "Table Design Rationale"

### "I'm nervous about the viva"
→ Remember: This design is rigorous, well-justified, and defensible. You've done good work. Confidence builds from preparation. Use VIVA_PREPARATION.md.

### "I have a different design idea"
→ Before changing: Read DESIGN_DOCUMENT.md "Why Each Table Was Necessary" (section 8). Ensure your alternative maintains separation of concerns and safety guarantees.

---

## 🎯 Final Thoughts

**This schema is:**
- **Not over-engineered** (8 tables, not 20)
- **Academically rigorous** (normalized, constraints, audit trail)
- **Safety-focused** (impossible to bypass approval, whitelist only)
- **Viva-ready** (clear reasoning for every decision)
- **Production-ready** (proper data types, indexes, InnoDB)

**Your job now:**
1. Understand it deeply (read documents)
2. Practice explaining it (especially to examiner)
3. Trust the design (it's solid)
4. Answer confidently (you have reasons for everything)

---

## 📅 Next Steps (Phase 2, Step 2)

After viva approval:
1. **Stored Procedures** — Safe execution wrappers
2. **Admin Views** — Dashboards for decision-making
3. **Backup/Recovery** — Schema backup strategy
4. **ML Integration** — How learning_records feed model training

But that's later. Focus on Phase 2, Step 1 viva now.

---

**You've got this. Good luck! 🚀**

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-30  
**Phase:** 2, Step 1  
**Status:** Ready for Viva

# 🔮 AI-Powered DBMS Self-Healing Engine

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](#)
[![Next.js](https://img.shields.io/badge/Next.js-14-black)](#)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-00a393)](#)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-blue)](#)

A state-of-the-art anomaly resolution framework bridging modern web technologies and a self-repairing SQL transaction pipeline.

---

## ⚡ The Value Proposition
Modern databases execute thousands of transactions per second. Deadlocks, slow query avalanches, and connection overloads usually require a Database Administrator to surgically kill connections or roll back logic.

**We automated this.**

This project simulates an AI-layer sitting on top of `MySQL`. When the trigger engine detects anomalies like `DEADLOCK`, the Self-Healing backend automatically analyzes the threat weight, determines a "Confidence Score," and autonomously executes structural repairs in real-time. If the AI confidence is below our strict 85% threshold, the anomaly is quarantined into a visually stunning, Glassmorphism-style React UI for manual Admin Approval.

---

## 📚 Technical Documentation Structure

All deep-dive technical explanations and setup guides have been historically preserved and elegantly organized into our `docs/` folder structure:

- 🏛️ **[System Architecture](./docs/Architecture.md)** - Review our API, Frontend, and Database stack layout.
- ⚙️ **[The Self Healing Engine](./docs/SelfHealingEngine.md)** - Deep dive into our transaction hooks and scoring mechanics.
- 🚀 **[Getting Started Guide](./docs/GettingStarted.md)** - Step-by-step tutorial to spin this project up locally.
- 🔌 **[API Reference](./docs/API_Reference.md)** - Details on our FastAPI JSON payloads.

*(Note: Prior unstructured markdown audits and legacy DB snapshots have been moved into `/archive_docs` for historical purposes).*

---

## ✨ Features
1. **Autonomous Anomaly Detection**: Built-in triggers continuously record transactional strain and blockages.
2. **Confidence-Based Routing**: Strict internal policies decide if a `DEADLOCK` can be fixed via rule-based commands natively, or if it needs routing to a human.
3. **Control Center Dashboard**: An ultra-premium React interface enabling Admins to visually see what decisions the Database is making, and inject manual overrides (`APPROVE`/`REJECT`).
4. **Learning Module**: The AI simulates incrementing its success criteria the more often an Admin approves a specific action type.
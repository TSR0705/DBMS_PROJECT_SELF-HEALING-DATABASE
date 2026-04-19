# ✨ UI/UX Design System

The **Self-Healing Dashboard** utilizes a modern, premium design language centered around **Glassmorphism** and ultra-responsive layouts.

---

## 🎨 Design Philosophy
The goal is to provide a "Mission Control" aesthetic that feels alive and interactive.

### 1. Glassmorphism
- **Implementation**: Utilizes `backdrop-blur-xl` and semi-transparent white backgrounds (`bg-white/80`).
- **Effect**: Creates a sense of depth and hierarchy, ensuring the data tables pop against the dynamic background.

### 2. Micro-Animations
- **Hover States**: Every row in our `DataTable` component features a subtle `translate-x-1` and shadow expansion on hover.
- **Pulse Indicators**: Unreviewed issues in the "Status" column utilize a subtle pulse animation (`animate-pulse`) to draw user attention without being intrusive.

---

## 🧩 Shared Components

### 📐 `DataTable`
A highly customized wrapper around standard HTML tables.
- **Gradient Headers**: Uses a linear gradient for table headers to distinguish data categories.
- **Dynamic Banners**: Integrated "Empty State" illustrations for when no anomalies are detected.

### 🚦 `StatusBadge`
A specialized indicator for issue severity and review status.
- **Emerald (Success)**: Confirmed resolutions.
- **Amber (Warning)**: Pending human reviews.
- **Rose (Critical)**: High-risk anomalies like Deadlocks.

---

## 📐 Proportional Layout
The dashboard has been optimized to move away from side-by-side grids to a **Vertical Stacking** model. This ensures that even on smaller desktop screens, technical data like "Override Reason" or "Confidence Score" remains readable without truncation.

### Responsive Breakpoints
- **Desktop**: 100% width tables with fixed-width column ratios.
- **Mobile**: Horizontal scrolling enabled for data density management.

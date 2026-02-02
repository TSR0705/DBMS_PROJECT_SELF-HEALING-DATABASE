# DBMS Dashboard Design System

## Philosophy: "Calm Density"

This design system prioritizes sustained analytical work over visual appeal. Every decision optimizes for:
- **Cognitive load reduction** during long monitoring sessions
- **Information density** without overwhelming users  
- **Consistent rhythm** that guides the eye naturally

## Layout Rhythm Rules

### Spacing Scale (8px grid)
- `space-xs` (8px): Tight spacing within components (button padding, input margins)
- `space-sm` (12px): Small gaps between related elements (form fields, list items)
- `space-md` (16px): Standard component spacing (card padding, section gaps)
- `space-lg` (24px): Section spacing (between dashboard widgets)
- `space-xl` (32px): Major section breaks (page sections)
- `space-2xl` (48px): Page-level spacing (header to content)
- `space-3xl` (64px): Major layout divisions (sidebar to main content)

### Content Width Discipline
- `max-w-content-sm` (512px): Narrow forms, navigation panels
- `max-w-content-md` (768px): Main content areas, detailed views
- `max-w-content-lg` (1024px): Wide tables, dashboard grids
- `max-w-content-xl` (1280px): Full-width layouts, monitoring displays

### Typography Hierarchy
- `text-xs` (12px): Timestamps, metadata, table annotations
- `text-sm` (14px): Table data, secondary information, form labels
- `text-base` (16px): Body text, form inputs, primary content
- `text-lg` (18px): Section headings, important labels
- `text-xl` (20px): Page titles, dashboard names
- `text-2xl` (24px): Reserved for rare emphasis

## Enforcement Strategy

All spacing must use design tokens - no arbitrary values.
All typography must follow the hierarchy - no ad-hoc sizing.
All layouts must respect content width constraints.

This system prevents visual inconsistency as the dashboard scales across teams and features.
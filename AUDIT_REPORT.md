# Audit Report: `analytics_gen`

**Role:** Senior Staff Engineer / Data Platform Lead
**Date:** 2025-12-14
**Status:** Review Complete

## Executive Summary

Your library is excellent. It follows the "Schema-First" methodology which is the gold standard in top-tier tech companies. The core value proposition—**Type Safety** and **Single Source of Truth**—is solid.

However, your `TODO.md` indicates a "Feature Factory" mindset—trying to solve every problem adjacent to analytics. You are strictly a **Code Generator** and **Runtime Router**. You are NOT a UI library, a Data Warehouse tool, or a Project Management SaaS.

## 🔴 Over-Engineering (Kill / Cancel)

These items are distractions. They dilute your library's focus and bloat maintenance.

### 1. In-App Debug Overlay (`AnalyticsDebugView`)
*   **Verdict:** **CANCEL**
*   **Reasoning:** Violation of Separation of Concerns. Your library handles *data transport*, not *data visualization*.
*   **Alternative:** Developers already use tools like **Alice**, **Chucker**, or **Proxyman**. Do not burden your package with Flutter UI dependencies, routing issues, and theme conflicts.

### 2. Visual Plan Editor (Web UI)
*   **Verdict:** **CANCEL**
*   **Reasoning:** This turns a simple CLI tool into a full-stack SaaS project. The maintenance burden of a React/Vue/Flutter Web app + Backend for saving YAMLs is enormous.
*   **Alternative:** VS Code is your UI. Use **JSON Schema** (see below) to give a "Visual Editor-like" experience with autocomplete and validation.

### 3. A/B Testing Support
*   **Verdict:** **CANCEL**
*   **Reasoning:** Analytics tracks *results*. Experimentation drives *configuration*. While related, coupling them in the *generation layer* is architecturally dangerous. A/B testing SDKs (Statsig, Firebase Remote Config) have their own complex events.
*   **Action:** Keep them decoupled. Log the "experiment_group" as a User Property/Super Property, don't bake experiment logic into the `analytics_gen` schema.

### 4. CSV/Excel to YAML Import
*   **Verdict:** **CANCEL**
*   **Reasoning:** Fragile. CSVs are unstructured mess. You will spend more time parsing broken CSVs than improving the generator.
*   **Alternative:** If analysts want to use Excel, that's their workflow problem. Teach them YAML (it's human readable!) or write a strictly defined script later. Not core core.

## 🟢 Strategic Wins (Double Down)

These features have high ROI (Return on Investment) regarding Developer Experience (DX) and reliability.

### 1. JSON Schema for IDE Autocomplete (`analytics_gen.schema.json`)
*   **Verdict:** **MUST HAVE (High Priority)**
*   **Reasoning:** This solves the "Visual Editor" problem (Item 2 above) for free. Validating YAML while typing in VS Code is a 10x developer experience improvement. It makes the library feel "Pro".
*   **Effort:** Low.

### 2. "Dead Event" Audit Command
*   **Verdict:** **KEEP (Already done)**
*   **Reasoning:** This is hygiene. In huge codebases, this is the #1 feature that prevents "Analytics Rot".

### 3. Semantic PR Reports (Diff Generator)
*   **Verdict:** **HIGH PRIORITY**
*   **Reasoning:** Data Analysts don't read code. They read diffs. If you can comment on a GitHub PR "🚨 You deleted event 'purchase_completed' which is used in 12 dashboards", you save the company money.
*   **Effort:** Medium.

### 4. Custom Linter (`analytics_gen:lint`)
*   **Verdict:** **KEEP (Medium Priority)**
*   **Reasoning:** Good for teams. Enforcing `snake_case` vs `camelCase` and description length ensures the data catalog (DataHub/Amundsen) isn't garbage.

## 🟡 Contextual / Extension (Move to Separate Packages)

### 1. dbt Schema / AsyncAPI
*   **Verdict:** **EXTRACT**
*   **Reasoning:** This is valuable for the *Data Engineering* team, not the Mobile team. If you put this in the core `analytics_gen`, you bloat the CLI.
*   **Action:** Plugin architecture. `analytics_gen_dbt` or `analytics_gen_asyncapi`. Don't bundle it by default.

## Recommended Action Plan

1.  **Purge TODO:** Remove the UI and Editor tasks.
2.  **Focus on v1.1:**
    *   Shipped: Audit (Done)
    *   Next: JSON Schema (Quick win)
    *   Next: Semantic PR Diffs (High Value)

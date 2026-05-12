# Spec-Driven Development Framework for Claude Code

**Combining spec-driven development with self-contained HTML visualization for reliable AI-assisted programming.**

---

## What Is This?

The Spec-Driven Development (SDD) Framework is a Claude Code framework that enforces a structured, phase-gated workflow for building software with AI assistance. It combines rigorous specification practices with self-contained HTML visualization, making AI-generated plans, designs, and code reviews transparent and auditable.

Core ideas:

- **Phase-gated workflow** -- every stage requires human approval before proceeding to the next
- **Self-contained HTML documents** -- all human-facing artifacts are single HTML files with inline CSS/JS and zero external dependencies; they work offline on `file://`
- **Interactive feedback** -- approve, reject, or fine-tune directly in the browser; feedback is persisted to JSON
- **Multi-agent parallel development** -- each agent operates on an isolated feature directory with its own feedback files
- **Git-tracked audit trail** -- specs, feedback, and decisions are all committed to version control
- **Bilingual** -- supports both Chinese and English

Inspired by GitHub's spec-kit, Fission-AI's OpenSpec, and Thariq's 20 HTML effectiveness demos.

---

## Quick Start

### Remote Install (one command)

From inside your project directory:

```bash
bash <(curl -sL https://raw.githubusercontent.com/maken2012/coding-guide/main/install.sh)
```

### Local Install

```bash
git clone https://github.com/maken2012/coding-guide.git
cd your-project
./coding-guide/install.sh
```

### Language Option

The installer auto-detects your system language. You can override it:

```bash
# Force English
bash install.sh --lang en

# Force Chinese (default)
bash install.sh --lang zh
```

---

## Main Workflow (6 Steps)

```
/spec-init --> /spec-detail --> /spec-design --> /spec-plan --> /spec-implement --> /spec-review
Architecture    Requirements     Design        Plan+Tasks    Dev+Testing        Review+Deploy
```

| Command | Purpose | Output |
|---|---|---|
| `/spec-init` | Architecture selection, high-level requirements | `spec.html` |
| `/spec-detail` | Detailed requirements, interactions, business rules | `detail.html` |
| `/spec-design` | Flow, DB schema, API contracts, UI design | `design/*.html` |
| `/spec-plan` | Phased implementation plan + task breakdown | `plan.html`, `tasks.html` |
| `/spec-implement` | Code, unit tests, integration tests | source files, `test-report.html` |
| `/spec-review` | Code review, deploy plan | `review.html`, `deploy-plan.html` |

Each command reads the feedback from the previous phase. Only when `verdict: "approved"` is present does the next command proceed.

**LTS 1.1 shortcuts:** Use `/spec-run <feature>` to auto-advance through all 6 phases, or `/spec-dispatch` to analyze features and get parallel agent commands. See [Multi-Agent Parallel (LTS 1.1)](#multi-agent-parallel-lts-11) for details.

---

## Auxiliary Commands (Standalone)

These commands work independently of the main workflow:

```
/spec-explore   --> Approach / architecture comparison
/spec-research  --> Technical deep-dive and research
/spec-report    --> Status report or incident post-mortem
/spec-present   --> Presentation slide deck
```

---

## How It Works

1. You invoke a slash command (e.g., `/spec-init`).
2. Claude generates one or more self-contained HTML documents in `.specify/specs/<feature>/`.
3. You open the HTML file in your browser, review the content, and use the interactive feedback bar to approve or reject with notes.
4. Feedback is saved to a `.feedback.json` file alongside the HTML document.
5. The next slash command reads the feedback file. Only an `"approved"` verdict allows progression to the next phase.
6. A dashboard (`dashboard.html`) provides an overview of all features and their current phase.

---

## Project Structure (After Install)

```
.specify/
  constitution.md              # Project charter and invariants
  specs/                       # Runtime spec files
    <feature>/
      spec.html                # + spec.feedback.json
      detail.html              # + detail.feedback.json
      design/
        flow-design.html       # + .feedback.json
        db-design.html         # + .feedback.json
        api-design.html        # + .feedback.json
        ui-design.html         # + .feedback.json
      plan.html                # + plan.feedback.json
      tasks.html               # + tasks.feedback.json
      review.html              # + review.feedback.json
      deploy-plan.html         # + deploy-plan.feedback.json
    dashboard.html             # Global overview
    dashboard-state.json       # Dashboard state
  templates/                   # Document templates
    dashboard.html
    spec-template.html
    detail-template.html
    design-template.html
    plan-template.html
    tasks-template.html
    review-template.html
    exploration-template.html
    research-template.html
    report-template.html
    presentation-template.html
    ...                        # 15 templates total
    components/                # Reusable HTML components
      exploration-approaches.html
      flowchart-diagram.html
      code-understanding.html
      ...                      # 20 components total

.claude/
  commands/                    # 10 slash commands
    spec-init.md
    spec-detail.md
    spec-design.md
    spec-plan.md
    spec-implement.md
    spec-review.md
    spec-explore.md
    spec-research.md
    spec-report.md
    spec-present.md
  hooks/                       # Validation hooks
```

---

## Key Features

- **Phase-gated workflow** -- no skipping stages; every document must be approved before the next phase begins
- **Self-contained HTML output** -- works offline, on `file://`, with zero external dependencies
- **Interactive feedback** -- approve, reject, or fine-tune directly in the browser
- **Multi-agent parallel development** -- isolated feedback per feature directory; no cross-contamination
- **Git-tracked audit trail** -- all specs, decisions, and feedback are plain files in version control
- **20 HTML components** -- flowcharts, ER diagrams, code review annotations, slide decks, triage boards, and more
- **Bilingual** -- Chinese and English supported out of the box
- **Multi-agent parallel (LTS 1.1)** -- run `/spec-run` to auto-advance through all phases, or `/spec-dispatch` to launch parallel agents for multiple features

---

## HTML Components (20)

| Component | Purpose |
|---|---|
| `exploration-approaches` | Side-by-side comparison of architectural or design approaches |
| `exploration-visual-designs` | Visual direction comparison for front-end projects |
| `implementation-plan` | Phased plan with dependency graph |
| `annotated-pr-review` | Inline-annotated code review |
| `pr-writeup` | Change summary and PR description |
| `code-understanding` | Code walkthrough with call graphs, ER diagrams |
| `design-system` | Design tokens and style guide |
| `component-variants` | Component matrix with property combinations |
| `prototype-animation` | Motion and animation prototypes |
| `prototype-interaction` | Interactive click-through prototypes |
| `svg-illustrations` | Scalable diagrams and illustrations |
| `flowchart-diagram` | Flowcharts, sequence diagrams, state machines |
| `slide-deck` | Presentation slides with navigation |
| `feature-explainer` | Step-by-step feature walkthrough |
| `concept-explainer` | Technical concept illustration |
| `status-report` | Progress dashboard with metrics |
| `incident-report` | Post-mortem timeline and analysis |
| `triage-board` | Prioritized task board with drag-and-drop |
| `feature-flags-editor` | Feature flag configuration editor |
| `prompt-tuner` | Prompt parameter tuning interface |

---

## Feedback Mechanism

Every generated HTML document includes an interactive review bar at the bottom. From there you can:

- **Approve** the document, allowing the next phase to proceed
- **Reject** the document with feedback notes, requiring regeneration
- **Make selections** on multi-option decisions embedded in the document
- **Add freeform notes** for fine-tuning instructions

Feedback is saved to a companion `.feedback.json` file. The saving mechanism uses the File System Access API (Chrome/Edge) with a clipboard fallback for other browsers.

Before each phase, Claude reads the relevant `.feedback.json` and only proceeds when `verdict` is `"approved"`.

### Feedback JSON Structure

```json
{
  "artifact": "spec.html",
  "feature": "my-feature",
  "phase": "spec",
  "status": "pending_review",
  "decisions": [
    {
      "id": "arch-choice",
      "type": "single-select",
      "options": ["monolith", "microservices"],
      "selected": null,
      "note": ""
    }
  ],
  "review": {
    "verdict": null,
    "feedback": "",
    "timestamp": null
  },
  "created_at": "2026-05-12T10:00:00Z",
  "updated_at": "2026-05-12T10:00:00Z"
}
```

---

## Multi-Agent Parallel (LTS 1.1)

Run multiple Claude Code sessions simultaneously, each managing one feature's full lifecycle.

### /spec-run — Automated Lifecycle

One command manages the entire 6-phase pipeline, auto-advancing after each approval:

```bash
/spec-run "User Authentication Module"
```

The agent generates spec.html → waits for your approval → auto-runs spec-detail → waits → ... through spec-review. You only interact via the browser review buttons.

### /spec-dispatch — Parallel Agent Analyzer

Scan all features and get parallel execution recommendations:

```bash
/spec-dispatch
```

Output shows which features are at which phase, which are locked by active agents, and exact terminal commands to start new agents.

### Multi-Agent Workflow

```
Terminal 1: /spec-run "User Authentication"    # Agent A manages feature 001
Terminal 2: /spec-run "Data Export"            # Agent B manages feature 002
Terminal 3: /spec-run "Payment Integration"    # Agent C manages feature 003
```

Each agent works independently on its own feature directory. Feature locks prevent conflicts.

### New Architecture

- `.feature-state.json` — Per-feature pipeline state (replaces centralized dashboard-state.json)
- `.agent-lock` — Atomic feature lock with 60-minute expiry
- `registry.jsonl` — Append-only event log for cross-agent observability
- Reactive polling — Agents detect approval via .feedback.json and auto-advance

---

## Requirements

- **Claude Code CLI** (or Claude desktop app / VS Code extension)
- **Git**
- **A modern browser** -- Chrome or Edge recommended for full File System Access API support; Firefox and Safari work with clipboard fallback

---

## License

MIT

---

## Links

- **GitHub:** <https://github.com/maken2012/coding-guide>
- **Chinese documentation:** [README.zh-CN.md](README.zh-CN.md)

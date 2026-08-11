
# AI-Assisted Architecture & Design Framework

## Purpose

This framework is intended to guide engineering teams through a structured software design process before implementation begins. The goal is to improve engineering clarity, reduce architectural mistakes, improve AI-assisted development outcomes, and minimize unnecessary token usage during coding.

This framework is intentionally platform agnostic.

AI tools evolve rapidly. The goal of this framework is to create durable engineering artifacts and structured context that can be consumed by multiple AI-assisted development tools.

Claude Skills, Cursor Rules, Copilot Instructions, OpenAI project prompts, and similar systems should be treated as adapters over the same underlying engineering context.

---

# Core Principle

The goal is not maximum context.

The goal is minimum sufficient context.

The framework exists to produce:
- durable engineering decisions,
- structured project artifacts,
- compressed architectural truth,
- and implementation-ready context.

The framework itself should not be pasted wholesale into AI coding tools.

---

# AI Context Management Rules

## Important Rule

Use the framework to generate context artifacts, not to become the context artifact.

### During Coding
Provide AI systems only:
- the current task,
- relevant architecture sections,
- relevant files,
- applicable constraints,
- and required contracts/interfaces.

Avoid:
- entire meeting histories,
- brainstorming notes,
- obsolete decisions,
- duplicated explanations,
- and large unrelated documents.

## Context Budget Guidance

AI_CONTEXT.md should remain concise enough to be quickly reviewed and efficiently consumed during coding sessions.

Prefer:
- references,
- linked files,
- summarized decisions,
- and compressed architectural truth

over duplicating full design discussions.

---

# Project Scale Guidance

## Small Project Shortcut

Small internal tools and prototypes should still follow the same phases, but at reduced depth.

Do not skip architectural thinking.

Instead:
- shorten documentation,
- compress decisions,
- simplify contracts,
- and reduce operational complexity appropriately.

The goal is proportional rigor, not bureaucracy.

---

# Phase 1 — Challenge the Brief

## Objective

Validate that the team understands the actual problem before designing solutions.

## Questions
- What problem are we solving?
- Who experiences the problem?
- What happens if we do nothing?
- What is the smallest useful version?
- What assumptions are unverified?
- What would make this fail organizationally?
- What are the real business constraints?
- If we could only ship one thing, what would it be?

## Deliverables
- PROJECT_BRIEF.md
- validated problem statement
- success criteria
- constraints list

## Exit Criteria
- Problem statement agreed upon
- Success criteria defined
- MVP identified
- Major assumptions documented

---

# Phase 2 — Operational Requirements

## Objective

Define non-functional requirements before architecture selection.

## Questions
- Required uptime?
- Expected latency?
- Expected scale?
- Concurrent users?
- Burst behavior?
- Recovery expectations?
- RTO/RPO requirements?
- Compliance obligations?
- Cost ceilings?
- Accessibility requirements?
- Geographic/data residency requirements?

## Deliverables
- operational requirements section
- SLA/SLO expectations
- cost expectations

## Exit Criteria
- Non-functional requirements documented
- Scale assumptions validated
- Recovery expectations defined

---

# Phase 3 — Domain Modeling

## Objective

Define the business domain before designing infrastructure or data schemas.

## Questions
- What are the core entities?
- What are the bounded contexts?
- Who owns each domain?
- What are the business invariants?
- What workflows exist?
- What are the lifecycle transitions?
- What events occur?
- What terminology must remain consistent?

## Deliverables
- domain model
- entity glossary
- workflow diagrams
- lifecycle/state definitions

## Exit Criteria
- Core entities identified
- Ownership boundaries documented
- Workflow states defined
- Shared terminology established

---

# Phase 4 — User & System Interfaces

## Objective

Define how humans and systems interact with the solution.

## Questions
- Who are the users?
- What interfaces are required?
- What APIs exist?
- What external systems integrate?
- What events are exchanged?
- What schemas/contracts are required?
- What approval workflows exist?

## Deliverables
- interface inventory
- API contracts
- event schemas
- user interaction flows

## Exit Criteria
- Interfaces documented
- Contracts defined
- Major integration boundaries established

---

# Phase 5 — Compute & Execution Model

## Objective

Determine how the system executes work.

## Questions
- Event-driven or request/response?
- Synchronous or asynchronous?
- Long-lived or ephemeral compute?
- Queue-based?
- Batch processing?
- Polling required?
- Stateful workloads?
- AI/agent orchestration needed?
- Human escalation paths?

## Deliverables
- execution model
- workload classification
- orchestration approach

## Exit Criteria
- Execution patterns selected
- Workload types identified
- Orchestration strategy documented

---

# Phase 6 — Data Architecture

## Objective

Design storage around access patterns and lifecycle requirements.

## Principles
Access patterns drive schema.
Schema never drives access patterns.

## Questions
- What data exists?
- Who owns it?
- What are the read/write patterns?
- What are retention requirements?
- What consistency guarantees are needed?
- What archival strategy exists?
- What relationships matter?
- What reporting/query patterns exist?

## Deliverables
- data model
- storage decisions
- lifecycle definitions
- access pattern inventory

## Exit Criteria
- Access patterns documented
- Data ownership identified
- Retention strategy defined
- Storage choices justified

---

# Phase 7 — Security & Threat Modeling

## Objective

Design security using adversarial thinking, not only operational controls.

## Questions
- What are the trust boundaries?
- What data classifications exist?
- Who are the threat actors?
- What abuse cases exist?
- What insider risks exist?
- What privilege escalation paths exist?
- What AI/prompt injection risks exist?
- What supply chain risks exist?
- How are secrets managed?
- How is tenant isolation enforced?

## Deliverables
- threat model
- trust boundary diagrams
- data classification inventory
- security controls

## Exit Criteria
- Threat actors identified
- Trust boundaries documented
- High-risk attack paths mitigated

---

# Phase 8 — Observability & Operations

## Objective

Design for debugging, operations, and incident response.

## Questions
- What logs are required?
- What metrics matter?
- What traces are needed?
- What alerts matter?
- Who receives incidents?
- What dashboards are needed?
- What operational workflows exist?
- What rollback mechanisms exist?

## Deliverables
- observability plan
- dashboards
- alerting strategy
- incident workflow

## Exit Criteria
- Critical telemetry identified
- Alerting expectations defined
- Rollback procedures documented

---

# Phase 9 — Testing & Validation

## Objective

Validate correctness before and after deployment.

## Questions
- What unit tests are required?
- What integration tests exist?
- What contract tests exist?
- What end-to-end tests exist?
- What synthetic monitoring exists?
- What AI evals are required?
- What prompt regression testing exists?
- What deterministic validation exists?

## Deliverables
- testing strategy
- evaluation datasets
- regression plan
- validation workflows

## Exit Criteria
- Test strategy documented
- Critical paths covered
- Regression approach defined

---

# Phase 10 — Infrastructure as Code & Deployment

## Objective

Ensure reproducible deployment and operational consistency.

## Questions
- How is infrastructure provisioned?
- What environments exist?
- What secrets management exists?
- What deployment strategy exists?
- What rollback strategy exists?
- What disaster recovery process exists?

## Deliverables
- IaC repository
- deployment workflows
- environment definitions

## Exit Criteria
- Infrastructure reproducible
- Deployment workflow defined
- Rollback capability validated

---

# Phase 11 — Governance & Decision Management

## Objective

Keep architecture current and maintainable over time.

## Questions
- How are decisions recorded?
- What requires ADRs?
- How are deprecated systems retired?
- What triggers architecture review?
- How is technical debt tracked?
- Who owns ongoing governance?

## Deliverables
- ADR repository
- governance process
- review cadence

## Exit Criteria
- ADR process established
- Review ownership assigned
- Technical debt process defined

---

# Architecture Readiness Review

Before implementation begins, evaluate the project:

| Area | Status |
|---|---|
| Problem Clarity | Green / Yellow / Red |
| Operational Requirements | Green / Yellow / Red |
| Domain Model | Green / Yellow / Red |
| Interfaces & Contracts | Green / Yellow / Red |
| Compute Model | Green / Yellow / Red |
| Data Architecture | Green / Yellow / Red |
| Security & Threat Modeling | Green / Yellow / Red |
| Observability | Green / Yellow / Red |
| Testing & Validation | Green / Yellow / Red |
| AI Context Readiness | Green / Yellow / Red |

If any critical area is Red, implementation should pause until resolved.

---

# Artifact Ownership Guidance

| Artifact | Suggested Owner |
|---|---|
| PROJECT_BRIEF.md | Product / Engineering Lead |
| ARCHITECTURE.md | Tech Lead |
| API_CONTRACTS.md | Backend Lead |
| DATA_MODEL.md | Tech Lead / Data Lead |
| TESTING_STRATEGY.md | Engineering Lead / QA |
| AI_CONTEXT.md | Tech Lead |
| ADRs | Decision Owner |

---

# Recommended Project Artifacts

## PROJECT_BRIEF.md
Contains:
- problem statement
- business goals
- success criteria
- constraints
- MVP scope

## ARCHITECTURE.md
Contains:
- architectural truth
- execution model
- domain boundaries
- data decisions
- deployment model
- operational expectations

## API_CONTRACTS.md
Contains:
- OpenAPI definitions
- schemas
- event contracts
- integration contracts

## DATA_MODEL.md
Contains:
- entities
- relationships
- lifecycle rules
- retention rules

## TESTING_STRATEGY.md
Contains:
- unit strategy
- integration strategy
- contract testing
- AI eval methodology

## AI_CONTEXT.md
Contains:
- compressed implementation guidance
- architectural constraints
- coding expectations
- links to supporting artifacts

## ADR/
Contains:
- Architecture Decision Records
- decision rationale
- alternatives considered
- consequences

---

# Example Mini Project

## Example: Internal Cost Reporting Tool

### Problem
Finance analysts manually gather cloud cost reports from multiple systems.

### MVP
Single dashboard aggregating AWS cost data daily.

### Operational Requirements
- Daily refresh acceptable
- Internal users only
- 99% uptime sufficient

### Domain Model
Entities:
- Account
- CostReport
- ServiceCategory

### Interface Contracts
- REST API for dashboard
- CSV export contract

### Compute Model
- Scheduled serverless jobs
- Daily batch aggregation

### Data Architecture
- DynamoDB for account summaries
- S3 for archived reports

### Security
- SSO required
- Read-only finance access

### Testing
- Contract tests for CSV schema
- Integration tests for aggregation pipeline

### AI Context
Provide only:
- aggregation logic,
- schema definitions,
- and API contract during coding.

---

# Glossary

## ADR
Architecture Decision Record.

## Bounded Context
A domain boundary where terminology and rules remain internally consistent.

## Contract Testing
Validation that systems honor agreed interfaces.

## Evals
Evaluation datasets and validation workflows used to measure AI behavior.

## Prompt Injection
Attempts to manipulate AI systems through malicious or untrusted inputs.

## RTO
Recovery Time Objective.

## RPO
Recovery Point Objective.

---

# Final Principle

Most long-term engineering failures originate in unclear architecture and undefined constraints rather than typing code.

Good architecture reduces:
- implementation waste,
- operational failures,
- debugging time,
- onboarding friction,
- and AI token consumption.

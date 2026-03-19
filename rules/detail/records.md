# Design Records and Work Log (Sections 23–24 Detail)

> Reference when writing design records or AI-Logs/{app_name}.log.

## Recommended Documents

| File | Content | When to create |
|---|---|---|
| `CONTEXT.md` | Current design state, constraints, unresolved issues | Always check before starting work |
| `DESIGN.md` | Overall design and architecture policy | Project start |
| `DECISIONS.md` | Design decision history and rationale | On every major decision |
| `KNOWN_ISSUES.md` | Known issues and temporary workarounds | When issues are found |
| `ROADMAP.md` | Future implementation plans | As needed |
| `CHANGELOG.md` | Feature addition / change history (for users and AI) | On every [Fxx] addition or spec change |

## CHANGELOG Rules (23-3)

Update when a task involving a `[Fxx]` addition or feature spec change is complete.

- Write at a level where "a human or another AI can understand what was added or changed"
- Not technical commit log style — user-facing summary style

## AI-Logs/{app_name}.log Format (24-2)

Record at each checkpoint — not after all work is done:

```
## [Datetime] Work Log

### Work Start
- Assignee   : AI / Human
- Target file:
- Content    :

### Completion Checkpoints
- [F01] Done / Not done
- [F02] Done / Not done

### Errors / Issues
- What happened:
- What was tried:
- Why this approach was chosen:
  - Alternatives considered:
  - Reason for rejection:
- Temporary workaround:

### Handoff for Next Session
- What to do next:
- Incomplete items:
- Notes:
```

## When to Write AI-Logs/{app_name}.log

- When starting work (what to do, target files)
- When each Function Index unit is complete
- When an error occurs
- Before session end or quota exhaustion

Real-time recording ensures state can be restored regardless of when work stops.

## Recording Principles

- Record failed attempts and rejected approaches
- Write at a level another AI or human can understand
- Manage `AI-Logs/{app_name}.log` in Git

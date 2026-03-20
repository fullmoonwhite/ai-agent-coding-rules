# Guardrails — Safety Standards (Section 14 Detail)

> Reference when a safety judgment is unclear.

## Operations Requiring Human Approval

Never perform the following without prior human confirmation:

- File deletion or large-scale rewrite
- Destructive database schema changes
- Modifying credentials or environment variables
- Destructive requests to external APIs
- Adding new external libraries (→ dependencies.md)
- Resolving merge conflicts by guessing

## Error Recovery

- Guessing-based fixes (arbitrary code changes) are prohibited
- Always analyze logs or stack traces to identify root cause before proposing a fix
- One function index unit ([F01] etc.) at a time — do not implement multiple features at once

## Retreat Rule (Section 24-4)

Stop immediately when either applies:

- Same error unresolved after 3 consecutive attempts
- Context confusion (hallucination) noticed

Procedure:
```
1. Write situation, what was tried, and cause of deadlock in ai_log.md
2. Request session restart and human intervention
3. Do not make guessing-based fixes or stopgap changes
```

Retreating is not failure — it is the correct decision to protect code and context.

## Context Summarization in Long Sessions (Section 24-5)

When context window exhaustion approaches:

- Retain only context relevant to the current task in summarized form
- Intentionally discard old execution logs and exploration memory (sliding window)
- Write important decisions to `ai_log.md` or `DECISIONS.md`

## Zero Trust — External Data (Section 20-5)

- Treat all data from networks, user input, or external files as untrusted
- Always sanitize or escape before passing to logs, DB, or LLM prompts
- Passing external input to `eval()` or system commands is strictly prohibited

# Architecture Principles (Section 2 Detail)

> Reference when an architecture decision is unclear.

## Module Design (2-1)

- One module, one responsibility — modules operate independently
- Core is minimal; delegate functionality to modules
- Every module must have a header comment (→ header_spec.md)
- Regenerate index.yaml after adding a module

## Inter-Module Interface (2-2)

- Use JSON-compatible format for data exchange between modules
- Schema definitions, event formats, and inter-module specs are frozen areas (→ Section 11)
- Project-specific formats are defined in `RULES.md`

## UI and Logic Separation (2-3)

- Clearly separate UI code from business logic
- Logic layer must not depend on the UI
- Changing the UI framework must not affect logic

## Secret Management (2-4)

- Never store passwords, API keys, or tokens in plain text
- Use a secret store (specify implementation in `RULES.md`)
- Never embed secrets in code, config files, or logs

## External Module Security Clearance (2-5)

- Apply security clearance to all external (third-party) libraries
- Maintain at minimum two levels: trusted / untrusted
- Define levels and approval process in `RULES.md`

## Frozen Areas (Section 11)

Freeze applies only when:

- Version >= v1.0
- Or explicitly marked as stable

The following are subject to freezing:

- Core API
- Schema definitions
- Event formats
- Inter-module interface specifications
- Security clearance definitions
- `index.yaml` (auto-generated; manual editing prohibited)

If modification is necessary, create a plan document and get it reviewed.

## File Size Management (21-4)

If a file exceeds 500 lines, or is predicted to exceed it:

- Appending without refactoring is prohibited
- Create a split plan and propose it to a human before implementing

## Prompt Caching Optimization (22-4)

For systems that call AI agents:

- Place stable info (PROJECT_CONFIG.md, index.yaml, shared rules) at the **beginning** of the prompt
- Place per-task instructions at the **end**
- This maximizes KV cache hit rates

## AST / Skeleton Exploration (22-5) `[Large recommended]`

When exploring an unknown large codebase:

- Do not load full text from the start
- Use AST parsers or Tree-sitter to extract function signatures and header comments as a skeleton
- Fetch full text only for specific [Fxx] blocks where needed
- When tools are unavailable, use index.yaml and Function Index as alternative

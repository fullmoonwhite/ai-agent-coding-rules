# Dependency Management (Section 18 Detail)

> Reference when adding an external library.

## Principle

Adding new external libraries requires **human approval** (Guardrails Section 14-3).

Before adding, create a plan document containing:

- Purpose and why the library is needed
- Alternatives considered
- License
- Version to pin

## Lightweight Mode

For limited AI capability environments (Level 2 or 3):

- This mode overrides full requirement

- Require only:
  - Purpose
  - Version
  - License type

## License Check

| License | Commercial Use | Notes |
|---|---|---|
| MIT / Apache 2.0 / BSD | Generally OK | Maintain copyright notice |
| LGPL | Conditional | Verify linking method |
| GPL | Caution required | Source disclosure may be required |
| Commercial license | Verify | Separate contract may be needed |

## Version Pinning

- Always pin exact versions: `requests==2.31.0`
- Range specifiers (`>=`) are prohibited by default
- If used, state the reason in `RULES.md`

## After Adding

1. Add to module header `Libraries` field
2. Update `requirements.txt` or equivalent
3. Record in `DECISIONS.md` with reason and license result
4. Re-run `generate_index.bat`

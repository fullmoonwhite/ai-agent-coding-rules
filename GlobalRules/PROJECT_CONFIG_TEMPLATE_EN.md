# PROJECT_CONFIG_TEMPLATE

> Copy this file and rename it to `PROJECT_CONFIG.md`.
> Fill in each item according to your project.

---

## Project Information

| Item | Value |
|---|---|
| Project Name | |
| Scale | 🟢 Small / 🟡 Medium / 🔴 Large |
| Primary Language | |
| Created | |

---

## Environment Settings

| Item | Value |
|---|---|
| Development OS | Windows / macOS / Linux |
| Target OS | Windows / macOS / Linux / Cross-platform |
| Config File Format | TOML / JSON / YAML / ENV |
| Developer | |
| Character Encoding | UTF-8 (should not be changed in principle) |
| Timezone | UTC (convert to local for display) |
| Project Root | |
| Secret Management | (specify secret store) |
| Skills Folder | C:/Users/[username]/ai_rules/skills/ (default) |

---

## Rule Adoption / Exclusion Table

> Default: all rules adopted. List only exclusions.

| Section | Rule | Status | Exclusion Reason |
|---|---|---|---|
| 1 | Basic Policy | ✅ | |
| 2-1 | Module Design | ✅ | |
| 2-2 | Module Interface | ✅ / ⬜ Excluded | |
| 2-3 | UI and Logic Separation | ✅ / ⬜ Excluded | |
| 2-4 | Secret Management | ✅ | |
| 2-5 | External Module Security Clearance | ✅ / ⬜ Excluded | |
| 3 | New Code Creation Rules | ✅ | |
| 4 | Code Update Rules | ✅ | |
| 5 | Search Comment Spec | ✅ | |
| 6 | Index Auto-Generation | ✅ / ⬜ Excluded | |
| 7 | Function Index Rules | ✅ | |
| 8 | Log Output Rules | ✅ | |
| 9 | Comment Update Rules | ✅ | |
| 10 | Agent Response Rules | ✅ | |
| 11 | Frozen Areas | ✅ / ⬜ Excluded | |
| 12 | Relationship with Project Rules | ✅ | |
| 12-1 | Language Rule Files | ✅ | |
| 13 | Purpose of Ruleset | ✅ | |
| 14 | Guardrails | ✅ | |
| 15 | Coding Standards | ✅ | |
| 15-3 | Test Obligation / TDD | ✅ / ⬜ Excluded | |
| 16 | Git Rules | ✅ / ⬜ Excluded | |
| 16-4 | Conflict Resolution | ✅ / ⬜ Excluded | |
| 17 | Operational Notes | ✅ / ⬜ Excluded | |
| 18 | Dependency Management | ✅ | |
| 19 | Coding Style Consistency | ✅ | |
| 20 | Quality Policy | ✅ | |
| 20-5 | Zero Trust Principle | ✅ | |
| 21 | File Naming Rules | ✅ | |
| 21-4 | File Size Management | ✅ / ⬜ Excluded | |
| 22 | AI Exploration Rules | ✅ | |
| 22-4 | Prompt Caching Optimization | ✅ | |
| 22-5 | AST / Skeleton Exploration | ✅ / ⬜ Excluded | |
| 23 | Design Record Rules | ✅ / ⬜ Excluded | |
| 23-3 | CHANGELOG Maintenance | ✅ / ⬜ Excluded | |
| 24 | AI Work Log Rules | ✅ / ⬜ Excluded | |
| 24-5 | Context Summarization | ✅ / ⬜ Excluded | |
| 25 | Environment-Independent Rules | ✅ | |
| 26 | Agent Skills Rules | ✅ / ⬜ Excluded | |
| 26-7 | English for Skills / Split Files | ✅ / ⬜ Excluded | |

---

## Project-Specific Additions

> Fill in only when overriding GLOBAL_RULES or language rules.

### Frozen Areas

(List files and directories that agents must not modify)

### Permission Types

(List permission names used in the Permissions field)

### Security Clearance Levels

(Define clearance levels for external modules)

### Log Format

(Specify if different from GLOBAL_RULES Section 8)

Default configuration (each folder: latest file at root, past files under `History/`):
- `logs/`     : Minimal log — AI agent primary read, WARNING and above, overwrite per run
- `runtime/`  : Detail log — AI agent when needed, INFO and above, overwrite per run
- `All-Logs/` : Full action log — human post-mortem only, DEBUG and above, overwrite per run

### Test Framework / Execution

(Specify framework and run command)

---

## Notes for Agents

(Project-specific cautions and instructions)

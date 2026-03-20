# AI Development Global Rules

> This file defines rules common to all projects.
> Project-specific rules are written in `RULES.md`, which inherits from this file.

---

## 0. How to Use This File

### Basic Policy

**All rules are recommended for adoption.** However, if certain items are impractical given the project's scale or nature, they may be omitted by explicitly stating the exclusion in `PROJECT_CONFIG.md`.

Even when excluding a rule, marking it as "not applied" allows agents to recognize the omission as intentional.

### Project Scale Definitions

| Scale | Description |
|---|---|
| 🟢 Small | One-off scripts, a few files, throwaway tools |
| 🟡 Medium | Multiple features, spans sessions, ~10–30 files |
| 🔴 Large | Many files, multiple modules, released or ongoing development |

### Rule Scale Tags

Each section is tagged as follows. Tags are **recommendations** and can be overridden in `PROJECT_CONFIG.md`.

| Tag | Meaning |
|---|---|
| `[All]` | Recommended regardless of scale |
| `[Medium+]` | May be omitted for small-scale projects |
| `[Large recommended]` | Use judgment for medium-scale and below |

### Agent Startup Procedure

Run the following at project start:

```
1. Read I:\.agents\MainSkills\SKILL.md          (start SkillManager)
2. Read I:\.agents\MainSkills\skills\skill_index.yaml
3. Run generate_index.bat to regenerate index.yaml
   → If execution is not possible: use existing index.yaml as-is
4. Load index.yaml into context
5. Check PROJECT_CONFIG.md (create it if it doesn't exist)
6. Proceed with development according to adopted rules
```

A template for `PROJECT_CONFIG.md` is provided as `PROJECT_CONFIG_TEMPLATE.md`.

---

## 1. Basic Policy `[All]`

- This ruleset is the **shared rules for both human developers and AI agents**
- Humans and AI use the **same rules, same structure, and same exploration methods**
- All code must satisfy the following principle:

```
Human Readable  ← Structures that humans cannot understand are prohibited
AND
AI Searchable   ← Structures that AI cannot search are prohibited
```

- All code should aim to be **Self-Describing Code**
- Search comments and Function Indexes are mandatory to enable efficient AI exploration

---

## 2. Architecture Principles

### 2-1. Module Design `[All]`

- Applications are structured in modules
- Each module has a single responsibility and can operate independently
- Every module must include its role, permissions, and dependencies at the top (→ Section 5)
- Regenerate the index after adding a module (→ Section 6)
- Keep the core minimal and delegate functionality to modules

### 2-2. Inter-Module Interface `[Medium+]`

- Use **JSON-compatible format** for data exchange between modules
- Define project-specific communication formats in `RULES.md`
- Schema definitions, event formats, and inter-module interface specs are **frozen areas** (→ Section 11)

### 2-3. UI and Logic Separation `[Medium+]`

- Clearly separate UI code from business logic
- The logic layer must not depend on the UI
- Maintain a structure where changes to the UI framework do not affect logic

### 2-4. Secret Management `[All]`

- Do **not store** passwords, API keys, tokens, or other secrets in plain text
- Use a secret store (specify the implementation in `RULES.md`)
- Embedding secrets in code, config files, or logs is prohibited

### 2-5. External Module Security Clearance `[Large recommended]`

- Apply security clearance to external (third-party) modules and libraries
- Define clearance levels and approval process in `RULES.md`
- Granting permissions to uncleaned external modules is prohibited
- At minimum, maintain two levels: **trusted / untrusted**

---

## 3. New Code Creation Rules `[All]`

When creating a new file or module:

- Include a **search comment (code index)** at the top of the file
- Write the search comment before any code
- Follow the format specified in Section 5

---

## 4. Code Update Rules `[All]`

When updating code, perform the following in order:

1. Review the search comment at the top of the file
2. Check the Function Index for the target feature
3. Verify the change does not affect other features or modules
4. After updating, **re-check the changed area and header**
5. Update the search comment and index as needed

### 4-1. Post-AI-Change Review Rules

After completing a change, always verify:

- Review the **entire file**, not just the changed function
- Check affected imports, types, callers, and tests
- Confirm comments, function IDs, logs, and type hints match the changes
- Remove any unused, temporary, or debug code added by AI

---

## 5. Search Comment (Code Index) Specification `[All]`

### Required Fields

```
==================================================
Module / Plugin Name:

Role:
Role of this file

Dependencies:
Internal module names this file depends on

Libraries:
External libraries used (e.g. requests==2.31.0)

Permissions:
Required permissions (per project definition)

Function Index:
[F01] function_name - One-line description of what the function does
[F02] function_name - One-line description of what the function does

Search Tags:
Search keywords
==================================================
```

### Optional Fields

```
Input:            Input data
Output:           Output data
Related Files:    Related files
Security Clearance: Clearance level for external modules
Change Rules:     Notes for when modifying this file
Module Stability: stable / experimental (AI handles experimental modules with extra care)
Owner:            Human / AI / Shared (indicates last modifier)
```

### Format Compliance

- The `=` separator line must consist only of 10 or more `=` characters
- Every field name must be followed by `:` (no space)
- A field's value spans until the next field name appears
- The `generate_index.bat` parser depends on this format; formatting errors will cause index generation to fail

---

## 6. Index Auto-Generation Rules `[Medium+]`

### Principles

- `index.yaml` is **automatically generated by script** from header comments
- Manual editing of `index.yaml` is prohibited (the header comment is the single source of truth)
- Agents must always reference `index.yaml` before exploring code

### File Structure

Place the following two files in the project root:

```
generate_index.bat   ← Entry point (can also be run by double-click)
generate_index.ps1   ← Core processing (called from bat)
```

### Agent Execution Procedure

Run at every project startup:

```
1. Run generate_index.bat
   → If PowerShell is not found: display error and exit
   → If execution is not possible in the current environment: use existing index.yaml as-is
2. Load the generated index.yaml into context
```

### Script Files

Refer to the actual script files (place in project root):

- `generate_index.bat` ← Entry point (PowerShell check and invocation)
- `generate_index.ps1` ← Core processing (header parsing and index.yaml generation)

### index.yaml Structure

```yaml
generated: '2025-01-01T00:00:00'
root: '/path/to/project'
count: 3
modules:
  - file: plugins/chat_client.py
    name: 'ChatClient'
    role: 'IRC接続とメッセージ受信'
    tags: [irc, websocket, chat]
    dependencies: [stream_monitor]
```

※ To minimize AI token consumption, function lists, libraries, and permissions are excluded from the index. For details, refer to `_index/XX.py.yaml`.

### _index/ Folder (Function Detail Index) `[Medium+]`

Used to narrow down **line numbers** after identifying the target file in `index.yaml`.  
Enables loading only the relevant function's line range without reading the entire file — significantly reducing token consumption for large files.

**Location:** `_index/` folder at the project root (auto-generated; manual editing is prohibited)

**Naming convention:** Convert path separators (`/` `\`) to `__` to flatten the path, then append `.yaml`

```
Example: plugins/chat_client.py  →  _index/plugins__chat_client.py.yaml
         core.py                 →  _index/core.py.yaml
```

**XX.py.yaml structure:**

```yaml
file: 'plugins/chat_client.py'
generated: '2025-01-01T00:00:00'
functions:
  - id: F01
    name: connect
    desc: Establishes a WebSocket connection and returns the session
    line_start: 45
    line_end: 78
  - id: F02
    name: disconnect
    desc: Disconnects the session and releases resources
    line_start: 80
    line_end: 95
```

**generate_index.ps1 behavior:**

```
1. Scan all target files and generate index.yaml (same as before)
2. Parse [Fxx]~[FEND] blocks for each file in index.yaml and generate/update _index/XX.py.yaml
3. Auto-delete .yaml files in _index/ that are no longer listed in index.yaml
```

---

## 7. Function Index Rules `[All]`

Assign an ID to each function. Format: `[Fxx] function_name - one-line description`

```
[F01] load_config  - Load config file and return as dict
[F02] get_auth     - Retrieve API key from env and validate
[F03] connect      - Establish WebSocket connection and return session
[F04] recv_message - Start receive loop and pass to callback
```

Write the same ID immediately before the function, and place `# [FEND]` at the end of the function:

```python
# [F03] connect - Establish WebSocket connection and return session
def connect():
    ...
# [FEND]
```

By adding `[FEND]`, `generate_index.ps1` records line numbers precisely, allowing AI agents to load **only the relevant line range** via `_index/XX.py.yaml`.

### 7-1. Nesting and Decorator Rules

- Class methods also require `[Fxx]` / `[FEND]`
- If decorators are present, place `# [Fxx]` **immediately before the decorator line**
- `__init__` is also a target for FIDs (e.g., `[F01] __init__ - Initialize instance`)
- For nested inner functions, apply FID to the **outer function only**

### 7-2. Operational Rules

- All important functions must have a Function ID
- Function IDs must be unique within the file
- Keep the ID when making minor changes; re-number only when responsibility changes completely
- When requesting reviews or fixes, include both the function name and ID (e.g., "Fix [F03] connect")
- Keep `Function Index` in the header, `# [Fxx]` markers, and `_index/XX.py.yaml` contents in sync at all times

---

## 8. Log Output Rules `[All]`

All major processes must produce log output.

AI-Logs is not a standard log.

It is a structured context log for AI agents, containing:

- Work process (what was done)
- Reasoning (why it was done)
- Handoff state (what remains)

This ensures session continuity and prevents context loss across executions.

Top-level log directories must follow PascalCase with hyphen separation when representing logical roles.

Examples:

- logs/
- runtime/
- All-Logs/
- AI-Logs/

### What to Log

- Process start / end
- Errors
- Reconnection
- External communication
- Important state changes
- Security clearance evaluation results

### Log Format

```
[INFO]  module_name : message : run_id=YYYYMMDD_HHMMSS_NNN
[WARN]  module_name : message : run_id=YYYYMMDD_HHMMSS_NNN
[ERROR] module_name : message : {error} : run_id=YYYYMMDD_HHMMSS_NNN
```

### Log File Output Rules

Output logs to four folders simultaneously. Each folder uses a unified structure: **latest file at root, past files under `History/`**.

```
logs/
  ├── {app_name}.log               ← AI primary read (overwrite)
  └── History/
        └── {app_name}_{timestamp}.log

runtime/
  ├── {app_name}.log               ← AI detail read, when needed (overwrite)
  └── History/
        └── {app_name}_{timestamp}.log

All-Logs/
  ├── {app_name}.log               ← Human, latest full run (overwrite)
  └── History/
        └── {app_name}_{timestamp}.log

AI-Logs/
  ├── {app_name}.log ← ai_log.md. Work process, reasoning trace, and handoff state (AI thinking log for context continuity).
  └── History/
        └── {app_name}_{timestamp}.log
```

| Folder | Reader | Content | Level |
|---|---|---|---|
| `logs/` | AI agent (primary) | Minimal. Normal: OK/FAIL + count + run_id. On error: type, location, last 5 ops | WARNING and above |
| `runtime/` | AI agent (when needed) | Latest run full log including stack traces | INFO and above |
| `AI-Logs/` | AI (Context) | ai_log.md. Work process, reasoning trace, and handoff information (AI thinking log for context continuity) (5-gen management). | - |
| `All-Logs/` | Human (post-mortem only) | All actions, inputs/outputs, decisions, tool results | DEBUG and above |

#### AI Reading Order

```
1. logs/{app_name}.log          Required — always first
2. AI-Logs/{app_name}.log            Understand the context of previous work and pending tasks.
3. runtime/{app_name}.log       When more detail is needed
4. logs/History/ or runtime/History/   For historical comparison only
5. All-Logs/                    For deep analysis only — do not load routinely
```

#### run_id — Required on All Logs

A `run_id` is mandatory for all log entries. Format: `YYYYMMDD_HHMMSS_NNN`

```
[WARN] app : process_complete : total=42 : run_id=20260318_153012_001
```

- @Why: Ensures each session is uniquely traceable when multiple runs exist in History/

### Notes

- Do not include secrets (tokens, passwords, etc.) in logs
- Define detailed log format in the project's `RULES.md`

---

## 9. Comment Update Rules `[All]`

When code is changed, always update:

- `Function Index`
- `Search Tags`
- `Dependencies`
- `Permissions`

Mismatches between comments and implementation are prohibited.

---

## 10. AI Agent Response Rules `[All]`

### Response Language

- Respond in the language specified by `PROJECT_CONFIG.md`
- Default: Japanese (`Output strictly in Japanese.`)

### Implementation Plan

Before implementing, create a plan document that includes:

| Item | Content |
|---|---|
| Purpose | What this change is for |
| Targets | Files, functions, modules |
| Implementation | Specific changes to be made |
| Impact | Other features or modules affected |
| Risks | Anticipated issues and mitigations |

---

## 11. Frozen Areas `[Medium+]`

The following areas must not be modified under any circumstances unless explicitly approved:

- Core API
- Schema definitions
- Event formats
- Inter-module interface specifications
- Security clearance definitions
- `index.yaml` (auto-generated; manual editing is prohibited)

If modification is necessary, create a plan document and get it reviewed first.

---

## 12. Relationship with Project Rules `[All]`

```
GLOBAL_RULES.md  ← This file (common principles)
    ↓ inherits
RULES.md         ← Project-specific rules
```

`RULES.md` defines:

- Specific implementation of the secret store
- Security clearance level definitions and approval process
- List of permission types for Permissions field
- Detailed log format
- Project-specific frozen areas
- Overrides and exceptions to GLOBAL_RULES (must be stated explicitly)

---

## 12-1. Language-Specific Rule Files `[All]`

Language-specific rules are defined in the following files.
Projects using those languages must reference the corresponding file in addition to GLOBAL_RULES.

| Language | Rule File |
|---|---|
| Python | `PYTHON_RULES.md` |
| Java | `JAVA_RULES.md` |

When adding a new language, add a row to the table above and create the corresponding rule file.

---

## 13. Purpose of This Ruleset `[All]`

| Purpose | Description |
|---|---|
| Improved exploration efficiency | AI can understand code quickly |
| Prevention of incorrect modifications | Impact scope is identified in advance |
| Reduced token consumption | Headers provide overview, avoiding full-file reads |
| Improved readability | Facilitates human–AI collaborative development |
| Security assurance | Secrets and external modules are properly managed |
| Portability | UI/logic separation reduces cost of change |

---

## 14. Safety Standards for Agent Autonomous Execution (Guardrails) `[All]`

### 14-1. Error Recovery Procedure

- When an error occurs, guessing-based fixes (arbitrary code changes) are prohibited
- Always output and analyze logs or stack traces to identify the root cause before proposing a fix

### 14-2. Atomic Changes and Checkpoints

- Do not modify or implement multiple features at once
- Based on the `Function Index`, establish a checkpoint after each task (e.g., [F01]) is complete and verified

### 14-3. Human-in-the-Loop Conditions

The following operations require prior human approval before execution:

- Deleting files or making large-scale rewrites
- Destructive changes to database schemas
- Modifying authentication credentials or environment variables
- Destructive requests to external APIs
- Adding new external libraries (→ detailed in Section 18)

---

## 15. Coding Standards `[All]`

### 15-1. Mandatory Type Definitions

- Even in dynamically typed languages (e.g., Python), type hints must be provided as a rule
- This prevents schema mismatches in inter-module JSON communication and data structure hallucinations

### 15-2. Idempotency

- Initialization routines and scripts that change state must be implemented to produce the same result no matter how many times they are run
- This prevents system or data corruption from agent retry loops

### 15-3. Test Obligation and Self-Verification `[Medium+]`

- As a rule, write test code (or a verification script) before implementing, and **confirm it fails intentionally before writing the implementation** (TDD recommended)
- After changing code, always run the relevant tests
- Only consider a task complete after tests pass
- Declaring a task complete without running tests is prohibited
- Define specific test frameworks and execution procedures in `RULES.md`

### 15-4. AI-Directed Meta Comments

When implementing complex logic or unusual code, leave a rationale comment for agents:

**Format**

```python
# @AI-Note: <why this implementation was chosen / reasoning / cautions>
```

**Example**

```python
# @AI-Note: Retry logic is here because connection drops are usually transient.
#            Max 3 retries with exponential backoff. On exhaustion, raise to caller.
def connect_with_retry():
```

Use the `@AI-Note:` prefix consistently to maintain searchability across session resets or agent handoffs.

### 15-5. Process Description Comments

Use the following prefixes to write comments that communicate intent without requiring a full code read:

| Prefix | Purpose | Where to write |
|---|---|---|
| `@What:` | What the process does; language syntax explanation; equivalents in other languages | Before complex or language-specific code |
| `@Why:` | Design rationale; basis for decisions | Before functions or important logic |
| `@AI-Note:` | Agent-specific cautions and constraints | Wherever a modifier needs to know something |

**Example**

```python
# @What: Extracts only elements matching the condition from the list
#        Python list comprehension. Equivalent to filter() / where() in other languages
active_users = [u for u in users if u.is_active]

# @Why:  Raising the exception allows the caller to handle it
#        Catching here would break the retry logic upstream
# @AI-Note: Timeout value must come from config. Hardcoding is prohibited
def connect():
```

**When to write:**

- Not required on every line
- Prioritize language-specific syntax, hard-to-read logic, and design decisions
- Either `@What:` or `@Why:` alone is acceptable when appropriate

---

## 16. Version Control (Git) Rules `[Medium+]`

> **Applicability**: Mandatory for team projects or released products.
> For personal or prototype-stage projects, treat as recommended; state the adoption level in `RULES.md`.

### 16-1. Branch Separation and Protection

- Direct commits to the main branch (`main` or `master`) are prohibited
- Always create a working branch before starting work

```
feature/name      ← New feature
fix/description   ← Bug fix
refactor/target   ← Refactoring
```

### 16-2. Atomic Commits

- Commits represent the smallest functional unit that can be safely rolled back
- Do not mix multiple unrelated changes in a single commit

### 16-3. Self-Describing Commit Messages

Commit messages must include:

- The `Function Index` or module name being changed
- What was changed
- **Why the change was made (rationale / reasoning)**

**Format**

```
<type>([target]): <what changed>. <why>.

Example:
feat([F02]): Add retry logic to credential fetch.
             Prevents crashes on transient network drops.
```

### 16-4. Conflict Resolution Procedure

When a merge conflict occurs:

- Guessing-based automatic resolution by AI is prohibited
- Summarize the context around conflict markers (`<<<<<<<` etc.) and the intent of both branches
- Report the proposed resolution to a human and wait for instruction before resolving

```
# Reading conflict markers
<<<<<<< HEAD (your branch's changes)
Code A
=======
Code B
>>>>>>> branch-name (the branch being merged)
```

- Removing only the markers without reflecting either change is prohibited
- Guessing and discarding one side is prohibited

---

## 17. Operational Notes `[Large recommended]`

### 17-1. Index Bloat Mitigation (Future Consideration)

If the project grows and `index.yaml` starts consuming excessive context window space, consider splitting the index by directory.
Define this in the project's `RULES.md` when the need arises.

---

## 18. Dependency Management `[All]`

### 18-1. Principle for Adding External Libraries

- Adding new external libraries **requires human approval** (→ Section 14-3)
- Before adding, create a plan document stating the purpose, alternatives considered, license, and version

### 18-2. License Verification

- Always verify the license of any library being added
- Confirm license compatibility with the project before adding
- Document the verification result in the plan document

| License | Commercial Use | Notes |
|---|---|---|
| MIT / Apache 2.0 / BSD | Generally OK | Maintain copyright notice |
| LGPL | Conditional | Verify linking method |
| GPL | Caution required | Source disclosure may be required |
| Commercial license | Verify | Separate contract may be needed |

### 18-3. Version Pinning

- **Pin versions** (e.g., `requests==2.31.0`)
- Range specifiers (`>=`) are prohibited by default; if used, state the reason in `RULES.md`
- List used libraries and versions in the module's header comment `Libraries` field (→ Section 5)

---

## 19. Coding Style Consistency `[All]`

Language-specific detailed conventions are defined in `RULES.md`. The following principles apply across languages.

### 19-1. Function / Method Design

- Maintain single responsibility per function
- Keep functions short (guideline: within 50 lines; consider splitting if exceeded)
- Keep argument count low (guideline: 4 or fewer)

### 19-2. Readability

- Define magic numbers as constants or config values
- Limit nesting to 3 levels; use early return or function extraction for deeper nesting
- Avoid abbreviations and use names that clearly convey intent

### 19-3. Prohibition of Dead Code

- Do not leave commented-out code (Git manages history; it's unnecessary)
- Do not leave unused variables, functions, or imports
- Do not leave debug print / console.log statements in production code

---

## 20. Quality Policy `[All]`

### 20-1. Error Handling

- Swallowing errors is prohibited (empty catch / except blocks are prohibited)
- Always log errors and propagate them appropriately up the call stack
- Error messages must include the cause and location

### 20-2. Side Effect Disclosure

- Functions that modify external state (files, DB, network, global variables)
  must disclose the side effect via the function name or `@AI-Note:`

### 20-3. No Hardcoding

- Do not hardcode URLs, file paths, or configuration values in code
- Extract them to config files, environment variables, or constant definitions

### 20-4. Code Review Criteria

Self-check items for agents after implementation:

- Does the header comment match the current implementation?
- Are type hints provided?
- Is error handling complete?
- Are there any hardcoded values?
- Were tests run?

### 20-5. Zero-Trust Principle for External Data `[All]`

- Treat all data from networks, user input, or external files (API responses, chat comments, etc.) as **untrusted**
- When passing external data to logs, databases, or LLM prompts, always implement sanitization or escaping
- Passing external input directly to `eval()`-type functions or executing it as a system command is strictly prohibited

---

## 21. File Naming Rules `[All]`

Language-specific conventions may override these in `RULES.md`. The following are common principles.

### 21-1. Basic Principles

- File names must **clearly indicate the role at a glance**
- Abbreviations and sequential numbering (`util2.py`, `module_new.js`) are prohibited
- Use only alphanumerics, underscores, and hyphens (no spaces)

### 21-2. Naming Patterns

| Type | Pattern | Example |
|---|---|---|
| Module / Class | `snake_case` or `PascalCase` (follow language convention) | `chat_client.py` / `ChatClient.cs` |
| Config file | `snake_case` | `app_config.toml` |
| Test file | `test_target` or `target_test` | `test_chat_client.py` |
| Script | `verb_target` | `generate_index.ps1` |
| Document | `SCREAMING_SNAKE_CASE` (important docs) or `snake_case` | `GLOBAL_RULES.md` / `api_reference.md` |

### 21-3. Directory Structure Principles

- Directory names are nouns that represent their role
- Avoid overly deep hierarchies (guideline: 4 levels or fewer)
- Define project-specific directory structure in `RULES.md`

### 21-4. File Size and Cognitive Load Management `[Medium+]`

- If a file exceeds **500 lines (guideline)**, or is predicted to exceed it with this change,
  appending to it without refactoring is prohibited as a rule
- Before starting new implementation, create a plan proposing how to split the file into multiple modules and present it to a human
- This prevents both AI context window exhaustion and spaghetti structure growth

---

## 22. AI Exploration and Context Conservation Rules `[All]`

### 22-1. Exploration Order

Agents must strictly follow this order when exploring code:

```
1. Check index.yaml (identify the target file)
2. Check _index/XX.py.yaml (identify Function ID and line numbers)
3. Read only the relevant line range in the target file (minimum load by line number)
4. Read only the header section if header comment is needed
5. Reading the full file is a last resort
```

**Example of line-range reading (PowerShell):**

```powershell
# When _index/XX.py.yaml shows line_start=45, line_end=78
Get-Content chat_client.py | Select-Object -Skip 44 -First 34
```

### 22-2. Exploration Prohibitions

- Starting with a full-project scan is prohibited
- Starting with a full-file read is prohibited
- First identify "which file and which feature to look at" before reading
- Do not read files unrelated to the change target
- Only trace `Dependencies` for additional investigation when dependency is unclear

### 22-3. Context Consumption Minimization

- Full-file loading must not be the default behavior
- Identify the minimum necessary scope before modifying
- Summarize and internally memoize content already read to reduce re-reading
- Skip constant groups and helper code unrelated to the change
- When outputting, prioritize required diffs, key points, and impact scope; avoid redundant full-text reproduction

### 22-4. Prompt Caching Optimization `[All]`

> This is a design guideline for those building systems that call AI agents.

- Place "stable or infrequently changing information" such as `PROJECT_CONFIG.md`, `index.yaml`, and shared rules at the **beginning** of the prompt
- Place per-task instructions and dynamically changing information at the **end** of the prompt
- This maximizes KV cache hit rates, improving speed and reducing cost

### 22-5. AST / Skeleton Exploration `[Large recommended]`

- When exploring an unknown large module, do not load full text from the start
- When available, use AST parsers or Tree-sitter to extract only function signatures and header comments as a "skeleton" for an overview
- Only fetch full text for specific `[Fxx]` blocks where implementation details are needed
- When tools are unavailable, use `index.yaml` and the Function Index as an alternative

---

## 23. Design Record Rules `[Medium+]`

Record important design decisions in persistent documents so they remain accessible across sessions.

### 23-1. Recording Principles

- Do not end important decisions in conversation alone
- Always record "why this structure was chosen"
- Record destructive changes, policy shifts, and library adoption rationale
- Maintain a state where the next AI or next session can resume just by reading
- Record the gap between pre-implementation policy and post-implementation result as needed

### 23-2. Recommended Documents

Create the following as needed based on project scale. Define specific file structure in `RULES.md`.

| File | Content |
|---|---|
| `CONTEXT.md` | Current design state, constraints, unresolved issues (always check before starting work) |
| `DESIGN.md` | Overall design and architecture policy |
| `DECISIONS.md` | Design decision history and rationale |
| `KNOWN_ISSUES.md` | Known issues and temporary workarounds |
| `ROADMAP.md` | Future implementation plans |
| `CHANGELOG.md` | Feature addition / change history (for users and AI) |

### 23-3. User-Facing Change History (CHANGELOG) `[Medium+]`

- When a task involving a `[Fxx]` addition or feature spec change is complete,
  update `CHANGELOG.md` in addition to `ai_log.md`
- Write at a level where "a human or another AI reading it can understand what features were added or changed,"
  not in the style of technical commit log details

---

## 24. AI Work Log Rules `[Medium+]`

Agents record their work in `ai_log.md` at each checkpoint.

### 24-1. Directory Structure and Generation Management

Follows the same two-tier structure as other log folders.

AI-Logs/
├── ai_log.md                ← Latest work log (Append-only)
└── History/
└── ai_log_{timestamp}.log

- **Latest Log Maintenance**: Continuously append work details to `ai_log.md`.
- **Rotation (Moving to History)**: Move content to `History/` and create a new (clear) `ai_log.md` when any of the following conditions are met:
  - Approximately **5 sessions** worth of logs have accumulated.
  - The file size bloats and starts exhausting the AI's context window.
  - A major project milestone or feature implementation is completed.

### 24-2. When to Record

Do not write only after all work is done; record continuously at these moments:

- When starting work (what to do, target files)
- When each Function Index unit is complete (what was finished)
- When an error occurs (what happened, temporary workaround)
- Before session end or quota exhaustion (what to do next)

Real-time recording ensures state can be restored regardless of when a forced termination, crash, or quota exhaustion occurs.

### 24-3. Record Content (Format)

Each entry should ideally include a `run_id` to uniquely identify the session.

```markdown
## [Datetime] Work Log (run_id: YYYYMMDD_HHMMSS_NNN)

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
- Temporary workaround:

### Handoff for Next Session
- What to do next:
- Incomplete items:
- Notes:

### 24-4. Rules

- Record failed attempts and rejected approaches as needed
- Write at a level of detail that another AI or human can understand the situation
- Manage `ai_log.md` in Git and preserve history

### 24-5. Retreat Rule for Context Degradation

Immediately stop guessing-based fixes when any of the following applies:

- The same error has not been resolved after 3 or more consecutive attempts
- Extended task duration causes noticeable context confusion (hallucination)

Procedure after stopping:

```

1. Write the current situation, what was tried, and the cause of the deadlock in ai_log.md
2. Request a session restart and human intervention from a person (or another agent)
3. Do not make guessing-based fixes or stopgap code changes

```

- Continuing guessing-based fixes on the basis of "I'm almost there" is prohibited
- Retreating is not failure — it is the correct decision to protect code and context

### 24-6. Context Summarization and Disposal in Long Sessions `[Medium+]`

- When conversation history grows long and context window exhaustion approaches,
  do not continue holding all past exchanges as-is
- Retain only "context relevant to the current task" in summarized form;
  intentionally discard old execution logs and exploration memory (sliding window)
- Write important decisions to `ai_log.md` or `DECISIONS.md` to keep context lightweight

---

## 25. Environment-Independent Rules `[All]`

Prevents code from failing due to specific environment dependencies.
Language version dependencies are defined in the respective language rule files (e.g., `PYTHON_RULES.md`).

### 25-1. Character Encoding

- Use **UTF-8 consistently** for code, files, and communication
- Opening files without explicitly specifying encoding is prohibited
- Do not depend on the OS default encoding

```python
# ✅ Recommended
with open(path, encoding="utf-8") as f: ...

# ❌ Prohibited (depends on OS default)
with open(path) as f: ...
```

### 25-2. Timezone

- **Save and transmit datetime data in UTC**
- Convert to the OS timezone only for display
- Using naive datetime objects without specifying timezone is prohibited

```
Save / transmit → UTC (environment-independent)
Display         → Convert to OS timezone
```

### 25-3. Environment Variables

- Code must not depend directly on environment variables
- Retrieve via config file; use environment variables as fallback
- Always define a default value for when the environment variable is absent

```
Priority: config file → environment variable → default value
```

- Use a secret store for secrets such as API keys (→ Section 2-4)

### 25-4. Hardware

- Do not hardcode CPU core count, memory size, or GPU availability
- Retrieve hardware specs dynamically or via config values
- When using special hardware such as GPU, always provide a CPU fallback

```
CPU core count → Retrieve dynamically (e.g., os.cpu_count())
GPU presence   → Implement CPU fallback with conditional branching
Memory size    → Design to be adjustable via config
```

- When using hardware-dependent processing, document the dependency and alternative in `@AI-Note:`

### 25-5. File Paths

- Do not hardcode file path separators
- Use the path manipulation API provided by the language or framework
- Do not hardcode absolute paths

```python
# ✅ Recommended (Python)
from pathlib import Path
config_path = Path(__file__).parent / "config" / "app.toml"

# ❌ Prohibited
config_path = "C:\\Users\\user\\project\\config\\app.toml"
config_path = "./config/app.toml"  # depends on working directory
```

- If project-root-relative paths are needed, document them in `PROJECT_CONFIG.md`

---

## 26. Agent Skills Rules `[All]`

### 26-1. Basic Policy

- Skills are managed as individual instruction units that agents "read only when needed"
- The skills folder is specified in `PROJECT_CONFIG.md` (default: `skills/`)
- The skill list is managed in `skill_index.yaml` (auto-generated; manual editing prohibited)
- Agents must always read SkillManager first at startup

### 26-2. SkillManager

SkillManager is a meta-skill that manages all skills.

```
skills/
  skill_index.yaml          ← Skill list (auto-generated)
  generate_skills.bat       ← Entry point
  generate_skills.ps1       ← Core processing (scans SKILL.md files and generates JSON)
  skill_manager/
    SKILL.md                ← Always read first
    skill_manager.md        ← Search and selection procedure
```

**Agent Startup Procedure**

```
1. Read skills/skill_manager/SKILL.md
2. Read skill_index.yaml
3. Identify relevant skills by tags and description
4. Load only the relevant skills
5. Do not read unrelated skills
6. Reference GLOBAL_RULES.md only when skills cannot resolve the issue
```

### 26-3. SKILL.md Format

Place a `SKILL.md` in each skill folder. Define metadata in YAML front matter at the top.

```yaml
---
name: HeaderComment
description: Use when writing or reviewing header comments
priority: 1
tags: [header, comment, create]
---

# Skill detail content here
```

| Field | Content |
|---|---|
| `name` | Skill name (must be unique) |
| `description` | When to use it (used by agents to decide relevance) |
| `priority` | Load priority (SkillManager = 0; others = 1 or higher) |
| `tags` | Search tags (array) |

### 26-4. skill_index.yaml Structure

```json
{
  "generated": "2025-01-01T00:00:00",
  "skills_root": "I:/.agents/MainSkills/skills",
  "count": 3,
  "skills": [
    {
      "name": "SkillManager",
      "path": "skill_manager/SKILL.md",
      "description": "Manages skill search and selection. Always read first.",
      "priority": 0,
      "tags": ["meta", "management"]
    },
    {
      "name": "HeaderComment",
      "path": "header_comment/SKILL.md",
      "description": "Use when writing or reviewing header comments.",
      "priority": 1,
      "tags": ["header", "comment", "create"]
    }
  ]
}
```

### 26-5. Skill Auto-Generation Rules

- Always run `generate_skills.bat` after adding or modifying a skill
- Manual editing of `skill_index.yaml` is prohibited (the `SKILL.md` files are the single source of truth)
- `skill_index.yaml` is included in frozen areas (→ Section 11)

### generate_skills.bat

```bat
@echo off
chcp 65001 > nul
echo [INFO] generate_skills : starting...

where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] generate_skills : PowerShell not found.
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -File "%~dp0generate_skills.ps1" %*
if %errorlevel% neq 0 (
    echo [ERROR] generate_skills : script failed.
    pause
    exit /b 1
)

echo [INFO] generate_skills : done.
```

### generate_skills.ps1

```powershell
# generate_skills.ps1
# Scans SKILL.md files and generates skill_index.yaml
# Usage: .\generate_skills.bat [-Root <path>] [-Out <path>]

param(
    [string]$Root = ".",
    [string]$Out  = "skill_index.yaml"
)

function Parse-SkillHeader {
    param([string]$FilePath)
    $content = Get-Content $FilePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { return $null }
    if ($content -notmatch "(?s)^---\s*\n(.+?)\n---") { return $null }
    $yaml = $Matches[1]
    $fields = @{}
    foreach ($line in $yaml -split "\n") {
        if ($line -match "^(\w+):\s*(.+)$") {
            $fields[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
    return $fields
}

function Parse-Tags {
    param([string]$Raw)
    ($Raw -replace "[\[\]]", "" -split "[,\s]+") | Where-Object { $_ }
}

$skills = @()

Get-ChildItem -Path $Root -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue |
Where-Object { $_.FullName -notmatch "\\(\.git|__pycache__|node_modules)\\" } |
ForEach-Object {
    $fields = Parse-SkillHeader $_.FullName
    if (-not $fields) { return }
    $relPath = $_.FullName.Replace((Resolve-Path $Root).Path, "").TrimStart("\", "/")
    $skills += [ordered]@{
        name        = $fields["name"]
        path        = $relPath -replace "\\", "/"
        description = $fields["description"]
        priority    = [int]($fields["priority"] ?? 1)
        tags        = @(Parse-Tags ($fields["tags"] ?? ""))
    }
}

$skills = $skills | Sort-Object { $_["priority"] }

$output = [ordered]@{
    generated   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    skills_root = (Resolve-Path $Root).Path -replace "\\", "/"
    count       = $skills.Count
    skills      = $skills
}

$output | ConvertTo-Json -Depth 10 | Set-Content $Out -Encoding UTF8
Write-Host "[INFO] generate_skills : generated $($skills.Count) skills -> $Out"
```

### 26-6. Sharing Across Multiple Agents

- The skills folder is shared across all agents
- Standard path: `I:\.agents\MainSkills\skills\`
- Point each agent's skill folder to this path:
  - If path can be changed → specify in the agent's config file
  - If it cannot → create a symbolic link with `mklink /D "[agent skill folder]" "I:\.agents\MainSkills\skills\`

### 26-7. English Recommended for Skills and Split Rule Files `[Medium+]`

- It is recommended to write split rule files under `rules/` and `SKILL.md` files under `skills/` in English
- This minimizes token consumption and removes the language barrier when distributing to English-speaking users
- Even if rule files are in English, set agent output instructions to the target language
  (e.g., add `Output strictly in Japanese.` to CORE.md)
- Source of truth language management:
  - Japanese original (`GLOBAL_RULES.md` etc.) ← the authoritative source for editing
  - English original (`GLOBAL_RULES_EN.md` etc.) ← for distribution to English-speaking users
  - English split files (`rules/` directory) ← compressed version read by agents

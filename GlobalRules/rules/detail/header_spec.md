# Header Comment Specification (Section 5 Detail)

> Detailed version of GLOBAL_RULES_EN.md Section 5.
> Reference only when writing or reviewing a header comment.

## Required Fields

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

## Optional Fields

```
Input:              Input data
Output:             Output data
Related Files:      Related files
Security Clearance: Clearance level for external modules
Change Rules:       Notes when modifying this file
Module Stability:   stable / experimental
Owner:              Human / AI / Shared
```

## Format Compliance

- Separator line: 10 or more `=` characters only
- Field names must be followed by `:` (no space)
- Field value spans until the next field name
- The `generate_index.bat` parser depends on this format —  Minor formatting issues should not break parsing
- If parsing fails:
  - fallback to:
    - filename
    - Search Tags (if available)
    - Function names (best-effort)

## Function Index Operational Rules

- All important functions must have a `[F01]`-style ID
- Format: `[Fxx] function_name - one-line description`
- IDs are sequential and unique within the file (duplicates across files are allowed)
- Write the same ID as a comment immediately before the function; write `# [FEND]` at the end
- If decorators are present, place `# [Fxx]` immediately before the decorator line
- `__init__` and class methods are also FID targets
- For nested inner functions, apply FID to the outer function only
- Never renumber automatically
- Only renumber with human instruction
- When requesting fixes, include both function name and ID (e.g., "Fix [F03] connect")

## _index/ Folder Structure

`generate_index.ps1` auto-generates `_index/XX.py.yaml` alongside `index.yaml`.  
These files record line numbers per function and enable agents to load only the required range.

```yaml
file: 'plugins/chat_client.py'
generated: '2025-01-01T00:00:00'
functions:
  - id: F01
    name: connect
    desc: Establishes a WebSocket connection and returns the session
    line_start: 45
    line_end: 78
```

Naming rule: replace path separators with `__` and append `.yaml`
```
plugins/chat_client.py  →  _index/plugins__chat_client.py.yaml
```

## index.yaml Structure

```yaml
generated: '2025-01-01T00:00:00'
root: 'I:/path/to/project'
count: 1
modules:
  - file: plugins/chat_client.py
    name: 'ChatClient'
    role: 'IRC connection and message reception'
    tags: [irc, websocket]
    dependencies: [asyncio, json]
```

For function-level detail (line numbers), refer to `_index/plugins__chat_client.py.yaml`.

Script: run `generate_index.bat` to auto-generate both `index.yaml` and `_index/*.yaml`. Manual editing is prohibited.

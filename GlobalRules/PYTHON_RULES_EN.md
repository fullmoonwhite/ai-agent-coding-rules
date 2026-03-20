# Python Development Rules

> Inherits from GLOBAL_RULES_EN.md. This file defines Python-specific rules.
> Project-specific additions are written in `RULES.md`.

---

## 0. Prerequisites

- Target Python 3.10 or higher
- Source file encoding must be UTF-8 and should not be changed in principle
- Follow PEP 8 (the rules below concretize and extend PEP 8)
- Standard tooling (override in `RULES.md` if needed):

| Tool | Purpose |
|---|---|
| `ruff` | Lint and format (replaces Black + flake8) |
| `mypy` | Static type checking |
| `pytest` | Testing |

---

## 1. Naming Rules

| Target | Rule | Example |
|---|---|---|
| Variable / Function | `snake_case` | `user_name`, `get_config()` |
| Class | `PascalCase` | `ChatClient`, `UniversalPost` |
| Constant | `SCREAMING_SNAKE_CASE` | `MAX_RETRY`, `DEFAULT_TIMEOUT` |
| Module / File | `snake_case` | `chat_client.py`, `stream_monitor.py` |
| Private | Leading underscore | `_internal_state` |
| Type alias | `PascalCase` | `UserId = int`, `PostList = list[Post]` |

### Prohibited

- Single-character variables (loop counters `i`, `j` are exceptions)
- Meaningless names (`tmp`, `data2`, `new_func`)
- Abbreviations (`usr` → `user`, `msg` → `message`)

---

## 2. Type Hint Rules

### 2-1. Basic Principles

- Add type hints to all function/method arguments and return values
- Also annotate variables when their type is not obvious

### 2-2. Type Syntax (Unified to Python 3.10+ style)

```python
# ✅ Python 3.10+ syntax
def get_user(user_id: int) -> str | None: ...
def process(value: int | str) -> str: ...
x: list[int] = []
y: dict[str, int] = {}
# ❌ Do not use old syntax: Optional / Union / List / Dict
```

### 2-3. TypedDict Usage

Use `TypedDict` for dict-type data exchanged between modules:

```python
from typing import TypedDict

class UserConfig(TypedDict):
    name: str
    timeout: int
    debug: bool

# For optional keys
class PartialConfig(TypedDict, total=False):
    name: str
    timeout: int  # optional
```

### 2-4. Choosing dataclass vs TypedDict vs Pydantic

| Use case | Use |
|---|---|
| Internal data structures (with methods) | `@dataclass` |
| Inter-module communication / JSON conversion | `TypedDict` |
| Input data requiring validation | `Pydantic BaseModel` |

### 2-5. No Any

- `Any` is prohibited by default
- Use `TypeVar` or `Protocol` when types are uncertain
- If unavoidable, document the reason with `# @AI-Note:`

---

## 3. Import Rules

### 3-1. Groups and Order

List imports in the following order with a blank line between groups:

```python
# Group 1: Standard library
import os
import sys
from pathlib import Path

# Group 2: Third-party
import requests
from websockets import WebSocketClientProtocol

# Group 3: Internal modules
from .chat_client import ChatClient
from .config import AppConfig
```

### 3-2. Prohibited

```python
# ❌ Wildcard imports prohibited
from module import *

# ❌ Unused imports prohibited
import os  # not used

# ❌ Circular imports prohibited (redesign instead)
```

---

## 4. Function Comment Templates

Applies the GLOBAL_RULES comment system (`@What:` / `@Why:` / `@AI-Note:`) to Python.

Not required on every line. Prioritize "ambiguous, complex, or important" functions.

---

### 4-1. Connection / Communication

```python
# @What: Establishes a TCP connection to a WebSocket server
#        Raises on failure and delegates to the caller (swallowing prohibited)
#        Equivalent to connect() / open() in other languages
# @Why:  Connection drops are usually transient; retry is controlled by the caller
# @AI-Note: Timeout must come from config. Hardcoding prohibited
# [F03] Connect
async def connect(url: str, timeout: int) -> WebSocketClientProtocol:
    ...
```

---

### 4-2. Data Transformation / Normalization

```python
# @What: Normalizes raw dict data into a UniversalPost type
#        Returns a default value (not None) when a key is missing
#        Equivalent to map() / transform() in other languages
# @Why:  Eliminates None checks downstream and preserves type consistency
# [F05] Normalize data
def normalize(raw: dict[str, object]) -> UniversalPost:
    ...
```

---

### 4-3. Side Effects (DB / File / Network Write)

```python
# @What: Writes session info to SQLite (modifies external state)
#        Uses INSERT OR REPLACE to ensure idempotency
# @Why:  Tracks startup time and platform per session
# @AI-Note: Assumes WAL mode. Call from outside a transaction.
#            Idempotent — safe to call multiple times
# [F07] Save session
def save_session(db: sqlite3.Connection, session: SessionData) -> None:
    ...
```

---

### 4-4. Pure Functions (Input → Output Only, No Side Effects)

```python
# @What: Converts an IRC emotes tag string into a list of EmoteSpan
#        Example: "425618:0-6" → [EmoteSpan(id="425618", start=0, end=6)]
# @Why:  Allows the UI layer to receive emote IDs and position info
# [F09] Parse emote tag
def parse_emote_tag(emote_tag: str) -> list[EmoteSpan]:
    ...
```

---

### 4-5. Initialization / Config Loading

```python
# @What: Loads config from a TOML file and returns it as AppConfig
#        Returns defaults if the file doesn't exist (no exception raised)
#        Equivalent to loadConfig() / initialize() in other languages
# @Why:  Allows default behavior without a config file
# @AI-Note: Pass an absolute path. Relative paths are working-directory-dependent
# [F01] Load config
def load_config(path: Path) -> AppConfig:
    ...
```

---

### 4-6. Error Handling / Retry

```python
# @What: Retries the connect operation up to max_retry times
#        Increases wait time exponentially on each failure (exponential backoff)
#        Equivalent to retry() / withRetry() in other languages
# @Why:  Prevents crashes on transient network drops
# @AI-Note: Max retries and initial wait time must come from config
#            On exhaustion, raises ConnectionError to the caller
# [F03] Reconnect
async def connect_with_retry(
    url: str,
    max_retry: int,
    base_wait: float,
) -> WebSocketClientProtocol:
    ...
```

---

## 5. Exception Handling Rules

### 5-1. Basic Principles

```python
# ❌ Prohibited: swallowing exceptions
try:
    connect()
except Exception:
    pass

# ❌ Prohibited: catching bare Exception (use @AI-Note if unavoidable)
try:
    connect()
except Exception as e:
    log(e)

# ✅ Recommended: catch specific exception, log, and re-raise
try:
    connect()
except ConnectionError as e:
    logger.error(f"chat_client : connect failed : {e}")
    raise
```

### 5-2. Custom Exceptions

Define custom exception classes for project-specific errors:

```python
# @What: Base exception class specific to this module
#        Provides a dedicated base to distinguish from generic exceptions
class ChatClientError(Exception): ...
class ConnectionError(ChatClientError): ...
class AuthenticationError(ChatClientError): ...
```

---

## 5-3. Handling External Data (Zero Trust) `[All]`

- Treat all external input (HTTP, WebSocket, files, user input) as untrusted
- When passing to LLM prompts, sanitize thoroughly (prompt injection defense)
- Passing external input to `eval()` / `exec()` is prohibited

```python
# ❌ Prohibited
eval(user_input)
subprocess.run(user_input, shell=True)

# ✅ Recommended: sanitize before use
sanitized = sanitize(user_input)
```

---

## 6. Log Output Rules

Implements the GLOBAL_RULES log format in Python.

```python
import logging

# @What: Gets a per-module logger
#        Using __name__ maps the filename directly to log output
logger = logging.getLogger(__name__)

# Format (run_id is embedded by setup_logger formatter)
logger.info("chat_client : process_start")
logger.warning("chat_client : reconnecting")
logger.error(f"chat_client : connect failed : {e}")
```

### Three-Folder Output Policy

| Folder | Content | Level |
|---|---|---|
| `logs/` | Minimal — AI agent primary read (overwrite) | `WARNING` and above |
| `runtime/` | Full latest run — AI agent detail read (overwrite) | `INFO` and above |
| `All-Logs/` | All actions — human post-mortem only (overwrite) | `DEBUG` and above |

Each folder: **latest file at root, past files under `History/`**.

- AI reading order: `logs/` → `runtime/` → `History/` → `All-Logs/` (last resort)
- Use `setup_logger()` from `examples/log_example.md` for standard setup.

### Prohibited

```python
# ❌ No print for logging (do not leave even for debugging)
print("connected")

# ❌ Do not include secrets in logs
logger.info(f"token={token}")  # NG
```

---

## 7. Virtual Environment and Dependency Management

### 7-1. Virtual Environment

```
# Create
python -m venv .venv

# Activate (Windows)
.venv\Scripts\activate
```

- Do not commit `.venv` to the repository (add to `.gitignore`)

### 7-2. Dependency Files

- Pin versions (per GLOBAL_RULES Section 18-3)

```
# requirements.txt
requests==2.31.0
websockets==12.0
```

- Follow GLOBAL_RULES Section 18 procedure when adding a library

---

## 8. AI-Generated Code Verification Checklist

Verify the following after generating or modifying Python code:

- [ ] Are type hints on all functions?
- [ ] Is `Any` avoided? (If used, document reason with `@AI-Note:`)
- [ ] Is `import *` avoided?
- [ ] Are exceptions not swallowed?
- [ ] Is `print` not used for logging?
- [ ] Are there no hardcoded values?
- [ ] Is the `Libraries` field in the header comment updated?
- [ ] Was a plan document and license check completed for any new library?
- [ ] Was it judged whether `@What:` / `@Why:` is needed for each function?
- [ ] Was test code written and run successfully?
- [ ] Is external input sanitized / escaped? (Zero Trust principle)
- [ ] Is external input not passed to `eval()`-type functions?

---

## 9. Async / Task Management Rules

Especially important for WebSocket, resident, and event-driven apps like StreamHub or AITuberCore.

### 9-1. Basic Principles

- Prefer `async` for I/O-bound operations (WebSocket, HTTP, file watching, etc.)
- Do not run heavy CPU work directly inside `async` functions — offload to a thread or process
- Do not prefix async function names with `async_` (the `async def` keyword is sufficient)

### 9-2. Task Management

- Do not overuse `asyncio.create_task()` directly
- Start and stop background tasks through a management layer such as `TaskManager`
- Always define behavior on **start, stop, and exception** for each task
- Implement with `cancel()` in mind; never swallow `CancelledError`

```python
# ❌ Direct asyncio.create_task() is prohibited (creates orphaned tasks)
# ✅ Start through the management layer
# @What: Registers and starts a task via the management layer
# @Why:  Prevents orphaned and unstoppable tasks
await task_manager.start(some_work())
```

### 9-3. Exception Handling

```python
# ❌ Prohibited: swallowing CancelledError
try:
    await some_work()
except Exception:
    pass  # CancelledError is also swallowed

# ✅ Recommended: always re-raise CancelledError
try:
    await some_work()
except asyncio.CancelledError:
    raise  # always re-raise
except Exception as e:
    logger.error(f"task_manager : task failed : {e}")
```

---

## 10. Module Responsibility Rules

### 10-1. File Responsibility Principle

- One file = one responsibility
- Ambiguous file names are prohibited:

```
# ❌ Prohibited
utils.py
common.py
helper.py
misc.py

# ✅ Recommended (names with clear responsibility)
emote_parser.py
session_store.py
connection_manager.py
```

### 10-2. Dependency Direction

- Dependency direction must follow:

```
UI / Adapter → Service → Core
```

- Circular references indicate a structural problem and must be redesigned
  (exceptions require `@AI-Note:` explaining the reason)
- Define specific directory structure in the project's `RULES.md`

---

## 11. State Management Rules

Prevents AI from falling back to global variables.
Critical for resident apps, reconnection logic, and concurrent systems.

- Do not hold state in global variables
- Aggregate state in `@dataclass` / classes / Context objects
- Clearly define the owner of connection state, session state, and config cache
- Confine mutable shared state to a single location
- Do not initialize state during module import

```python
# ❌ Holding state in global variables is prohibited
# ✅ Aggregate in a dataclass
# @What: Centrally manages connection state
# @Why:  Prevents race conditions during concurrent ops and reconnection
@dataclass
class ConnectionContext:
    connected: bool = False
    session_id: str | None = None
    retry_count: int = 0
```

---

## 12. Test Rules

### 12-1. When to Write Tests

- Add at least one test when adding a new module
- **Always** write tests for:
  - Transformation, normalization, and parser logic
  - Pure functions (happy path, boundary values, error cases)
- When fixing a bug, **add a regression test first**, then fix

### 12-2. TDD Procedure (Recommended)

```
1. Write the test
2. Run it and confirm it fails intentionally (Red)
3. Implement the feature
4. Confirm the test passes (Green)
5. Refactor
```

- Do not consider a task complete without running tests
- Run with `pytest`; all tests must pass before completion

### 12-3. How to Write Tests

- Mock external communication; do not depend on live network connections
- Name test files `test_<target_filename>.py`
- Name test functions `test_<what_is_being_tested>` for clarity

```python
# ✅ Recommended
def test_parse_emote_tag_returns_correct_span():
    result = parse_emote_tag("425618:0-6")
    assert result == [EmoteSpan(id="425618", start=0, end=6)]

def test_parse_emote_tag_empty_string_returns_empty_list():
    assert parse_emote_tag("") == []
```

---

## 13. Comment Application Rules

Guidelines for deciding where to write `@What:` / `@Why:` / `@AI-Note:`.

### 13-1. When to Write @What and @Why

Apply to functions that meet any of the following:

- Makes external calls (WebSocket, HTTP, DB, file)
- Transformation / normalization with non-obvious rules
- Contains retry or exception control logic
- Logic whose intent is not immediately clear

Not required on every function. Simple getters / setters do not need them.

### 13-2. When to Write @AI-Note

- Only when there are constraints that AI is likely to misunderstand
- When there is a "changing this in this way will break things" warning

```python
# ✅ Needs @What / @Why (external call, retry)
# @What: Starts the loop that connects to IRC WebSocket and receives messages
# @Why:  Does not propagate exceptions so reconnect loop can resume on drop
async def start_receive_loop(): ...

# ✅ Does not need @What / @Why (intent is obvious)
def get_username(user: User) -> str:
    return user.name
```

---

## 14. Detailed Log Rules

Supplement to GLOBAL_RULES Section 8 for Python.

### 14-0. Three-Folder Structure

```
logs/
  ├── {app_name}.log               ← Minimal. AI primary read. Overwrite per run.
  └── History/{app_name}_{timestamp}.log

runtime/
  ├── {app_name}.log               ← Detail. AI reads when needed. Overwrite per run.
  └── History/{app_name}_{timestamp}.log

All-Logs/
  ├── {app_name}.log               ← Full. Human only. Overwrite per run.
  └── History/{app_name}_{timestamp}.log
```

- `logs/`     : `WARNING` and above
- `runtime/`  : `INFO` and above
- `All-Logs/` : `DEBUG` and above
- AI reading order: `logs/` → `runtime/` → `History/` → `All-Logs/` (last resort)
- See `examples/log_example.md` for `setup_logger()` implementation

### 14-1. run_id

All logs must carry a `run_id`. It is embedded automatically by `setup_logger()` — callers do not need to add it manually.

```python
# run_id is injected via formatter in setup_logger()
logger.warning("app : process_complete : total=42")
# → [WARN] app : process_complete : total=42 : run_id=20260318_153012_001
```

### 14-2. Trace Identifiers

Include trace identifiers in logs for resident apps or multiple-connection systems:

```python
# ✅ Recommended: include session or connection ID
logger.info(f"chat_client : message_received : session_id={session_id}")
logger.error(f"chat_client : connect failed : url={url} : {e}")

# ❌ Insufficient: cannot trace which connection
logger.error(f"connect failed : {e}")
```

### 14-3. Error Logging to logs/ (Minimal but Sufficient)

On error, emit structured context to `logs/` before raising — enough for agent diagnosis without reading `runtime/` or `All-Logs/`:

```python
# ✅ Emit error type, location, and preceding ops (max 5)
logger.error(f"chat_client : connect_failed : url={url} : {type(e).__name__}")
logger.error(f"chat_client : preceding_ops={','.join(recent_ops[-5:])}")
raise
```

### 14-4. Log Quality

- Include "what was being done when it failed" in error logs
- Do not over-log successes; **prioritize state transition logs**
- When the same failure repeats at high frequency, consider log suppression (document with `@AI-Note:`)
- Do not include secrets (tokens, passwords) in logs (per GLOBAL_RULES Section 8)

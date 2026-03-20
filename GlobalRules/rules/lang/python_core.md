# Python-Specific Rules — Core

> Read on startup for Python projects.
> For code examples, see lang/python_examples.md.

## Prerequisites

- Python 3.10 or higher
- Source file encoding must be UTF-8 and should not be changed in principle
- Standard tooling:

| Tool | Purpose |
|---|---|
| `ruff` | Lint and format (replaces Black + flake8) |
| `mypy` | Static type checking (recommended) |
| `pytest` | Testing |

## Naming Rules

| Target | Rule | Example |
|---|---|---|
| Variable / Function | `snake_case` | `user_name`, `get_config()` |
| Class | `PascalCase` | `ChatClient`, `UniversalPost` |
| Constant | `SCREAMING_SNAKE_CASE` | `MAX_RETRY`, `DEFAULT_TIMEOUT` |
| Module / File | `snake_case` | `chat_client.py` |
| Private | Leading underscore | `_internal_state` |
| Type alias | `PascalCase` | `UserId = int` |

Prohibited: single-char variables (except loop `i`,`j`), meaningless names (`tmp`,`data2`), abbreviations (`usr`→`user`)

## Type Hints

- All functions should have type hints
- Exception:
  - small-scale scripts
  - quick prototypes
- Use Python 3.10+ syntax — no `Optional` / `Union` / `List` / `Dict`

```python
def get_user(user_id: int) -> str | None: ...
x: list[int] = []
```

- Use `TypedDict` for inter-module dict data
- Use `@dataclass` for internal structures with methods
- `Any` is prohibited — use `TypeVar` or `Protocol`; if unavoidable, add `@AI-Note:`

## Import Order

```python
# Group 1: Standard library
import os
from pathlib import Path

# Group 2: Third-party
import requests

# Group 3: Internal
from .chat_client import ChatClient
```

Prohibited: `from module import *` · unused imports · circular imports

## Exception Handling

```python
# ❌ Prohibited — swallowing
try:
    connect()
except Exception:
    pass

# ✅ Recommended — specific exception, log, re-raise
try:
    connect()
except ConnectionError as e:
    logger.error(f"chat_client : connect failed : {e}")
    raise
```

## Zero Trust — External Data

```python
# ❌ Prohibited
eval(user_input)
subprocess.run(user_input, shell=True)

# ✅ Sanitize before use
sanitized = sanitize(user_input)
```

## Async Rules

- Prefer `async` for I/O-bound operations
- Do not run heavy CPU work directly inside `async` functions
- Always define start, stop, and exception behavior for background tasks
- Never swallow `CancelledError` — always re-raise

## State Management

- No global variables for state
- Aggregate state in `@dataclass` / classes / Context objects
- Do not initialize state during module import

## File Operations

```python
# ✅ Always specify encoding
with open(path, encoding="utf-8") as f: ...

# ❌ Prohibited — OS default dependent
with open(path) as f: ...
```

## Path Operations

```python
# ✅ Use pathlib
from pathlib import Path
config_path = Path(__file__).parent / "config" / "app.toml"

# ❌ Hardcoded paths prohibited
config_path = "C:\\Users\\user\\project\\config\\app.toml"
```

## Module Responsibility

- One file, one responsibility
- Prohibited names: `utils.py`, `common.py`, `helper.py`, `misc.py`
- Dependency direction: `UI / Adapter → Service → Core`

## AI-Generated Code Checklist

- [ ] Type hints on all functions?
- [ ] `Any` avoided?
- [ ] No `import *`?
- [ ] Exceptions not swallowed?
- [ ] No `print` for logging?
- [ ] No hardcoded values?
- [ ] `Libraries` field in header updated?
- [ ] Plan doc and license check for any new library?
- [ ] `@What:` / `@Why:` assessed for each function?
- [ ] Tests written and passing?
- [ ] External input sanitized / escaped?
- [ ] No `eval()` with external input?

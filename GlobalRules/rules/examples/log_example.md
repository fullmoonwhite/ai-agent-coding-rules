# Log Output Examples (Section 8 Detail)

> Reference when writing log output.

## Format

```
[INFO]  module_name : message
[WARN]  module_name : message
[ERROR] module_name : message : {error}
```

## What to Log

- Process start / end
- Errors (always)
- Reconnection
- External communication
- Important state changes
- Security clearance evaluation results

## Python Implementation

```python
import logging

# Get per-module logger — __name__ maps filename to log output
logger = logging.getLogger(__name__)

# Examples
logger.info("chat_client : process_start")
logger.info("chat_client : connected : url=wss://irc-ws.chat.twitch.tv")
logger.warning("chat_client : reconnecting : attempt=2")
logger.error(f"chat_client : connect failed : url={url} : {e}")
```

## File Output Strategy (Four-Folder System)

Each folder keeps the **latest file at root** and **past files under `History/`**.

```
logs/
  ├── {app_name}.log
  └── History/{app_name}_{timestamp}.log

runtime/
  ├── {app_name}.log
  └── History/{app_name}_{timestamp}.log

AI-Logs/
  ├── {app_name}.log
  └── History/{app_name}_{timestamp}.log

All-Logs/
  ├── {app_name}.log
  └── History/{app_name}_{timestamp}.log
```

| Folder | Reader | Level | Content |
|---|---|---|---|
| `logs/` | AI agent — primary | WARNING+ | OK/FAIL + count + run_id; on error: type, location, last 5 ops |
| `runtime/` | AI agent — detail | INFO+ | Full latest run, stack traces |
| `AI-Logs/` | AI (Context) | - | Work process, reasoning, and handoff (AI thinking log for context continuity) |
| `All-Logs/` | Human post-mortem | DEBUG+ | All actions, inputs/outputs, decisions |

**AI reading order: `logs/` → `AI-Logs/` → `runtime/` → `History/` →`All-Logs/`**

### run_id — Required

Generate one `run_id` per execution and attach to every log line.

```python
from datetime import datetime, timezone

def generate_run_id() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_001")
```

### logs/ Content Policy

```
# Normal completion (WARNING level to ensure it reaches logs/)
[WARN] app : process_complete : total=42 : success=42 : failed=0 : run_id=20260318_153012_001

# On error — type, location, last 5 ops only (no full traceback)
[ERROR] app : file_write_failed : file=output.txt : run_id=20260318_153012_001
[ERROR] app : preceding_ops=mkdir,file_read,validate,open,write
[ERROR] app : error=FileNotFoundError : line=42 in write_output
```

### Python Implementation

```python
import logging
from datetime import datetime, timezone
from pathlib import Path


def setup_logger(app_name: str = "app", run_id: str | None = None) -> logging.Logger:
    # @What: Sets up 8-handler logger for four-folder structure
    # @Why:  Separates AI-readable minimal logs from human full logs
    if run_id is None:
        run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_001")

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")

    for folder in ["logs/History", "runtime/History" ,"AI-Logs/History", "All-Logs/History"]:
        Path(folder).mkdir(parents=True, exist_ok=True)

    minimal_fmt = logging.Formatter(f'[%(levelname)s] %(name)s : %(message)s : run_id={run_id}')
    detail_fmt  = logging.Formatter(f'[%(levelname)s] %(asctime)s %(name)s : %(message)s : run_id={run_id}')

    handlers: list[tuple[str, str, int, logging.Formatter]] = [
        # (path, mode, level, formatter)
        (f"logs/{app_name}.log",                        "w", logging.WARNING, minimal_fmt),
        (f"logs/History/{app_name}_{timestamp}.log",    "a", logging.WARNING, minimal_fmt),
        (f"runtime/{app_name}.log",                     "w", logging.INFO,    detail_fmt),
        (f"runtime/History/{app_name}_{timestamp}.log", "a", logging.INFO,    detail_fmt),
        (f"AI-Logs/{app_name}.log",                     "w", logging.INFO,    detail_fmt),
        (f"AI-Logs/History/{app_name}_{timestamp}.log", "a", logging.INFO,    detail_fmt),
        (f"All-Logs/{app_name}.log",                    "w", logging.DEBUG,   detail_fmt),
        (f"All-Logs/History/{app_name}_{timestamp}.log","a", logging.DEBUG,   detail_fmt),
    ]

    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)

    for path, mode, level, fmt in handlers:
        handler = logging.FileHandler(path, mode=mode, encoding="utf-8")
        handler.setLevel(level)
        handler.setFormatter(fmt)
        logger.addHandler(handler)

    return logger
```

### Logging Completion and Errors

```python
# ✅ Normal completion — WARNING reaches logs/
logger.warning(f"app : process_complete : total=42 : success=42 : failed=0")

# ✅ On error — emit minimal context to logs/ before raising
logger.error(f"app : connect_failed : url={url} : {type(e).__name__}")
logger.error(f"app : preceding_ops={','.join(recent_ops[-5:])}")
raise
```

## For Resident Apps / Multiple Connections

Include session or connection ID for traceability:

```python
# ✅ With trace ID
logger.info(f"chat_client : message_received : session_id={session_id}")
logger.error(f"chat_client : connect failed : url={url} : {e}")

# ❌ Without trace ID — cannot identify which connection
logger.error(f"connect failed : {e}")
```

## Prohibited

```python
# ❌ No print for logging
print("connected")

# ❌ No secrets in logs
logger.info(f"token={token}")    # Never
logger.info(f"password={pwd}")   # Never
```

## Log Quality

- Include "what was being done when it failed" in error logs
- Prioritize state transition logs over success logs
- When the same failure repeats at high frequency, consider log suppression
  (document with `@AI-Note:`)

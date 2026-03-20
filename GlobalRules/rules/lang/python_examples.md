# Python Code Examples

> Reference for Python-specific code patterns.

## TypedDict

```python
from typing import TypedDict

class UserConfig(TypedDict):
    name: str
    timeout: int
    debug: bool

# Optional keys
class PartialConfig(TypedDict, total=False):
    name: str
    timeout: int
```

## Custom Exceptions

```python
class ChatClientError(Exception): ...
class ConnectionError(ChatClientError): ...
class AuthenticationError(ChatClientError): ...
```

## Async Task Management

```python
# ❌ Direct create_task — creates orphaned tasks
asyncio.create_task(some_work())

# ✅ Through a management layer
# @What: Registers and starts a task via management layer
# @Why:  Prevents orphaned and unstoppable tasks
await task_manager.start(some_work())
```

## CancelledError Handling

```python
# ❌ Swallows CancelledError
try:
    await some_work()
except Exception:
    pass

# ✅ Always re-raise CancelledError
try:
    await some_work()
except asyncio.CancelledError:
    raise
except Exception as e:
    logger.error(f"task_manager : task failed : {e}")
```

## State Aggregation

```python
# ❌ Global variable
_connected = False

# ✅ Aggregate in dataclass
# @What: Centrally manages connection state
# @Why:  Prevents race conditions during concurrent ops and reconnection
@dataclass
class ConnectionContext:
    connected: bool = False
    session_id: str | None = None
    retry_count: int = 0
```

## TDD Procedure

```
1. Write the test
2. Run it — confirm it fails intentionally (Red)
3. Implement
4. Confirm test passes (Green)
5. Refactor
```

## Test Examples

```python
def test_parse_emote_tag_returns_correct_span():
    result = parse_emote_tag("425618:0-6")
    assert result == [EmoteSpan(id="425618", start=0, end=6)]

def test_parse_emote_tag_empty_string_returns_empty_list():
    assert parse_emote_tag("") == []
```

- Mock external communication; never rely on live network connections
- File names: `test_<target>.py`
- Function names: `test_<what_is_tested>`

## Virtual Environment

```
python -m venv .venv
.venv\Scripts\activate    # Windows
source .venv/bin/activate # macOS/Linux
```

`.venv` must not be committed to the repository.

## requirements.txt

```
requests==2.31.0
websockets==12.0
```

Always pin exact versions.

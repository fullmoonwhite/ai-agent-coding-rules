# Function Comment Examples (@What / @Why / @AI-Note)

> Reference when writing @What / @Why / @AI-Note comments.

## Prefixes and Purpose

| Prefix | Purpose | Where |
|---|---|---|
| `@What:` | What the process does; language syntax explanation | Before complex or language-specific code |
| `@Why:` | Design rationale; basis for decisions | Before functions or important logic |
| `@AI-Note:` | Agent-specific cautions and constraints | Wherever a modifier needs to know something |

Not required on every line.
Apply to: external calls, complex transforms, retry logic, non-obvious design decisions.
Simple getters and setters do not need them.

---

## Connection / Communication

```python
# @What: Establishes a TCP connection to a WebSocket server
#        Raises on failure and delegates to the caller (swallowing prohibited)
#        Equivalent to connect() / open() in other languages
# @Why:  Connection drops are usually transient; retry is controlled by the caller
# @AI-Note: Timeout must come from config. Hardcoding prohibited
# [F03] connect - Establish WebSocket connection and return session
async def connect(url: str, timeout: int) -> WebSocketClientProtocol:
    ...
# [FEND]
```

## Data Transformation / Normalization

```python
# @What: Normalizes raw dict data into a UniversalPost type
#        Returns default value (not None) when a key is missing
#        Equivalent to map() / transform() in other languages
# @Why:  Eliminates None checks downstream and preserves type consistency
# [F05] normalize - Normalize raw dict into UniversalPost with defaults
def normalize(raw: dict[str, object]) -> UniversalPost:
    ...
# [FEND]
```

## Side Effects (DB / File / Network Write)

```python
# @What: Writes session info to SQLite (modifies external state)
#        Uses INSERT OR REPLACE to ensure idempotency
# @Why:  Tracks startup time and platform per session
# @AI-Note: Assumes WAL mode. Call from outside a transaction. Idempotent.
# [F07] save_session - Write session data to SQLite with INSERT OR REPLACE
def save_session(db: sqlite3.Connection, session: SessionData) -> None:
    ...
# [FEND]
```

## Pure Function (No Side Effects)

```python
# @What: Converts IRC emotes tag string into list of EmoteSpan
#        Example: "425618:0-6" → [EmoteSpan(id="425618", start=0, end=6)]
# @Why:  Allows UI layer to receive emote IDs and position info
# [F09] parse_emote_tag - Parse IRC emote tag string into list of EmoteSpan
def parse_emote_tag(emote_tag: str) -> list[EmoteSpan]:
    ...
# [FEND]
```

## Initialization / Config Loading

```python
# @What: Loads config from TOML file and returns it as AppConfig
#        Returns defaults if file doesn't exist (no exception raised)
# @Why:  Allows default behavior without a config file
# @AI-Note: Pass absolute path. Relative paths are working-directory-dependent
# [F01] load_config - Load TOML config and return AppConfig, with defaults if missing
def load_config(path: Path) -> AppConfig:
    ...
# [FEND]
```

## Error Handling / Retry

```python
# @What: Retries connect up to max_retry times with exponential backoff
#        Equivalent to retry() / withRetry() in other languages
# @Why:  Prevents crashes on transient network drops
# @AI-Note: Max retries and base wait must come from config
#            On exhaustion, raises ConnectionError to caller
# [F03] connect_with_retry - Retry WebSocket connect with exponential backoff
async def connect_with_retry(
    url: str,
    max_retry: int,
    base_wait: float,
) -> WebSocketClientProtocol:
    ...
# [FEND]
```

## Inline Usage

```python
# @What: List comprehension — extracts only elements matching the condition
#        Equivalent to filter() / where() in other languages
active_users = [u for u in users if u.is_active]

# @Why:  Raising the exception allows the caller to handle retry
#        Catching here would break upstream retry logic
# @AI-Note: Timeout value must come from config. Hardcoding prohibited
def connect():
    ...
```

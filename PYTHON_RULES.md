# Python 開発ルール

> GLOBAL_RULES.md を継承する。本ファイルはPython固有のルールを定義する。
> プロジェクト固有の追加ルールは `RULES.md` に記載する。

---

## 0. 前提

- Python 3.10 以上を対象とする
- ソースファイルのエンコーディングは UTF-8 とし、原則変更しない
- PEP 8 に準拠する（以下のルールはPEP 8を具体化・拡張したもの）
- 使用ツールは以下を標準とする（プロジェクトで変更する場合は `RULES.md` に明記）

| ツール | 用途 |
|---|---|
| `ruff` | リント・フォーマット（Black + flake8 の代替） |
| `mypy` | 静的型チェック |
| `pytest` | テスト |

---

## 1. 命名規則

| 対象 | 規則 | 例 |
|---|---|---|
| 変数・関数 | `snake_case` | `user_name`, `get_config()` |
| クラス | `PascalCase` | `ChatClient`, `UniversalPost` |
| 定数 | `SCREAMING_SNAKE_CASE` | `MAX_RETRY`, `DEFAULT_TIMEOUT` |
| モジュール・ファイル | `snake_case` | `chat_client.py`, `stream_monitor.py` |
| プライベート | 先頭アンダースコア | `_internal_state` |
| 型エイリアス | `PascalCase` | `UserId = int`, `PostList = list[Post]` |

### 禁止事項

- 1文字変数（ループカウンタ `i`, `j` は例外）
- 意味のない名前（`tmp`, `data2`, `new_func`）
- 略語（`usr` → `user`、`msg` → `message`）

---

## 2. 型ヒント規則

### 2-1. 基本原則

- すべての関数・メソッドの引数と戻り値に型ヒントを付ける
- 変数も型が不明確な場合は明示する

### 2-2. 型の書き方（Python 3.10以上の記法に統一）

```python
# ✅ Python 3.10以上の記法に統一
def get_user(user_id: int) -> str | None: ...
def process(value: int | str) -> str: ...
x: list[int] = []
y: dict[str, int] = {}
# ❌ Optional / Union / List / Dict 等の旧記法は使わない
```

### 2-3. TypedDict の使い方

モジュール間でやり取りする辞書型データには `TypedDict` を使う

```python
from typing import TypedDict

class UserConfig(TypedDict):
    name: str
    timeout: int
    debug: bool

# オプションキーがある場合
class PartialConfig(TypedDict, total=False):
    name: str
    timeout: int  # なくてもよい
```

### 2-4. dataclass vs TypedDict vs Pydantic の使い分け

| 用途 | 使うもの |
|---|---|
| 内部データ構造（メソッドあり） | `@dataclass` |
| モジュール間通信・JSON変換 | `TypedDict` |
| バリデーションが必要な入力データ | `Pydantic BaseModel` |

### 2-5. Any の禁止

- `Any` の使用を原則禁止する
- 型が不確定な場合は `TypeVar` または `Protocol` を使う
- やむを得ず使う場合は `# @AI-Note:` で理由を明記する

---

## 3. import 規則

### 3-1. グループと順序

以下の順序で記載し、グループ間は1行空ける

```python
# グループ1: 標準ライブラリ
import os
import sys
from pathlib import Path

# グループ2: サードパーティ
import requests
from websockets import WebSocketClientProtocol

# グループ3: 内部モジュール
from .chat_client import ChatClient
from .config import AppConfig
```

### 3-2. 禁止事項

```python
# ❌ ワイルドカードインポート禁止
from module import *

# ❌ 未使用インポート禁止
import os  # 使っていない

# ❌ 循環インポート禁止（設計を見直す）
```

---

## 4. 関数コメントテンプレート

GLOBAL_RULES のコメント体系（`@What:` / `@Why:` / `@AI-Note:`）を Python で具体的に適用する。

すべての行にコメントを書く必要はない。以下のパターンで「迷いやすい・複雑・重要な」関数に優先して記載する。

---

### 4-1. 接続・通信系

```python
# @What: WebSocketサーバーへのTCP接続を確立する
#        失敗時は例外を投げて呼び出し元に委ねる（握りつぶし禁止）
#        他言語の connect() / open() に相当
# @Why:  接続断が一時的なケースが多いためリトライは呼び出し元で制御する
# @AI-Note: タイムアウト値は設定ファイルから取得すること。ハードコーディング禁止
# [F03] connect - WebSocket接続を確立してセッションを返す
async def connect(url: str, timeout: int) -> WebSocketClientProtocol:
    ...
# [FEND]
```

---

### 4-2. データ変換・正規化系

```python
# @What: 辞書形式の生データを UniversalPost 型に正規化する
#        キーが存在しない場合は None ではなくデフォルト値を返す
#        他言語の map() / transform() に相当
# @Why:  下流の処理で None チェックを不要にし、型の一貫性を保つため
# [F05] normalize - 生dictをデフォルト値付きでUniversalPostに正規化する
def normalize(raw: dict[str, object]) -> UniversalPost:
    ...
# [FEND]
```

---

### 4-3. 副作用あり（DB・ファイル・ネットワーク書き込み）

```python
# @What: SQLite にセッション情報を書き込む（外部状態を変更する）
#        INSERT OR REPLACE で冪等性を確保している
# @Why:  起動時刻とプラットフォームをセッション単位で追跡するため
# @AI-Note: WALモード前提。トランザクション外から呼ぶこと
#            冪等性あり（何度呼んでも同じ結果になる）
# [F07] save_session - セッション情報をSQLiteにINSERT OR REPLACEで保存する
def save_session(db: sqlite3.Connection, session: SessionData) -> None:
    ...
# [FEND]
```

---

### 4-4. 純粋関数（入力→出力のみ・副作用なし）

```python
# @What: IRC の emotes タグ文字列を EmoteSpan のリストに変換する
#        例: "425618:0-6" → [EmoteSpan(id="425618", start=0, end=6)]
# @Why:  UI層がemote IDと位置情報を受け取れるようにするため
# [F09] parse_emote_tag - IRCのemoteタグ文字列をEmoteSpanリストに変換する
def parse_emote_tag(emote_tag: str) -> list[EmoteSpan]:
    ...
# [FEND]
```

---

### 4-5. 初期化・設定読み込み系

```python
# @What: TOML ファイルから設定を読み込み AppConfig 型で返す
#        ファイルが存在しない場合はデフォルト値を返す（例外を投げない）
#        他言語の loadConfig() / initialize() に相当
# @Why:  設定ファイルがなくてもデフォルト動作できるようにするため
# @AI-Note: パスは絶対パスで渡すこと。相対パスは実行場所依存になる
# [F01] load_config - TOMLから設定を読み込みAppConfigで返す（ファイルなしはデフォルト）
def load_config(path: Path) -> AppConfig:
    ...
# [FEND]
```

---

### 4-6. エラーハンドリング・リトライ系

```python
# @What: 接続処理を最大 max_retry 回リトライする
#        失敗のたびに待機時間を指数的に増やす（指数バックオフ）
#        他言語の retry() / withRetry() に相当
# @Why:  一時的なネットワーク切断でクラッシュしないようにするため
# @AI-Note: 最大リトライ数・初期待機時間は設定値から取得すること
#            全リトライ失敗時は ConnectionError を投げて呼び出し元に委ねる
# [F03] connect_with_retry - 指数バックオフで最大max_retry回リトライして接続する
async def connect_with_retry(
    url: str,
    max_retry: int,
    base_wait: float,
) -> WebSocketClientProtocol:
    ...
# [FEND]
```

---

## 5. 例外処理規則

### 5-1. 基本原則

```python
# ❌ 禁止：例外を握りつぶす
try:
    connect()
except Exception:
    pass

# ❌ 禁止：素のExceptionをキャッチする（やむを得ない場合は @AI-Note で理由を）
try:
    connect()
except Exception as e:
    log(e)

# ✅ 推奨：具体的な例外をキャッチしてログ出力・再送出
try:
    connect()
except ConnectionError as e:
    logger.error(f"[ERROR] chat_client : connect failed : {e}")
    raise
```

### 5-2. カスタム例外

プロジェクト固有のエラーはカスタム例外クラスを定義する

```python
# @What: このモジュール固有の基底例外クラス
#        他の例外と区別しやすくするため専用の基底を設ける
class ChatClientError(Exception): ...
class ConnectionError(ChatClientError): ...
class AuthenticationError(ChatClientError): ...
```

---

## 5-3. 外部データの扱い（ゼロトラスト） `[全規模]`

- 外部入力（HTTP・WebSocket・ファイル・ユーザー入力）はすべて非信頼として扱う
- LLMプロンプトに渡す場合は特にサニタイズを徹底する（プロンプトインジェクション対策）
- `eval()` / `exec()` に外部入力を渡すことを禁止する

```python
# ❌ 禁止
eval(user_input)
subprocess.run(user_input, shell=True)

# ✅ 推奨：サニタイズしてから使う
sanitized = sanitize(user_input)
```

---

## 6. ログ出力規則

GLOBAL_RULES のログ形式をPythonで実装する

```python
import logging

# @What: モジュール単位のロガーを取得する
#        __name__ を使うことでファイル名がそのままログ出力に使われる
logger = logging.getLogger(__name__)

# 形式（run_idはsetup_logger内でフォーマットに埋め込む）
logger.info("chat_client : process_start")
logger.warning("chat_client : reconnecting")
logger.error(f"chat_client : connect failed : {e}")
```

### 3フォルダ出力ポリシー

| フォルダ | 内容 | レベル閾値 |
|---|---|---|
| `logs/` | 最小限（AIエージェント最優先読み取り・上書き） | WARNING以上 |
| `runtime/` | 詳細（AIエージェント必要時読み取り・上書き） | INFO以上 |
| `All-Logs/` | 全行動（人間の事後確認専用・上書き） | DEBUG以上 |

各フォルダは **ルートに最新ファイル、`History/` に過去ファイル** を置く。

- AIの読み取り順序: `logs/` → `runtime/` → `History/` → `All-Logs/`（原則読まない）
- `setup_logger()` の実装は `examples/log_example.md` を参照

### 禁止事項

```python
# ❌ print によるログ出力禁止（デバッグ用途でも残さない）
print("connected")

# ❌ ログに機密情報を含めない
logger.info(f"token={token}")  # NG
```

---

## 7. 仮想環境・依存管理

### 7-1. 仮想環境

```
# 作成
python -m venv .venv

# 有効化（Windows）
.venv\Scripts\activate
```

- `.venv` はリポジトリに含めない（`.gitignore` に追加）

### 7-2. 依存ファイル

- バージョンは固定する（GLOBAL_RULES セクション18-3 に従う）

```
# requirements.txt
requests==2.31.0
websockets==12.0
```

- ライブラリを追加する場合は GLOBAL_RULES セクション18 の手順に従う

---

## 8. AI生成コードの検証チェックリスト

Pythonコードを生成・変更した後に以下を確認する

- [ ] すべての関数に型ヒントが付いているか
- [ ] `Any` を使っていないか（使う場合は `@AI-Note:` で理由を明記）
- [ ] `import *` を使っていないか
- [ ] 例外を握りつぶしていないか
- [ ] `print` をログ代わりに使っていないか
- [ ] ハードコーディングされた値がないか
- [ ] ヘッダーコメントの `Libraries` フィールドは更新したか
- [ ] 新しいライブラリを追加した場合、計画書とライセンス確認を行ったか
- [ ] 関数に `@What:` / `@Why:` が必要か判断したか
- [ ] テストコードを書いたか・実行して通ったか
- [ ] 外部入力をサニタイズ・エスケープしているか（ゼロトラスト原則）
- [ ] `eval()` 系関数に外部入力を渡していないか

---

## 9. async / タスク管理規則

StreamHubやAITuberCoreのようなWebSocket・常駐・イベント駆動型アプリでは特に重要。

### 9-1. 基本原則

- I/O待ちが発生する処理（WebSocket・HTTP・ファイル監視等）は `async` を優先する
- 重いCPU処理は `async` 関数内で直接実行せず、別スレッドまたは別プロセスへ逃がす
- 非同期関数名に `async_` プレフィックスは付けない（`async def` で判別できるため）

### 9-2. タスク管理

- `asyncio.create_task()` を直接多用しない
- バックグラウンドタスクは TaskManager などの管理層を通して起動・停止する
- タスクは必ず **開始・停止・例外時** の扱いを定義する
- `cancel()` される前提で実装し、`CancelledError` を握りつぶさない

```python
# ❌ asyncio.create_task() 直接呼び出し禁止（孤立タスクを生む）
# ✅ 管理層を通して起動する
# @What: タスクを管理層に登録して起動する / @Why: 孤立・停止不能タスクを防ぐため
await task_manager.start(some_work())
```

### 9-3. 例外処理

```python
# ❌ 禁止：CancelledError を握りつぶす
try:
    await some_work()
except Exception:
    pass  # CancelledError も握りつぶされる

# ✅ 推奨：CancelledError を再送出する
try:
    await some_work()
except asyncio.CancelledError:
    raise  # 必ず再送出
except Exception as e:
    logger.error(f"task_manager : task failed : {e}")
```

---

## 10. モジュール責務規則

### 10-1. ファイル責務の原則

- 1ファイル1責務を原則とする
- 以下のような責務が曖昧なファイル名を禁止する

```
# ❌ 禁止
utils.py
common.py
helper.py
misc.py

# ✅ 推奨（責務が明確な名前）
emote_parser.py
session_store.py
connection_manager.py
```

### 10-2. 依存方向の原則

- 依存方向は原則として以下に従う

```
UI / Adapter → Service → Core
```

- 循環参照が発生した場合は構造を見直す（`@AI-Note:` で理由を残した上で例外を許可する場合のみ）
- 具体的なディレクトリ構成はプロジェクトの `RULES.md` で定義する

---

## 11. 状態管理規則

AIが簡単に動かすためにグローバル変数へ逃げるパターンを防ぐ。
常駐アプリ・再接続あり・並列処理があるシステムでは競合・再現性問題に直結する。

- グローバル変数で状態を保持しない
- 状態は `@dataclass` / クラス / Context オブジェクトに集約する
- 接続状態・セッション状態・設定キャッシュの所有者を明確にする
- 書き換え可能な共有状態は1か所に閉じ込める
- モジュール import 時に状態を初期化しない

```python
# ❌ グローバル変数で状態を持つのは禁止
# ✅ dataclass に集約する
# @What: 接続状態を一元管理 / @Why: 並列処理・再接続時の競合を防ぐため
@dataclass
class ConnectionContext:
    connected: bool = False
    session_id: str | None = None
    retry_count: int = 0
```

---

## 12. テスト規則

### 12-1. テストを書く基準

- 新規モジュール追加時は最低1件以上のテストを追加する
- 以下の処理は **必ず** テストを書く
  - 変換処理・正規化処理・パーサー
  - 純粋関数（正常系・境界値・異常系）
- 不具合修正時は **再発防止テストを先に追加** してから修正する

### 12-2. TDD手順（推奨）

```
1. テストコードを書く
2. テストを実行して意図的に失敗することを確認する（Red）
3. 実装する
4. テストが通ることを確認する（Green）
5. リファクタリングする
```

- テスト未実行状態でタスクを完了とみなさない
- `pytest` で実行・すべてのテストがパスしてから完了とする

### 12-3. テストの書き方

- 外部通信はモック化し、ネットワーク実接続を前提にしない
- テストファイル名は `test_対象ファイル名.py` に統一する
- テスト関数名は `test_何をテストするか` で意図を明確にする

```python
# ✅ 推奨
def test_parse_emote_tag_returns_correct_span():
    result = parse_emote_tag("425618:0-6")
    assert result == [EmoteSpan(id="425618", start=0, end=6)]

def test_parse_emote_tag_empty_string_returns_empty_list():
    assert parse_emote_tag("") == []
```

---

## 13. コメント適用規則

`@What:` / `@Why:` / `@AI-Note:` をどこに書くかの判断基準。

### 13-1. @What と @Why を書く対象

以下のいずれかに当てはまる関数に付ける

- 外部通信を行う（WebSocket・HTTP・DB・ファイル）
- 変換・正規化処理で変換規則が分かりにくい
- リトライ・例外制御を含む
- 一見して意図が読み取りにくいロジック

すべての関数に書く必要はない。シンプルな getter / setter には不要。

### 13-2. @AI-Note を書く対象

- AIが誤解しやすい制約がある場合のみ付ける
- 「ここをこう変えると壊れる」という注意点がある箇所

```python
# ✅ @What / @Why が必要な例（外部通信・リトライあり）
# @What: IRC WebSocket に接続してメッセージを受信するループを開始する
# @Why:  接続断を検知したらリトライループに戻るため、例外を外に出さない
async def start_receive_loop(): ...

# ✅ @What / @Why が不要な例（意図が自明）
def get_username(user: User) -> str:
    return user.name
```

---

## 14. ログ詳細規則

GLOBAL_RULES セクション8の Python 向け補足。

### 14-0. 3フォルダ構造

```
logs/
  ├── {app_name}.log               ← 最小限。AIエージェント最優先読み取り。実行ごと上書き。
  └── History/{app_name}_{timestamp}.log

runtime/
  ├── {app_name}.log               ← 詳細。AIエージェント必要時読み取り。実行ごと上書き。
  └── History/{app_name}_{timestamp}.log

All-Logs/
  ├── {app_name}.log               ← 全行動。人間専用。実行ごと上書き。
  └── History/{app_name}_{timestamp}.log
```

- `logs/`     : WARNING以上（最小限）
- `runtime/`  : INFO以上（詳細）
- `All-Logs/` : DEBUG以上（全行動）
- AIの読み取り順序: `logs/` → `runtime/` → `History/` → `All-Logs/`（原則読まない）
- `setup_logger()` の実装は `examples/log_example.md` を参照

### 14-1. run_id の付与

すべてのログに `run_id` を付与する。`setup_logger()` でフォーマットに埋め込むため、呼び出し側は意識不要。

```python
# run_id はsetup_logger内で自動付与される
# 形式: YYYYMMDD_HHMMSS_001
logger.warning("app : process_complete : total=42")
# → [WARN] app : process_complete : total=42 : run_id=20260318_153012_001
```

### 14-2. 追跡子の付与

常駐アプリ・複数接続を扱う場合は追跡子をログに含める

```python
# ✅ 推奨：セッションIDや接続IDを含める
logger.info(f"chat_client : message_received : session_id={session_id}")
logger.error(f"chat_client : connect failed : url={url} : {e}")

# ❌ 不足：何の接続か追跡できない
logger.error(f"connect failed : {e}")
```

### 14-3. エラー時の logs/ への最小出力

エラー発生時は `logs/` に最小限の診断情報をWARNING以上で出力してからraiseする。エージェントが `runtime/` を読まずに原因を特定できる粒度にすること。

```python
# ✅ エラー種別・発生箇所・直前操作（最大5件）を出力
logger.error(f"chat_client : connect_failed : url={url} : {type(e).__name__}")
logger.error(f"chat_client : preceding_ops={','.join(recent_ops[-5:])}")
raise
```

### 14-4. ログの品質

- 例外ログには「何をしていた時に失敗したか」を含める
- 成功ログを増やしすぎず、**状態遷移ログを重視する**
- 同じ失敗を高頻度で繰り返す場合はログ抑制を検討する（`@AI-Note:` で明記）
- ログに機密情報（トークン・パスワード）を含めない（GLOBAL_RULES セクション8 に従う）

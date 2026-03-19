# ==================================================
# Module / Plugin Name: IndexGenerator
#
# Role:
# プロジェクト内の全コードファイルからヘッダーコメントを解析し、
# 検索用 index.yaml と _index/XX.py.yaml（関数詳細インデックス）を生成する。
# [Fxx]〜[FEND] ブロックの行番号を記録することで、AIエージェントが
# 関数単位の行範囲指定読み込みを行えるようにする。
#
# Function Index:
# [F01] Parse-Header    - ファイルヘッダーのフィールドを解析してハッシュで返す
# [F02] Parse-Functions - [Fxx]/[FEND]ブロックを解析して関数リストを返す
# [F03] Get-FlatYamlPath - 相対パスを_index/XX.py.yamlのフルパスに変換する
# [F04] Main            - 全ファイルをスキャンしてindex.yamlと_index/*.yamlを生成する
#
# Search Tags:
# tooling, index, generator, powershell, yaml, lightweight, function-index
# ==================================================

param(
    [string]$Root     = ".",
    [string]$Out      = "index.yaml",
    [string]$IndexDir = "_index",
    [string[]]$Ext    = @("*.py", "*.ps1", "*.cs", "*.js", "*.ts", "*.java", "*.go", "*.rs")
)

# -------------------------------------------------------
# [F01] Parse-Header - ファイルヘッダーのフィールドを解析してハッシュで返す
# -------------------------------------------------------
function Parse-Header {
    param([string]$FilePath)

    $lines   = Get-Content $FilePath -Encoding UTF8 -ErrorAction SilentlyContinue
    $inBlock = $false
    $block   = @()

    foreach ($line in $lines) {
        $cleanLine = $line -replace "^(\s*(#|//|--|;)\s*)", ""
        if ($cleanLine -match "^={10,}") {
            if ($inBlock) { break }
            $inBlock = $true
            continue
        }
        if ($inBlock) { $block += $cleanLine }
    }

    if (-not $block) { return $null }

    $fields     = @{}
    $currentKey = $null
    $buffer     = @()

    foreach ($line in $block) {
        if ($line -match "^([A-Za-z /]+):(.*)$") {
            if ($currentKey) { $fields[$currentKey] = ($buffer -join " ").Trim() }
            $currentKey = $Matches[1].Trim()
            $buffer     = @($Matches[2].Trim())
        } elseif ($currentKey) {
            $buffer += $line.Trim()
        }
    }
    if ($currentKey) { $fields[$currentKey] = ($buffer -join " ").Trim() }

    return $fields
}
# [FEND]

# -------------------------------------------------------
# [F02] Parse-Functions - [Fxx]/[FEND]ブロックを解析して関数リストを返す
# -------------------------------------------------------
function Parse-Functions {
    param([string]$FilePath)

    $lines = Get-Content $FilePath -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $lines) { return @() }

    $functions   = @()
    $currentFunc = $null
    $lineNum     = 0

    foreach ($line in $lines) {
        $lineNum++
        # コメントプレフィックスを除去（#, //, --, ; に対応）
        $cleanLine = $line -replace "^(\s*(#|//|--|;)\s*)", ""

        # [Fxx] name - description の形式を検出
        # 例: # [F01] connect - WebSocket接続を確立してセッションを返す
        if ($cleanLine -match "^\[(F\d+)\]\s+(\S+)\s+-\s+(.+)$") {
            # 前の関数がFENDなしで終わっていた場合も登録する
            if ($currentFunc) {
                $currentFunc.line_end = $lineNum - 1
                $functions += [PSCustomObject]$currentFunc
            }
            $currentFunc = @{
                id         = $Matches[1]
                name       = $Matches[2].Trim()
                desc       = $Matches[3].Trim()
                line_start = $lineNum
                line_end   = $null
            }
        }
        # [FEND] の検出
        elseif ($cleanLine -match "^\[FEND\]") {
            if ($currentFunc) {
                $currentFunc.line_end = $lineNum
                $functions += [PSCustomObject]$currentFunc
                $currentFunc = $null
            }
        }
    }

    # ファイル末尾でFENDなしだった場合も登録する
    if ($currentFunc) {
        $currentFunc.line_end = $lineNum
        $functions += [PSCustomObject]$currentFunc
    }

    return $functions
}
# [FEND]

# -------------------------------------------------------
# [F03] Get-FlatYamlPath - 相対パスを_index/XX.py.yamlのフルパスに変換する
# -------------------------------------------------------
function Get-FlatYamlPath {
    param([string]$RelPath, [string]$IndexDirFullPath)
    # パス区切り(/ \)を __ に変換してフラット化する
    # 例: plugins/chat_client.py → plugins__chat_client.py.yaml
    $flatName = $RelPath -replace "[/\\]", "__"
    return Join-Path $IndexDirFullPath "$flatName.yaml"
}
# [FEND]

# -------------------------------------------------------
# [F04] Main - 全ファイルをスキャンしてindex.yamlと_index/*.yamlを生成する
# -------------------------------------------------------

# _index/ フォルダを作成（なければ）
$indexDirFullPath = Join-Path (Resolve-Path $Root).Path $IndexDir
if (-not (Test-Path $indexDirFullPath)) {
    New-Item -ItemType Directory -Path $indexDirFullPath | Out-Null
    Write-Host "[INFO] generate_index : created directory -> $IndexDir/"
}

$modules            = @()
$processedYamlPaths = @{}
$functionIndexCount = 0

foreach ($pattern in $Ext) {
    Get-ChildItem -Path $Root -Recurse -Filter $pattern -ErrorAction SilentlyContinue |
    Where-Object {
        # _index/ 自身・git・キャッシュ系フォルダを除外
        $_.FullName -notmatch "\\(\.git|__pycache__|node_modules|\.venv|_index)\\" -and
        $_.FullName -notmatch "/(_index|\.git|__pycache__|node_modules|\.venv)/"
    } |
    ForEach-Object {
        $fields = Parse-Header $_.FullName
        if (-not $fields) { return }

        $relPath     = $_.FullName.Replace((Resolve-Path $Root).Path, "").TrimStart("\", "/")
        $relPathUnix = $relPath -replace "\\", "/"

        # index.yaml エントリを構築
        $entry = @{
            file         = $relPathUnix
            name         = $fields["Module / Plugin Name"]
            role         = $fields["Role"]
            tags         = ($fields["Search Tags"] -split "[,\s]+") | Where-Object { $_ }
            dependencies = ($fields["Dependencies"] -split "[,\s\n]+") | Where-Object { $_ }
        }
        $modules += $entry

        # [Fxx]〜[FEND] ブロックを解析して _index/XX.py.yaml を生成
        $functions = Parse-Functions $_.FullName
        if ($functions.Count -gt 0) {
            $yamlPath = Get-FlatYamlPath -RelPath $relPathUnix -IndexDirFullPath $indexDirFullPath

            $fyaml = @()
            $fyaml += "file: '$($relPathUnix -replace "'", "''")'"
            $fyaml += "generated: '$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")'"
            $fyaml += "functions:"

            foreach ($f in $functions) {
                $safeDesc = $f.desc -replace "'", "''"
                $safeName = $f.name -replace "'", "''"
                $fyaml += "  - id: $($f.id)"
                $fyaml += "    name: '$safeName'"
                $fyaml += "    desc: '$safeDesc'"
                $fyaml += "    line_start: $($f.line_start)"
                $fyaml += "    line_end: $($f.line_end)"
            }

            $fyaml -join "`n" | Set-Content $yamlPath -Encoding UTF8
            $processedYamlPaths[$yamlPath] = $true
            $functionIndexCount += $functions.Count
        }
    }
}

# _index/ に存在するが今回処理しなかった（削除・除外されたファイルに対応する）yamlを削除
$staleCount = 0
Get-ChildItem -Path $indexDirFullPath -Filter "*.yaml" -ErrorAction SilentlyContinue |
ForEach-Object {
    if (-not $processedYamlPaths.ContainsKey($_.FullName)) {
        Remove-Item $_.FullName -Force
        Write-Host "[INFO] generate_index : removed stale -> $($_.Name)"
        $staleCount++
    }
}

# index.yaml を生成（既存フォーマットを維持）
$yaml = @()
$yaml += "generated: '$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")'"
$yaml += "root: '$((Resolve-Path $Root).Path -replace "\\", "/")'"
$yaml += "count: $($modules.Count)"
$yaml += "modules:"

foreach ($m in $modules) {
    $yaml += "  - file: $($m.file)"
    $safeName = if ($m.name) { $m.name -replace "'", "''" } else { "" }
    $safeRole = if ($m.role) { $m.role -replace "'", "''" } else { "" }
    $yaml += "    name: '$safeName'"
    $yaml += "    role: '$safeRole'"
    if ($m.tags)         { $yaml += "    tags: [$($m.tags -join ', ')]" }
    if ($m.dependencies) { $yaml += "    dependencies: [$($m.dependencies -join ', ')]" }
}

$yaml -join "`n" | Set-Content $Out -Encoding UTF8

Write-Host "[INFO] generate_index : $($modules.Count) modules -> $Out"
Write-Host "[INFO] generate_index : $($processedYamlPaths.Count) files / $functionIndexCount functions -> $IndexDir/"
if ($staleCount -gt 0) {
    Write-Host "[INFO] generate_index : $staleCount stale index(es) removed"
}
# [FEND]

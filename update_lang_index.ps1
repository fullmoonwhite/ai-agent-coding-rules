# ==================================================
# Module / Plugin Name: LangIndexUpdater
#
# Role:
# rules/lang/ フォルダを走査し、XX_core.md と XX_examples.md の両方が存在する言語を検出する。
# 未登録の言語を CORE.md の Reference Guide テーブルと
# GLOBAL_RULES.md / GLOBAL_RULES_EN.md の Section 12-1 テーブルに自動追記する。
# generate_index.ps1 の -RulesDir オプションと同等の処理を単独スクリプトとして提供する。
#
# Function Index:
# [F01] Get-DetectedLangs          - lang/フォルダからペア済み言語を検出してリストで返す
# [F02] Update-CoreMdRefGuide      - CORE.mdのReference Guideテーブルに未登録言語を追記する
# [F03] Update-GlobalRulesLangTable - GLOBAL_RULES*.mdのSection 12-1テーブルに未登録言語を追記する
# [F04] Main                       - 引数検証・各関数の呼び出し・結果サマリー出力
#
# Search Tags:
# tooling, lang, index, updater, powershell, CORE.md, GLOBAL_RULES
# ==================================================

param(
    # GlobalRules のルートフォルダを指定する
    # 例: .\update_lang_index.ps1 -RulesDir "I:\.agents\GlobalRules"
    # 省略時はスクリプト自身のフォルダをルートとみなす
    [string]$RulesDir = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)

# -------------------------------------------------------
# [F01] Get-DetectedLangs - lang/フォルダからペア済み言語を検出してリストで返す
# -------------------------------------------------------
function Get-DetectedLangs {
    param([string]$LangDir)

    # 既知の言語キー→表示名・RULESファイル名のマッピング
    # @AI-Note: 未登録キーはTitleCaseにフォールバックする
    $langNameMap = @{
        "python"     = @{ display = "Python";     rules = "PYTHON_RULES.md" }
        "java"       = @{ display = "Java";       rules = "JAVA_RULES.md" }
        "typescript" = @{ display = "TypeScript"; rules = "TYPESCRIPT_RULES.md" }
        "javascript" = @{ display = "JavaScript"; rules = "JAVASCRIPT_RULES.md" }
        "csharp"     = @{ display = "C#";         rules = "CSHARP_RULES.md" }
        "go"         = @{ display = "Go";         rules = "GO_RULES.md" }
        "rust"       = @{ display = "Rust";       rules = "RUST_RULES.md" }
        "kotlin"     = @{ display = "Kotlin";     rules = "KOTLIN_RULES.md" }
        "swift"      = @{ display = "Swift";      rules = "SWIFT_RULES.md" }
    }

    $detected = @()
    $coreFiles = Get-ChildItem -Path $LangDir -Filter "*_core.md" -ErrorAction SilentlyContinue

    foreach ($f in $coreFiles) {
        $key = $f.BaseName -replace "_core$", ""
        $examplesPath = Join-Path $LangDir "${key}_examples.md"

        # XX_core.md と XX_examples.md の両方が揃っている場合のみ対象にする
        if (Test-Path $examplesPath) {
            $display = if ($langNameMap.ContainsKey($key)) {
                $langNameMap[$key].display
            } else {
                (Get-Culture).TextInfo.ToTitleCase($key)
            }
            $rulesFile = if ($langNameMap.ContainsKey($key)) {
                $langNameMap[$key].rules
            } else {
                "$($key.ToUpper())_RULES.md"
            }
            $detected += [PSCustomObject]@{
                key     = $key
                display = $display
                rules   = $rulesFile
            }
        }
    }

    return $detected
}
# [FEND]

# -------------------------------------------------------
# [F02] Update-CoreMdRefGuide - CORE.mdのReference Guideテーブルに未登録言語を追記する
# -------------------------------------------------------
function Update-CoreMdRefGuide {
    param(
        [string]$CoreMdPath,
        [array]$DetectedLangs
    )

    $lines = Get-Content $CoreMdPath -Encoding UTF8
    $lastLangLineIdx = -1

    # lang/ を含む最後の行インデックスを探す
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "lang/\w+_(core|examples)\.md") {
            $lastLangLineIdx = $i
        }
    }

    if ($lastLangLineIdx -lt 0) {
        Write-Host "[WARN] update_lang_index : CORE.md : Reference Guide lang table not found, skipping"
        return 0
    }

    $newLines      = [System.Collections.Generic.List[string]]$lines
    $insertAt      = $lastLangLineIdx + 1
    $insertedLines = @()

    foreach ($lang in $DetectedLangs) {
        $alreadyCore     = $lines | Where-Object { $_ -match "lang/$($lang.key)_core\.md" }
        $alreadyExamples = $lines | Where-Object { $_ -match "lang/$($lang.key)_examples\.md" }

        if (-not $alreadyCore) {
            $insertedLines += "| $($lang.display)-specific question | ``lang/$($lang.key)_core.md`` |"
        }
        if (-not $alreadyExamples) {
            $insertedLines += "| $($lang.display) code examples | ``lang/$($lang.key)_examples.md`` |"
        }
    }

    if ($insertedLines.Count -gt 0) {
        # 末尾から挿入してインデックスずれを防ぐ
        for ($i = $insertedLines.Count - 1; $i -ge 0; $i--) {
            $newLines.Insert($insertAt, $insertedLines[$i])
        }
        $newLines | Set-Content $CoreMdPath -Encoding UTF8
        Write-Host "[INFO] update_lang_index : CORE.md updated (+$($insertedLines.Count) entries)"
    } else {
        Write-Host "[INFO] update_lang_index : CORE.md : all languages already registered"
    }

    return $insertedLines.Count
}
# [FEND]

# -------------------------------------------------------
# [F03] Update-GlobalRulesLangTable - GLOBAL_RULES*.mdのSection 12-1テーブルに未登録言語を追記する
# -------------------------------------------------------
function Update-GlobalRulesLangTable {
    param(
        [string]$FilePath,
        [array]$DetectedLangs,
        [string]$RulesDir,
        [string]$Label
    )

    $lines = Get-Content $FilePath -Encoding UTF8
    $lastLangRulesIdx = -1

    # XX_RULES.md を含む言語テーブルの最終行インデックスを探す
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "\|\s+[\w#]+\s+\|\s+``\w+_RULES\.md``\s+\|") {
            $lastLangRulesIdx = $i
        }
    }

    if ($lastLangRulesIdx -lt 0) {
        Write-Host "[WARN] update_lang_index : $Label : language table not found, skipping"
        return 0
    }

    $newLines      = [System.Collections.Generic.List[string]]$lines
    $insertAt      = $lastLangRulesIdx + 1
    $insertedLines = @()

    foreach ($lang in $DetectedLangs) {
        # 既に登録済みの場合はスキップ
        $alreadyRules = $lines | Where-Object { $_ -match "``$($lang.rules)``" }
        if ($alreadyRules) { continue }

        # XX_RULES.md が存在する場合のみ追加する（ファイルなしでの登録を防ぐ）
        $rulesFilePath = Join-Path $RulesDir $lang.rules
        if (Test-Path $rulesFilePath) {
            $insertedLines += "| $($lang.display) | ``$($lang.rules)`` |"
        } else {
            Write-Host "[INFO] update_lang_index : $Label : $($lang.rules) not found, skipping entry"
        }
    }

    if ($insertedLines.Count -gt 0) {
        for ($i = $insertedLines.Count - 1; $i -ge 0; $i--) {
            $newLines.Insert($insertAt, $insertedLines[$i])
        }
        $newLines | Set-Content $FilePath -Encoding UTF8
        Write-Host "[INFO] update_lang_index : $Label updated (+$($insertedLines.Count) entries)"
    } else {
        Write-Host "[INFO] update_lang_index : $Label : all languages already registered (or rules files missing)"
    }

    return $insertedLines.Count
}
# [FEND]

# -------------------------------------------------------
# [F04] Main - 引数検証・各関数の呼び出し・結果サマリー出力
# -------------------------------------------------------

if (-not (Test-Path $RulesDir)) {
    Write-Host "[ERROR] update_lang_index : RulesDir not found -> $RulesDir"
    exit 1
}

$langDir = Join-Path $RulesDir "rules\lang"
if (-not (Test-Path $langDir)) {
    Write-Host "[ERROR] update_lang_index : lang/ not found -> $langDir"
    exit 1
}

Write-Host "[INFO] update_lang_index : scanning -> $langDir"

$detectedLangs = Get-DetectedLangs -LangDir $langDir

if ($detectedLangs.Count -eq 0) {
    Write-Host "[INFO] update_lang_index : no complete language pairs found (XX_core.md + XX_examples.md)"
    exit 0
}

Write-Host "[INFO] update_lang_index : detected languages -> $($detectedLangs.key -join ', ')"

$totalAdded = 0

# CORE.md を更新
$coreMdPath = Join-Path $RulesDir "rules\CORE.md"
if (Test-Path $coreMdPath) {
    $totalAdded += Update-CoreMdRefGuide -CoreMdPath $coreMdPath -DetectedLangs $detectedLangs
} else {
    Write-Host "[WARN] update_lang_index : CORE.md not found -> $coreMdPath"
}

# GLOBAL_RULES.md (日本語版) を更新
$globalRulesJaPath = Join-Path $RulesDir "GLOBAL_RULES.md"
if (Test-Path $globalRulesJaPath) {
    $totalAdded += Update-GlobalRulesLangTable -FilePath $globalRulesJaPath -DetectedLangs $detectedLangs -RulesDir $RulesDir -Label "GLOBAL_RULES.md"
} else {
    Write-Host "[WARN] update_lang_index : GLOBAL_RULES.md not found -> $globalRulesJaPath"
}

# GLOBAL_RULES_EN.md (英語版) を更新
$globalRulesEnPath = Join-Path $RulesDir "GLOBAL_RULES_EN.md"
if (Test-Path $globalRulesEnPath) {
    $totalAdded += Update-GlobalRulesLangTable -FilePath $globalRulesEnPath -DetectedLangs $detectedLangs -RulesDir $RulesDir -Label "GLOBAL_RULES_EN.md"
} else {
    Write-Host "[WARN] update_lang_index : GLOBAL_RULES_EN.md not found -> $globalRulesEnPath"
}

Write-Host "[INFO] update_lang_index : done. total $totalAdded entries added."
# [FEND]

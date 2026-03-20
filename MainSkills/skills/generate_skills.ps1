# generate_skills.ps1
# Scans SKILL.md files in the parent folder and generates skill_index.yaml
# Usage: .\generate_skills.bat

param(
    [string]$Root = "$PSScriptRoot",
    [string]$Out = "$PSScriptRoot\skill_index.yaml"
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
    ($Raw -replace "\[\]", "" -split "[,\s]+") | Where-Object { $_ }
}

$skills = @()

Get-ChildItem -Path $Root -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue |
Where-Object { $_.FullName -notmatch "\\(\.git|__pycache__|node_modules)\\" } |
ForEach-Object {
    $fields = Parse-SkillHeader $_.FullName
    if (-not $fields) { return }
    $relPath = $_.FullName.Replace((Resolve-Path $Root).Path, "").TrimStart("\", "/")
    $pri = if ($fields["priority"]) { [int]$fields["priority"] } else { 1 }
    $tgs = if ($fields["tags"]) { $fields["tags"] } else { "" }
    $skills += [ordered]@{
        name        = $fields["name"]
        path        = $relPath -replace "\\", "/"
        description = $fields["description"]
        priority    = $pri
        tags        = @(Parse-Tags $tgs)
    }
}

$skills = $skills | Sort-Object { $_["priority"] }

# YAMLの手動アセンブル（トークン消費を最小化するフォーマット）
$yaml = @()
$yaml += "generated: '$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")'"
$yaml += "skills_root: '$((Resolve-Path $Root).Path -replace "\\", "/")'"
$yaml += "count: $($skills.Count)"
$yaml += "skills:"

foreach ($s in $skills) {
    # コロンなどを含む文字列でYAMLが壊れないようシングルクォートで保護
    $safeName = if ($s.name) { $s.name -replace "'", "''" } else { "" }
    $safeDesc = if ($s.description) { $s.description -replace "'", "''" } else { "" }
    
    $yaml += "  - name: '$safeName'"
    $yaml += "    path: '$($s.path)'"
    $yaml += "    priority: $($s.priority)"
    $yaml += "    description: '$safeDesc'"
    
    if ($s.tags -and $s.tags.Count -gt 0) {
        $yaml += "    tags: [$($s.tags -join ', ')]"
    }
}

$yaml -join "`n" | Set-Content $Out -Encoding UTF8
Write-Host "[INFO] generate_skills : generated $($skills.Count) skills -> $Out"
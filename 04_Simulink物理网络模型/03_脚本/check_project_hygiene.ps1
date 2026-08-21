param(
    [switch]$Strict
)

$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$simulinkRoot = Join-Path $projectRoot '04_Simulink物理网络模型'
$archiveRoot = Join-Path $projectRoot '99_历史归档'
$violations = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Violation([string]$Message) {
    $script:violations.Add($Message)
}

function Add-Warning([string]$Message) {
    $script:warnings.Add($Message)
}

$rootMarkdown = @(Get-ChildItem -LiteralPath $projectRoot -File -Filter '*.md')
$allowedRootMarkdown = @('AGENTS.md', 'PROJECT.md')
$unexpectedRootMarkdown = @($rootMarkdown | Where-Object { $_.Name -notin $allowedRootMarkdown })
if ($unexpectedRootMarkdown.Count -gt 0) {
    Add-Violation ('项目根目录出现额外 Markdown：' + (($unexpectedRootMarkdown.Name | Sort-Object) -join ', '))
}

$contractRoot = Join-Path $simulinkRoot '04_说明'
$contractMarkdown = if (Test-Path -LiteralPath $contractRoot) {
    @(Get-ChildItem -LiteralPath $contractRoot -Recurse -File -Filter '*.md')
} else {
    @()
}
if ($contractMarkdown.Count -gt 5) {
    Add-Violation "活动工程说明超过 5 个 Markdown，当前为 $($contractMarkdown.Count) 个。"
}

$systemModelRoot = Join-Path $simulinkRoot '01_模型\RouteA_GasMixture_Derived'
$systemModels = @(Get-ChildItem -LiteralPath $systemModelRoot -File -Filter '*.slx' -ErrorAction SilentlyContinue)
if ($systemModels.Count -ne 1) {
    Add-Violation "完整系统正式模型应恰好为 1 个，当前为 $($systemModels.Count) 个。"
}

$focusedModelRoot = Join-Path $simulinkRoot '01_模型\RouteA_Cathode_cEGR_Focused'
$focusedModels = @(Get-ChildItem -LiteralPath $focusedModelRoot -File -Filter '*.slx' -ErrorAction SilentlyContinue)
if ($focusedModels.Count -gt 12) {
    Add-Violation "聚焦模型超过 12 个，当前为 $($focusedModels.Count) 个。"
}

$scriptRoot = Join-Path $simulinkRoot '03_脚本'
$runEntries = @(Get-ChildItem -LiteralPath $scriptRoot -Recurse -File -Filter 'run_*.m')
if ($runEntries.Count -gt 10) {
    Add-Violation "活动 run_*.m 入口超过 10 个，当前为 $($runEntries.Count) 个。"
}

$legacyReportRoot = Join-Path $simulinkRoot '05_汇报'
if (Test-Path -LiteralPath $legacyReportRoot) {
    Add-Violation '活动区不应恢复 05_汇报；正式汇报放结果目录，历史汇报放统一归档。'
}

$rootOutputs = Join-Path $projectRoot 'outputs'
if (Test-Path -LiteralPath $rootOutputs) {
    Add-Violation '项目根目录不应出现 outputs；结果必须进入 04_Simulink物理网络模型/02_结果。'
}

$resultRoot = Join-Path $simulinkRoot '02_结果'
$rawResultMat = if (Test-Path -LiteralPath $resultRoot) {
    @(Get-ChildItem -LiteralPath $resultRoot -Recurse -File -Filter '*.mat')
} else {
    @()
}
if ($rawResultMat.Count -gt 100) {
    Add-Warning "活动结果目录已有 $($rawResultMat.Count) 个 MAT；请在里程碑检查其复现价值和摘要覆盖度。"
}

$largeRunFolders = @($rawResultMat | Group-Object DirectoryName | Where-Object Count -gt 50)
foreach ($folder in $largeRunFolders) {
    Add-Warning "单个结果目录含 $($folder.Count) 个 MAT：$($folder.Name)"
}

$generatedExtensions = @('.slxc', '.autosave', '.asv', '.bak')
$generatedFiles = @(Get-ChildItem -LiteralPath $projectRoot -Recurse -File | Where-Object {
    $_.FullName -notlike "$archiveRoot*" -and $_.Extension -in $generatedExtensions
})
if ($generatedFiles.Count -gt 0) {
    Add-Warning "活动区存在 $($generatedFiles.Count) 个可重建缓存/备份文件；允许本地保留，但不要纳入 Git 或作为证据真源。"
}

$activeFiles = @(Get-ChildItem -LiteralPath $projectRoot -Recurse -File | Where-Object {
    $_.FullName -notlike "$archiveRoot*" -and $_.FullName -notlike "$(Join-Path $projectRoot '.git')*"
})

$status = if ($violations.Count -eq 0) { 'PASS' } else { 'FAIL' }
[ordered]@{
    status = $status
    metrics = [ordered]@{
        activeFileCount = $activeFiles.Count
        rootMarkdownCount = $rootMarkdown.Count
        engineeringContractMarkdownCount = $contractMarkdown.Count
        systemModelCount = $systemModels.Count
        focusedModelCount = $focusedModels.Count
        activeRunEntryCount = $runEntries.Count
        rawResultMatCount = $rawResultMat.Count
        generatedFileCount = $generatedFiles.Count
    }
    violations = @($violations)
    warnings = @($warnings)
} | ConvertTo-Json -Depth 4

if ($violations.Count -gt 0) {
    exit 1
}
if ($Strict -and $warnings.Count -gt 0) {
    exit 2
}

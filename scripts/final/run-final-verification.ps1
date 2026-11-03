[CmdletBinding()]
param(
    [switch]$PlanOnly,
    [switch]$IncludeDiscoveryMySql,
    [switch]$IncludeFullFlow,
    [string]$EvidenceDir = (Join-Path $env:TEMP 'campusoverflow-final-evidence')
)

$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))

function Invoke-Step {
    param([string]$Name, [scriptblock]$Action, [string]$Display)
    Write-Host "`n== $Name =="
    Write-Host $Display
    if ($PlanOnly) { return }
    & $Action
    if ($LASTEXITCODE -ne 0) { throw "$Name 失败，退出码 $LASTEXITCODE" }
}

New-Item -ItemType Directory -Force -Path $EvidenceDir | Out-Null
Set-Location $repo

Invoke-Step '后端单元测试' { mvn -B -f backend/pom.xml clean test } 'mvn -B -f backend/pom.xml clean test'
Invoke-Step 'ArchUnit' { mvn -B -f backend/pom.xml test -pl co-bootstrap -Dtest=ArchitectureTest -DfailIfNoTests=false } 'mvn ... ArchitectureTest'
Invoke-Step '完整 verify' { mvn -B -f backend/pom.xml verify -Djacoco.skip=false } 'mvn -B -f backend/pom.xml verify -Djacoco.skip=false'

if ($IncludeDiscoveryMySql) {
    $required = 'DISCOVERY_IT_DB_URL', 'DISCOVERY_IT_DB_USER', 'DISCOVERY_IT_DB_PASSWORD'
    $missing = @($required | Where-Object { [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_)) })
    if ($missing.Count) { throw "Discovery MySQL IT 缺少环境变量名称：$($missing -join ', ')" }
    Invoke-Step 'Discovery MySQL IT（必须 2 项且 0 跳过）' {
        mvn -B -f backend/pom.xml -pl co-discovery/co-discovery-infrastructure -am test -Dtest=DiscoveryMySqlIT -Dsurefire.failIfNoSpecifiedTests=false
    } 'mvn ... -Dtest=DiscoveryMySqlIT（凭据不打印）'
}

if ($IncludeFullFlow) {
    Invoke-Step 'Testcontainers 完整业务流' {
        mvn -B -f backend/pom.xml -pl co-bootstrap -am verify -Dit.test=CampusOverflowFlowIT -DfailIfNoTests=false
    } 'mvn ... -Dit.test=CampusOverflowFlowIT'
}

Push-Location frontend
try {
    Invoke-Step '前端可复现安装' { npm ci --no-audit --no-fund } 'npm ci --no-audit --no-fund'
    Invoke-Step '前端类型检查' { npm run typecheck } 'npm run typecheck'
    Invoke-Step '前端构建' { npm run build } 'npm run build'
    Write-Warning '当前 package.json 没有 lint 脚本；本脚本不会伪造 lint 通过。'
} finally { Pop-Location }

if (-not $PlanOnly) {
    git rev-parse HEAD | Set-Content (Join-Path $EvidenceDir 'commit-sha.txt')
    Get-Date -Format o | Set-Content (Join-Path $EvidenceDir 'finished-at.txt')
}

Write-Host "验证计划完成。证据目录：$EvidenceDir"

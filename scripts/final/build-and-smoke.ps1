[CmdletBinding()]
param(
    [switch]$PlanOnly,
    [switch]$Start,
    [switch]$Observability,
    [string]$ImageTag
)

$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$compose = Join-Path $repo 'deploy\docker-compose.yml'
if (-not $ImageTag) { $ImageTag = (git -C $repo rev-parse --short HEAD) }

function Run([string]$Display, [scriptblock]$Action) {
    Write-Host $Display
    if ($PlanOnly) { return }
    & $Action
    if ($LASTEXITCODE -ne 0) { throw "命令失败：$Display" }
}

Run 'docker info' { docker info *> $null }
Run 'docker compose config --quiet' { docker compose -f $compose config --quiet }
Run "构建 backend:$ImageTag" { docker build -f (Join-Path $repo 'deploy\backend.Dockerfile') -t "campus-overflow-backend:$ImageTag" $repo }
Run "构建 web:$ImageTag" { docker build -f (Join-Path $repo 'deploy\frontend.Dockerfile') -t "campus-overflow-web:$ImageTag" $repo }

if (-not $PlanOnly) {
    $backendUser = docker image inspect "campus-overflow-backend:$ImageTag" --format '{{.Config.User}}'
    $webUser = docker image inspect "campus-overflow-web:$ImageTag" --format '{{.Config.User}}'
    Write-Host "backend runtime user: $backendUser"
    Write-Host "web runtime user: $webUser"
    if ([string]::IsNullOrWhiteSpace($backendUser) -or [string]::IsNullOrWhiteSpace($webUser)) {
        throw '至少一个运行时镜像未声明非 root 用户；不能记录为 Lab8 通过。'
    }
}

if ($Start) {
    $profile = if ($Observability) { @('--profile', 'observability') } else { @() }
    Run '启动 Compose（保留数据卷）' { docker compose -f $compose @profile up -d --build }
    Run '检查容器状态' { docker compose -f $compose ps }
    if (-not $PlanOnly) {
        Invoke-RestMethod 'http://127.0.0.1:8080/actuator/health/readiness' | ConvertTo-Json -Depth 4
        Invoke-WebRequest 'http://127.0.0.1/' -UseBasicParsing | Select-Object StatusCode
    }
}

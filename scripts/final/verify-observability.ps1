[CmdletBinding()]
param(
    [switch]$PlanOnly,
    [uri]$Prometheus = 'http://127.0.0.1:9090',
    [uri]$Grafana = 'http://127.0.0.1:3000'
)

$ErrorActionPreference = 'Stop'
$queries = @(
    'up{job="campus-overflow"}',
    'http_server_requests_seconds_count',
    'jvm_memory_used_bytes',
    'process_cpu_usage',
    'co_outbox_backlog'
)

if ($PlanOnly) {
    Write-Host "将检查 Prometheus targets、5 个指标、告警规则和 Grafana health。"
    $queries | ForEach-Object { Write-Host "metric: $_" }
    exit 0
}

$targets = Invoke-RestMethod "$Prometheus/api/v1/targets"
$active = @($targets.data.activeTargets | Where-Object health -eq 'up')
if (-not $active) { throw 'Prometheus 没有健康 target。' }

foreach ($query in $queries) {
    $uri = "$Prometheus/api/v1/query?query=$([uri]::EscapeDataString($query))"
    $result = Invoke-RestMethod $uri
    $count = @($result.data.result).Count
    [pscustomobject]@{ Query = $query; Series = $count }
    if ($count -eq 0) { Write-Warning "指标暂无真实序列：$query" }
}

$rules = Invoke-RestMethod "$Prometheus/api/v1/rules?type=alert"
if (@($rules.data.groups).Count -eq 0) { throw '没有已加载的 Prometheus 告警规则，不能记录 Lab8 告警通过。' }

$grafanaHealth = Invoke-RestMethod "$Grafana/api/health"
$grafanaHealth | ConvertTo-Json -Depth 4

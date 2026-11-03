[CmdletBinding()]
param(
    [uri]$Uri = 'http://127.0.0.1:8080/actuator/health',
    [ValidateRange(1, 10000)][int]$Requests = 200,
    [ValidateRange(1, 64)][int]$Concurrency = 8,
    [switch]$AllowRemote,
    [string]$Output = (Join-Path $env:TEMP 'campusoverflow-load-result.json')
)

$ErrorActionPreference = 'Stop'
if (-not $AllowRemote -and $Uri.Host -notin @('127.0.0.1', 'localhost')) {
    throw '默认只允许本机地址；远端压测必须显式使用 -AllowRemote 并先获得授权。'
}

$results = 1..$Requests | ForEach-Object -Parallel {
    $watch = [Diagnostics.Stopwatch]::StartNew()
    try {
        $response = Invoke-WebRequest -Uri $using:Uri -UseBasicParsing -TimeoutSec 10
        $ok = $response.StatusCode -ge 200 -and $response.StatusCode -lt 400
        $status = $response.StatusCode
    } catch {
        $ok = $false
        $status = 0
    } finally { $watch.Stop() }
    [pscustomobject]@{ Ok = $ok; Status = $status; Milliseconds = $watch.Elapsed.TotalMilliseconds }
} -ThrottleLimit $Concurrency

$ordered = @($results.Milliseconds | Sort-Object)
function Percentile([double[]]$values, [double]$p) {
    if (-not $values.Count) { return 0 }
    $index = [Math]::Min($values.Count - 1, [Math]::Ceiling($values.Count * $p) - 1)
    return [Math]::Round($values[$index], 2)
}

$summary = [ordered]@{
    uri = $Uri.ToString()
    requests = $Requests
    concurrency = $Concurrency
    success = @($results | Where-Object Ok).Count
    errors = @($results | Where-Object { -not $_.Ok }).Count
    p50_ms = Percentile $ordered 0.50
    p95_ms = Percentile $ordered 0.95
    p99_ms = Percentile $ordered 0.99
    generated_at = (Get-Date -Format o)
}
$summary | ConvertTo-Json | Set-Content -Encoding utf8 $Output
$summary
Write-Host "结果已写入 $Output；提交证据前补充机器、SHA 和测试数据说明。"

[CmdletBinding()]
param(
    [switch]$PlanOnly,
    [uri]$Web = 'http://127.0.0.1/',
    [uri]$Backend = 'http://127.0.0.1:8080'
)

$steps = @(
    '登录测试账号（密码由操作者输入，不出现在录屏或日志）',
    '发布带“演示数据”标记的问题并在列表/详情确认',
    '另一账号回答，提问者采纳',
    '展示回答者声誉账本与排行榜变化',
    '中文搜索命中该问题',
    '展示未读通知、标记已读和顶部计数同步',
    '只清理本次唯一前缀的测试夹具'
)

if (-not $PlanOnly) {
    Invoke-WebRequest $Web -UseBasicParsing | Select-Object StatusCode
    Invoke-RestMethod "$Backend/actuator/health/readiness" | ConvertTo-Json -Depth 4
}

Write-Host '30 秒演示录屏人工步骤：'
$i = 1
foreach ($step in $steps) { Write-Host "$i. $step"; $i++ }
Write-Warning '本脚本只检查可录制性并输出步骤，不生成或伪造录屏。'

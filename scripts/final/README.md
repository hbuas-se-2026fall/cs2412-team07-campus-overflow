# 最终验收脚本使用说明

适用范围：CampusOverflow 老师仓库的 Windows PowerShell 本地验收。脚本不自动修改业务代码、CI、数据卷或系统环境变量，也不会生成伪造的截图、录屏或运行结果。

## 1. 执行前提

1. 在干净的独立 worktree 中固定待验收 SHA，并记录 `git rev-parse HEAD`。
2. JDK 21、Maven、Node.js 20+、npm 和 Docker Desktop/Compose 已可用。
3. A/B 业务已进入共同可测基线，关键路径不再抛出 TODO/`UnsupportedOperationException`。
4. 使用隔离测试数据；禁止将 Discovery IT 指向生产库。
5. 密码、Cookie、令牌、数据库 URL 和 Secrets 不写入命令文本、截图或仓库。

## 2. 先查看计划

```powershell
./scripts/final/run-final-verification.ps1 -PlanOnly
./scripts/final/build-and-smoke.ps1 -PlanOnly -Start -Observability
./scripts/final/verify-observability.ps1 -PlanOnly
./scripts/final/demo-readiness.ps1 -PlanOnly
```

`-PlanOnly` 只输出计划，不能记作测试、镜像、Smoke Test、监控或 E2E 通过。

## 3. 建议验收顺序

### 3.1 代码与测试

```powershell
./scripts/final/run-final-verification.ps1
```

该命令依次运行后端单元测试、ArchUnit、完整 `mvn verify`、`npm ci`、前端 typecheck 和 build。当前 `package.json` 没有 lint 脚本，运行结果不得写成课程 `pnpm lint` 已通过。

### 3.2 Discovery 显式 MySQL IT

只在隔离测试库中设置以下当前 PowerShell 会话变量，实际值不得写入本文：

- `DISCOVERY_IT_DB_URL`
- `DISCOVERY_IT_DB_USER`
- `DISCOVERY_IT_DB_PASSWORD`

```powershell
./scripts/final/run-final-verification.ps1 -IncludeDiscoveryMySql
```

脚本使用 Maven Failsafe 的 `verify -Dit.test=DiscoveryMySqlIT`。验收记录必须明确显示 `DiscoveryMySqlIT` 运行 2 项、失败 0、错误 0、跳过 0；默认环境下整类跳过不算真实数据库验收。

### 3.3 完整业务流

```powershell
./scripts/final/run-final-verification.ps1 -IncludeDiscoveryMySql -IncludeFullFlow
```

仅当仓库实际存在且可运行 `CampusOverflowFlowIT` 时才可将该步写成 E2E 验收。`-DfailIfNoTests=false` 只避免 Maven 在上游模块无指定测试时误报，不能把“没有测试”写成“E2E 通过”。

### 3.4 镜像、Compose 和 Smoke Test

```powershell
./scripts/final/build-and-smoke.ps1
./scripts/final/build-and-smoke.ps1 -Start
./scripts/final/build-and-smoke.ps1 -Start -Observability
```

第一条只构建并核对镜像运行用户；后两条会启动 Compose，保留现有命名卷，不执行 `down -v`。成功记录至少要包含镜像标签、容器健康状态、readiness 和首页 HTTP 状态。

### 3.5 监控、告警与压测

```powershell
./scripts/final/verify-observability.ps1
./scripts/final/run-local-load.ps1 -Requests 200 -Concurrency 8
```

监控验收要求 Prometheus 存在健康 target、5 类查询有真实序列、至少 1 条告警规则，且 Grafana health 可访问。压测默认只允许 localhost；远程目标必须另行获授权并显式使用 `-AllowRemote`。结果必须连同机器、SHA、数据集、并发、持续时间、p50/p95/p99 和错误率归档。

### 3.6 人工演示录屏

```powershell
./scripts/final/demo-readiness.ps1
```

该脚本只检查前后端可访问并输出人工操作顺序。录屏必须由真人在最终共同 SHA 上完成，不显示密码或令牌，并且只清理本次唯一前缀的测试数据。

## 4. 证据归档最小字段

每次真实执行至少记录：老师仓库完整 SHA、本地时间与时区、机器/工具版本、完整命令、退出码、测试数/失败/跳过数以及证据路径。配置文件存在、`-PlanOnly` 输出或历史截图均不能替代本轮真实验收。

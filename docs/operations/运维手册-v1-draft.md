# CampusOverflow 运维手册 v1 草稿

状态：待整体验收。基线：老师仓库 `main@12eef8a`。本手册不包含密码、令牌或线上地址。

## 1. 状态标记

- **配置已核对**：命令与仓库现有配置一致，但不代表完整应用成功运行。
- **历史已验证**：此前在 C 的隔离环境实际通过，需在最终 SHA 重跑。
- **待验**：当前因 A/B 业务阻碍未执行，不得作为成功证据。

## 2. 前置条件

JDK 21、Maven、Node.js 20+、npm、Docker Desktop/Compose。生产或共享环境必须显式提供以下变量，实际值不得写入仓库：

`DB_HOST`、`DB_PORT`、`DB_NAME`、`DB_USER`、`DB_PASSWORD`、`REDIS_HOST`、`REDIS_PORT`、`CO_FIELD_KEY`、`COOKIE_SECURE`、`GRAFANA_PASSWORD`。

Compose 默认暴露 MySQL `3306`、Redis `6379`。若仅本地运行后端并连接此前的 `127.0.0.1:3307` MySQL，应通过会话变量设置 `DB_HOST=127.0.0.1`、`DB_PORT=3307`；不要修改团队默认 Compose 端口。

## 3. 启动

### 3.1 配置预检（配置已核对）

```powershell
./scripts/c-integration-preflight.ps1
docker compose -f deploy/docker-compose.yml config --quiet
```

### 3.2 仅启动中间件（历史已验证，最终 SHA 待复验）

```powershell
docker compose -f deploy/docker-compose.yml up -d mysql redis
docker compose -f deploy/docker-compose.yml ps mysql redis
docker exec co-redis redis-cli ping
```

MySQL 连接通过容器健康状态和后端 readiness 间接验证，避免在命令行暴露密码。

### 3.3 启动完整应用（待验）

```powershell
docker compose -f deploy/docker-compose.yml up -d --build
docker compose -f deploy/docker-compose.yml ps
Invoke-RestMethod http://127.0.0.1:8080/actuator/health/readiness
Invoke-WebRequest http://127.0.0.1/
```

当前 A/B 组合不能编译，因此本节尚未成功执行。

### 3.4 启动监控（待验）

```powershell
docker compose -f deploy/docker-compose.yml --profile observability up -d prometheus grafana
./scripts/final/verify-observability.ps1
```

## 4. 停止

保留数据卷：

```powershell
docker compose -f deploy/docker-compose.yml stop
```

移除容器但保留命名卷：

```powershell
docker compose -f deploy/docker-compose.yml down
```

禁止在常规运维中执行 `down -v`；它会删除项目数据库和 Redis 数据卷。

## 5. 日志与健康检查

```powershell
docker compose -f deploy/docker-compose.yml ps
docker compose -f deploy/docker-compose.yml logs --since 15m backend
docker compose -f deploy/docker-compose.yml logs --since 15m mysql redis web
Invoke-RestMethod http://127.0.0.1:8080/actuator/health
```

日志归档前移除 Cookie、令牌、邮箱、数据库连接串和密钥。

## 6. 回滚（待验）

当前 Compose 使用本地 `build`，尚未配置不可变镜像仓库标签。可审阅的最小回滚流程是：

1. 保留当前数据库卷，不执行清库或 `down -v`。
2. 在独立 worktree 检出最后已验证 SHA，不重置正在开发的工作树。
3. 执行数据库迁移向后兼容检查；Flyway 没有自动降级。
4. 从已验证 SHA 重建镜像并运行 Smoke Test。
5. 若新迁移不可向后兼容，停止回滚并按备份恢复流程处理。

在完成镜像标签、数据库备份和真实演练前，不得声称已具备一键回滚。

## 7. 常见故障

| 现象 | 检查 | 处理 |
| --- | --- | --- |
| Docker daemon 不可用 | `docker info` | 启动 Docker Desktop；不要重复安装 WSL |
| 端口冲突 | `Get-NetTCPConnection -State Listen` | 查明占用项目；不要杀死未知进程 |
| 后端无法连接数据库 | 检查 `DB_HOST/DB_PORT/DB_NAME/DB_USER` 名称和容器健康 | 不在日志或截图中输出密码 |
| Flyway 失败 | 查看 backend 与 MySQL 日志、schema history | 不手工删除 history 或生产表 |
| Redis 会话异常 | `docker exec co-redis redis-cli ping` | 确认 `REDIS_HOST/REDIS_PORT`，不清空其他项目数据 |
| SPA 刷新 404 | 检查 Nginx `try_files ... /index.html` | 验证实际镜像内配置 |
| Prometheus 无 target | 检查 `backend:8080/actuator/prometheus` 和 targets 页面 | 不把配置文件存在写成采集成功 |

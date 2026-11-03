# CampusOverflow 交付证据索引

更新时间：2026-11-03。唯一交付仓库为老师仓库。本索引只登记可追溯证据；配置存在、计划命令和历史验证不能互相替代。

## 已存在的真实证据

| 范围 | 证据 | 能证明什么 | 不能证明什么 |
| --- | --- | --- | --- |
| C 浏览器验证 | `stage9/frontend/01-login.png` 至 `05-unread-count-restored.png` | 真实后端下的登录、中文搜索、通知列表、单条已读和顶部未读数恢复 | 不证明提问、回答、采纳、声誉和完整 E2E |
| C 环境核验 | `stage9/environment/环境核验.md` | 当时执行环境的 Java、Node、Docker 等状态 | 不代表 2026-11-03 当前服务仍在运行 |
| CI 失败归因 | `stage9/actions/PR状态与失败摘要.md`、老师仓库 PR #2/#3 Actions | Actions 能触发；前端构建成功；Identity application 测试失败 | 不代表后端、镜像或部署通过 |
| Discovery 实现记录 | `docs/c/阶段2-*`、`阶段3-*`、`阶段9-*` | C 模块规则、模块测试、显式 MySQL IT 和局部联调过程 | 不代表 Q&A/Reputation 已完成 |
| 故事地图导出 | `docs/backlog/assets/user-story-map-v1.{png,pdf}` | 从当前 Markdown 生成的可评审故事地图 | 不是看板截图或现场研讨照片 |
| Context Map 导出 | `docs/ddd/assets/context-map-v1.{png,pdf}` | 从当前 Markdown 生成的限界上下文关系图 | 不是事件风暴现场截图 |

## 真实评审记录

详见 `docs/evidence/reviews/verified-reviews.md`。旧仓库评审只作为历史证据，不能替代老师仓库的新批准。

## 待产生的证据

| 验收项 | 产生方式 | 当前阻碍 |
| --- | --- | --- |
| 全量单测、ArchUnit、verify | `scripts/final/run-final-verification.ps1` | Identity 错误码失败；A/B 组合尚不能编译 |
| 完整 Testcontainers E2E | 同上，使用 `-IncludeFullFlow` | Q&A 真实入口和 Reputation 闭环未完成 |
| 镜像与 Compose | `scripts/final/build-and-smoke.ps1` | 后端构建失败；前端运行时非 root 尚待核对/修复 |
| Prometheus/Grafana | `scripts/final/verify-observability.ps1` | 尚无已验证告警规则和真实流量 Dashboard |
| 本地压测 | `scripts/final/run-local-load.ps1` | 需要可运行且数据隔离的最终应用 |
| 演示录屏 | `scripts/final/demo-readiness.ps1` 后人工录屏 | 完整业务链路未就绪；脚本不伪造视频 |

所有新增运行证据应记录提交 SHA、执行时间、执行机器、命令、退出码和结果摘要；密码、Cookie、令牌及本地绝对凭据不得入库。

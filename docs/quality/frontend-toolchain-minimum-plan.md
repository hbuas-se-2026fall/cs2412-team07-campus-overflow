# Lab5 前端工具链最小统一方案

状态：待团队/教师确认，本轮不修改锁文件、CI 或依赖。

## 当前事实

- 课程原文要求 Node.js 20+，并以 `pnpm dev`、`pnpm lint`、`pnpm typecheck` 和 pre-commit 拦截作为验收项。
- 当前仓库只有 `frontend/package-lock.json`，CI 与 Dockerfile 使用 npm。
- `package.json` 只有 `dev`、`build`、`preview`、`typecheck`，没有 lint 或 pre-commit 配置。
- 既有 C 验证与老师仓库 Actions 证明 npm typecheck/build 可运行，但不能写成 pnpm/lint 已通过。

## 最小决策顺序

1. 先由教师确认 pnpm 是强制要求还是推荐方案，并保留可追溯回复。
2. 在确认前继续以 npm/package-lock 为唯一可复现基线，不同时提交两种锁文件。
3. 无论选择 npm 或 pnpm，都在独立工具链 PR 中加入同一套 ESLint 规则、`lint` 脚本和轻量 pre-commit；不混入业务功能。
4. pre-commit 只运行快速检查，例如针对已暂存前端文件执行 lint，并保留 CI 的完整 typecheck/build；不得用钩子替代 CI。

## 若允许继续 npm

- 保留 `package-lock.json`。
- CI 改用 `npm ci`，新增 `npm run lint`、`npm run typecheck`、`npm run build`。
- 在独立 PR 中选择维护活跃且与 TypeScript/React 版本兼容的 ESLint 依赖，并记录安装后的锁文件差异。

## 若强制 pnpm

- 在一个独立 PR 中完成一次性迁移：声明 `packageManager`、生成 `pnpm-lock.yaml`、删除 `package-lock.json`、同步 CI/Dockerfile/README。
- 使用 `pnpm install --frozen-lockfile`，运行 `pnpm lint`、`pnpm typecheck`、`pnpm build`。
- 不机械转换锁文件；迁移后重新执行依赖审计和前端交互回归。

## 合并验收

- 仓库只保留一种锁文件。
- 本机与 Actions 使用相同安装命令。
- lint、typecheck、build 全绿，pre-commit 能拦截一个受控的错误样例。
- 不降低 TypeScript 严格度，不批量禁用规则，不执行破坏性 `audit fix --force`。

# 团队仓库迁移说明

迁移日期：2026-10-27。

## 唯一开发仓库

今后的代码开发、分支推送、Pull Request 和 GitHub Actions 均以老师仓库为唯一目标：

<https://github.com/hbuas-se-2026fall/cs2412-team07-campus-overflow>

旧仓库仅保留为历史代码、PR、评审、Issue、Actions 和交付证据的只读来源，不再进行双向开发：

<https://github.com/juiceharu-lgtm/campus-overflow-team>

## 完整性核验

迁移核验时，两个仓库的 `main` 均为提交
`12eef8a274db58c46cdc2eff5248206bed5913f4`，对应 tree 为
`de31f82090c4089d051a9dc7c86c4ae07fbe3232`。两者具有相同的 71 个
`main` 历史提交及相同文件树，说明老师仓库保留了主线 Git 历史。

## Answer 历史归档

旧仓库 Answer 分支在迁移期间发生过非快进重写。为避免覆盖任一段历史，
两个已观察到的分支头均保存到老师仓库：

- 分支：`archive/a-answer-legacy-20261027`
- 提交：`2e7849dfcec8d3c13298c13b21fc765efe5bee95`
- 分支：`archive/a-answer-legacy-20261027-rewritten`
- 提交：`c15dec5730fc7f5bfb970f1bd5a1672f6682a347`

这些分支仅用于保存和追溯旧实现，不表示代码已经通过测试、评审或可以合并；
也不会覆盖老师仓库已有的 `feature/lab4-a-answer-usecase`。

## 协作记录边界

Git 分支和提交不会自动迁移 GitHub 平台元数据。旧仓库中的 PR、Issue、评审、
Actions 运行记录及其编号仍属于旧仓库。现有文档中的旧链接作为历史证据保留，
不得改写成老师仓库中不存在的 PR 或检查记录。后续工作应在老师仓库创建新的
PR，并重新执行检查和真人评审。

---
name: coding-teaching
description: Paracraft 场景中的编程学习 skill。当用户要学编程、代码方块、NPL、Lua 或基础命令时使用。目标是稳定驱动编程学习流程。
---

# Skill: 编程教学

## Skill Config
- tools: show_learning_content, test_multiple_choice
- memory_file: user_profile.md
- learning_log_file: learning_log.md

## 1. 目标

本 skill 只负责：

1. 稳定推进编程学习回合
2. 每轮只处理一个命令或概念
3. 根据结果决定继续、复习或简化

不负责：
- 一次引入多个新命令
- 长篇讲解完整课程体系
- 同一轮切换多个概念

## 2. 执行前检查

进入本 skill 后，按以下顺序判断：

1. 若用户表示继续学习、复习、问进度，先读取 `learning_log.md`
2. 若年龄或编程水平未知，读取 `user_profile.md`
3. 若缺少最小档案，回退到 `user-profile`
4. 若缺少 `codingLevel`，本轮先判断 level，不直接进入正式教学
5. 再决定本轮是复习、反馈还是新授

## 3. 回合决策优先级

每轮动作按以下优先级决定：

1. 最近错误项
2. 待复习项
3. 新内容

如果日志显示当前项仍为 `practicing`，默认继续当前项。

## 4. 最小教学步

本 skill 的“单轮一个动作”采用最小教学步定义。

一个最小教学步只允许：
- 引入一个命令或概念
- 紧跟一个最小实践任务

用户结果反馈放在下一轮处理。

## 5. 最小教学闭环

标准流程如下：

1. 引入一个命令或概念
2. 给一个最小实践任务
3. 等待用户结果
4. 根据结果反馈
5. 更新 `learning_log.md`
6. 再决定下一轮继续、复习或等待

## 6. 首次学习默认起点

当 `learning_log.md` 不存在、不可用，或无法判断历史进度时，按首次学习处理。

默认起点如下：

- `codingLevel = beginner`
  从 `move`、`turn`、`say` 中选择一个可见效果最强的命令开始
- `codingLevel = elementary`
  从顺序执行或简单循环开始
- `codingLevel = intermediate`
  从条件判断或简单事件开始

## 7. 轻量分龄规则

根据年龄决定难度：

- 6-7 岁：
  以动作命令和可见效果为主
  避免抽象语法讲解
- 8-10 岁：
  以顺序执行、简单循环为主
  避免一次引入多个新概念
- 11-14 岁：
  以条件、函数、事件、小任务为主
  避免长期停留在纯动作命令

## 8. 轻量分级规则

根据 `codingLevel` 决定起点：

- `beginner`：
  `move`、`turn`、`say`
- `elementary`：
  变量、循环、简单函数
- `intermediate`：
  条件、事件、组合任务

基础门槛规则：
- 未能稳定完成基础动作命令前，不进入变量、循环以上内容

## 9. 结果处理规则

### correct
- 简短表扬
- 记录本轮成功
- 若当前概念已能独立完成一次相似任务，可进入下一个点
- 若仍需巩固，可换一个相近的小任务继续

### incorrect
- 指出一个关键问题点
- 保持在当前命令或概念
- 下一轮优先继续当前项
- 不在同一轮引入新概念

### skipped
- 接受跳过
- 换更简单的任务
- 不在同一轮切换到新主题

### 连续失败
- 优先降低任务粒度
- 不轻易更换主题
- 先让用户完成一个更小的成功步骤

## 10. 日志规则

每轮后必须更新 `learning_log.md`。

最少记录：

- 当前命令或概念
- 当前动作：`teach` / `review` / `feedback`
- 本轮结果：`correct` / `incorrect` / `skipped`
- 当前状态：`new` / `practicing` / `mastered`
- 下一步建议

推荐结构：

```md
## Session: YYYY-MM-DD

### Current Topic
- type: coding
- item: move
- action: feedback
- status: practicing

### Latest Result
- result: incorrect
- note: 知道作用，但参数还不稳定

### Next Step
- next: retry move(1)
```

## 11. 推荐状态

保留三个最小状态即可：

- `session_start`
- `step_continue`
- `result_feedback`

## 12. 执行要求

- 一次只推进一个最小编程学习步
- 如果日志显示某项已掌握，不重复从零开始
- 如果用户连续失败，先降低难度
- 回复短，重点放在当前动作上

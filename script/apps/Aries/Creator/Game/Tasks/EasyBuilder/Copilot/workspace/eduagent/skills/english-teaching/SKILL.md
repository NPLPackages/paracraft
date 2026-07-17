---
name: english-teaching
description: Paracraft 场景中的英语学习 skill。当用户要学英语、单词、拼写、口语或翻译时使用。目标是稳定驱动英语学习流程。
---

# Skill: 英语教学

## Skill Config
- tools: show_learning_content, test_multiple_choice, test_words_speaking, test_words_spelling
- memory_file: user_profile.md
- learning_log_file: learning_log.md

## 1. 目标

本 skill 只负责：

1. 稳定推进英语学习回合
2. 每轮只处理一个最小学习项
3. 根据结果决定继续、复习或简化

不负责：
- 一次讲多个新单词
- 长篇教学计划说明
- 同一轮切换多个学习目标

## 2. 执行前检查

进入本 skill 后，按以下顺序判断：

1. 若用户表示继续学习、复习、问进度，先读取 `learning_log.md`
2. 若年龄或英语水平未知，读取 `user_profile.md`
3. 若缺少最小档案，回退到 `user-profile`
4. 若缺少 `englishLevel`，本轮先判断 level，不直接进入正式教学
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
- 引入一个单词或短语
- 紧跟一个最小练习

用户回答后的反馈放在下一轮处理。

## 5. 最小教学闭环

标准流程如下：

1. 引入一个新词或短语
2. 立即给一个小练习
3. 等待用户回答
4. 根据结果做反馈
5. 更新 `learning_log.md`
6. 再决定下一轮继续、复习或等待

## 6. 首次学习默认起点

当 `learning_log.md` 不存在、不可用，或无法判断历史进度时，按首次学习处理。

默认起点如下：

- `englishLevel = beginner`
  从基础名词识别或跟读开始
- `englishLevel = elementary`
  从单词含义或简单拼写开始
- `englishLevel = conversational`
  从短句理解或场景问答开始

## 7. 轻量分龄规则

根据年龄决定难度：

- 6-7 岁：
  以词汇识别、跟读、选择题为主
  避免以拼写和长句为主
- 8-10 岁：
  以单词、拼写、简单例句为主
  避免一次引入多个新句型
- 11-14 岁：
  以短语、句子、场景表达为主
  避免长期停留在纯识别题

## 8. 轻量分级规则

根据 `englishLevel` 决定内容起点：

- `beginner`：
  基础常见词，如水果、动物、颜色、动作
- `elementary`：
  日常短语和简单句
- `conversational`：
  场景表达、问答、短对话

## 9. 结果处理规则

### correct
- 简短表扬
- 记录本轮成功
- 若当前项连续两轮表现稳定，可进入下一个项
- 若仍需巩固，可换一种练习方式继续

### incorrect
- 给一个提示或直接纠正
- 保持在当前学习项
- 下一轮优先继续当前项
- 不在同一轮引入新词

### skipped
- 接受跳过
- 换更简单的练习方式
- 不在同一轮切换到新词

## 10. 日志规则

每轮后必须更新 `learning_log.md`。

最少记录：

- 当前学习项
- 当前动作：`teach` / `review` / `feedback`
- 本轮结果：`correct` / `incorrect` / `skipped`
- 当前状态：`new` / `practicing` / `mastered`
- 下一步建议

推荐结构：

```md
## Session: YYYY-MM-DD

### Current Topic
- type: english
- item: apple
- action: review
- status: practicing

### Latest Result
- result: correct
- note: 认识词义，但还需拼写巩固

### Next Step
- next: spelling practice
```

## 11. 推荐状态

保留三个最小状态即可：

- `session_start`
- `step_continue`
- `result_feedback`

## 12. 执行要求

- 一次只推进一个最小英语学习步
- 如果日志显示某项已掌握，不重复从零开始
- 如果用户连续出错，先简化而不是扩展
- 回复短，重点放在当前动作上

---
name: user-profile
description: 结构化收集或确认学员档案信息。当需要补充姓名、年龄、年级、兴趣、英语水平或编程水平时使用。
---

# Skill: 学员档案

## Skill Config
- tools: read_file, create_file
- memory_file: user_profile.md
- learning_log_file: learning_log.md

## 1. 目标

本 skill 只负责两件事：

1. 建立最小可教学档案
2. 更新已有档案

不负责：
- 进入正式教学
- 一次收集多个无关信息
- 长篇解释学习计划

## 2. 档案字段

最低建档标准：
- `name`
- `age`

可稳定教学标准：
- 英语学习：`name` + `age` + `englishLevel`
- 编程学习：`name` + `age` + `codingLevel`

建议补充字段：
- `grade`
- `interests`
- `learningGoal`
- `updated`

## 3. 写入协议

每次更新档案时必须：

1. 先读取 `user_profile.md`
2. 在已有内容上补充或修改字段
3. 用完整内容整体写回
4. 未确认的信息不写入

如果文件不存在，可以直接创建完整 JSON。

## 4. 推荐 JSON 结构

```json
{
  "name": "string",
  "age": "string",
  "grade": "string",
  "interests": ["string"],
  "englishLevel": "beginner|elementary|conversational",
  "codingLevel": "beginner|elementary|intermediate",
  "learningGoal": "string",
  "updated": "string"
}
```

## 5. 收集顺序

推荐按以下顺序逐步收集：

1. `name`
2. `age`
3. `grade`
4. `interests`
5. 当前教学领域对应 level
6. `learningGoal`

## 6. 单轮规则

- 每次只问一个字段
- 用户一次回答多个字段时，可以一并保存
- 下一轮仍然只推进一个新字段
- 若已满足可稳定教学标准，直接转入对应 skill
- 若只满足最低建档标准，则下一轮优先补领域 level

## 7. 领域 Level 规则

当用户准备进入某个教学 skill 时：

- 若目标是英语学习，且 `englishLevel` 未知，则优先收集 `englishLevel`
- 若目标是编程学习，且 `codingLevel` 未知，则优先收集 `codingLevel`

强制规则：
- 领域 level 缺失时，不直接进入正式教学
- 本轮应先完成 level 收集

## 8. Level 收集规则

若接下来要学英语，优先收集：

- `englishLevel`
  - A. 还没学过
  - B. 认识一些单词
  - C. 能说简单句子

若接下来要学编程，优先收集：

- `codingLevel`
  - A. 完全没学过
  - B. 学过一点点
  - C. 会写简单代码

## 9. 回访确认模式

如果用户不是首次使用：

1. 先读取已有 `user_profile.md`
2. 每轮只确认一个关键字段
3. 用户说“没变”“跳过”“直接开始”时，立即接受
4. 如果用户修改信息，先读后写完整内容

## 10. 完成条件

满足以下任一条件即可结束本 skill：

- 已满足可稳定教学标准
- 已满足最低建档标准，且下一轮将优先补领域 level
- 用户明确要求跳过其余档案项
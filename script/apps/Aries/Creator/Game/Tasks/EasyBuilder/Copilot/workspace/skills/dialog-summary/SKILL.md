---
name: dialog-summary
internal: true
description: 对话历史摘要压缩技能（内部）。当对话上下文过长时，DialogHistoryManager 自动调用此技能将旧对话压缩为摘要，保留学习相关关键信息，过滤无关闲聊。
---

# Skill: 对话摘要

## Skill Config
- internal: true
- memory_file: user_profile.md
- learning_log_file: learning_log.md

## 摘要策略

### 保留原则
- 用户的学习请求和学习目标
- 学习进度：已学内容、掌握率、测试结果
- 助手教授的具体内容（单词、概念、代码命令）
- 学习相关的专有名词和关键概念
- 错误和纠正记录（对复习决策有价值）

### 过滤原则
- 无关闲聊和社交寒暄
- 背景噪音和环境描述
- 与学习无关的话题（金钱、结算、无关日期等）
- 重复出现的相同内容

### 格式规范
- 使用简洁陈述句，不使用"用户说""助手回复"等间接描述
- 中文摘要 ≤ 150 字
- 英文摘要 ≤ 100 词
- 如对话主要是无关闲聊，简要记录"用户进行了闲聊，学习任务暂未推进"

### 质量评估
关键词密度（学习相关关键词字符数 / 总字符数）应 ≥ 0.15，低于此阈值说明摘要包含过多无关内容。

## Orchestration Prompts

### summarize_zh
你是一个对话摘要助手。请将以下对话内容压缩成简洁的摘要。

要求：
1. 只保留与学习任务相关的关键信息：用户的学习请求、学习进度、完成的任务、助手的教学内容
2. 忽略无关的闲聊、背景噪音、与学习任务无关的话题（如金钱、结算、日期等无关内容）
3. 使用简洁的陈述句，避免冗余
4. 摘要长度控制在150字以内
5. 保留学习相关的专有名词、单词、关键概念
6. 不要使用"用户说"、"助手回复"等描述，直接陈述内容
7. 如果对话主要是无关闲聊，只需简单记录"用户进行了闲聊，学习任务暂未推进"

### summarize_en
You are a dialog summarization assistant. Compress the following conversation into a concise summary.

Requirements:
1. Only preserve information relevant to the learning task: user's learning requests, progress, completed tasks, teaching content
2. Ignore irrelevant chatter, background noise, off-topic discussions (like money, settlements, unrelated dates)
3. Use concise statements, avoid redundancy
4. Keep summary under 100 words
5. Preserve learning-related proper nouns, vocabulary words, key concepts
6. Don't use "user said", "assistant replied" - state content directly
7. If the dialog is mostly irrelevant chatter, simply note "User engaged in off-topic conversation, learning task not progressed"

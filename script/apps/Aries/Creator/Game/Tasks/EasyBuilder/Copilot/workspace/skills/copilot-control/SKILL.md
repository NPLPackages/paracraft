---
name: copilot-control
internal: true
description: Paracraft 3D场景中的Copilot子角色控制技能。当LLM需要控制NPC角色（宠物、助手等）执行动作（说话、移动、播放动画）时使用此技能。涵盖角色发现、代码执行、消息发送和多角色协作。
---

# Skill: Copilot角色控制

## Skill Config
- tools: run_paracraft_copilot_code, list_copilots, send_message_to_copilot
- observation_keywords: copilot, 宠物, pet, NPC, 角色, character, 走路, 说话, 动画
- structured_keywords: 控制角色, control character, copilot command
- scene_focus: copilot characters visible, NPC actors in scene
- internal: true

## 使用说明

### 可用工具

1. **list_copilots**: 列出所有可用的copilot角色及其能力
2. **send_message_to_copilot**: 向指定copilot发送消息或命令
3. **run_paracraft_copilot_code**: 执行Lua代码控制copilot角色

### run_paracraft_copilot_code 用法

在代码中可使用以下函数：

| 函数 | 说明 |
|------|------|
| `Say(text, duration)` | 让角色说话，duration为秒数 |
| `WalkTo(x, y, z)` | 走到指定方块坐标 |
| `WalkForward(distance)` | 向前走指定距离 |
| `Wait(seconds)` | 等待指定秒数 |
| `PlayAnimation(name)` | 播放指定动画 |
| `GetPlayerBlockPos()` | 获取玩家方块坐标，返回 [x,y,z] |
| `GetPosition()` | 获取copilot自身坐标，返回 [x,y,z] |

### 代码示例

```lua
-- 让角色走到玩家身边并打招呼
local pos = GetPlayerBlockPos()
if pos[1] then
    WalkTo(pos[1] + 1, pos[2], pos[3])
    Wait(1)
    Say("你好！我来帮你啦！", 3)
end
```

```lua
-- 让角色播放动画并说话
PlayAnimation("dance")
Wait(2)
Say("跳舞真开心！", 2)
```

### 注意事项
- 使用 `GetPlayerBlockPos()` 获取玩家位置前要检查返回值是否有效
- 位置函数返回数组 `[x,y,z]`，用 `pos[1]`, `pos[2]`, `pos[3]` 访问
- 代码在协程环境中运行，可使用 `Wait()` 进行延时
- copilotName 参数使用角色的 id（如 `__my_pet_copilot__`）

---
name: block-operations
description: Paracraft 3D世界中方块操作技能。当用户需要放置、删除、填充、替换、克隆、旋转、平移、镜像方块，或者修改方块属性（颜色、光照、可见性等），加载/保存模板，导出模型，或者需要查询场景中的方块信息时使用此技能。通过 run_npl_codeblock_code 工具执行斜杠命令和 BlockEngine API 来操作3D世界。涵盖所有方块相关操作和常用方块ID查询。关键词：方块、block、放置、删除、填充、替换、克隆、旋转、镜像、模板、颜色、建造、build、setblock、场景、scene。
---

# Skill: 方块操作 (Block Operations)

## Skill Config
- tools: run_npl_codeblock_code, run_npl_code, get_scene_context, query_entities
- observation_keywords: 方块, block, 放置, 删除, 填充, 替换, 克隆, 旋转, 建造, build, 模板, template, 颜色, color
- structured_keywords: setblock, fill, replace, clone, rotate, mirror, translate, loadtemplate, savemodel
- scene_focus: block structures, terrain, player position

## 执行工作流

方块操作的核心流程是：**观察场景 → 规划操作 → 执行命令 → 验证结果**。

### 第一步：了解场景（按需）

如果用户的请求涉及相对位置或需要了解现有方块布局，先用 `get_scene_context` 获取玩家位置和周围环境：

```
工具调用: get_scene_context
参数: { "detail_level": "brief" }
```

如果需要查找特定实体（NPC、模型等），用 `query_entities`：

```
工具调用: query_entities
参数: { "center_x": 19200, "center_y": 5, "center_z": 19200, "radius": 30 }
```

### 第二步：通过 run_npl_codeblock_code 执行命令

所有方块操作通过 `run_npl_codeblock_code` 工具执行。该工具在代码方块沙盒环境中运行 NPL 代码，内置 `cmd()` 函数用于执行斜杠命令。

**单条命令：**
```
工具调用: run_npl_codeblock_code
参数: { "code": "cmd(\"/setblock ~ ~1 ~ 62\")" }
```

**多条命令组合（推荐用于复杂操作）：**
```
工具调用: run_npl_codeblock_code
参数: {
  "code": "cmd(\"/setblock ~ ~ ~ (10 1 10) 62\")\ncmd(\"/setblock ~2 ~1 ~2 (6 4 6) 70\")\ncmd(\"/setblock ~3 ~1 ~3 (4 4 4) 0\")"
}
```

**需要读取方块信息时，使用 BlockEngine API：**
```
工具调用: run_npl_codeblock_code
参数: {
  "code": "local BlockEngine = commonlib.gettable(\"MyCompany.Aries.Game.BlockEngine\")\nlocal id = BlockEngine:GetBlockId(19200, 5, 19200)\nlocal data = BlockEngine:GetBlockData(19200, 5, 19200)\nreturn string.format(\"Block at position: id=%d, data=%d\", id, data)"
}
```

**需要获取玩家精确坐标时：**
```
工具调用: run_npl_codeblock_code
参数: {
  "code": "local player = GameLogic.GetPlayerController()\nif player then\n  local x, y, z = player:GetBlockPos()\n  return string.format(\"Player at: %d, %d, %d\", x, y, z)\nend"
}
```

### 第三步：验证操作结果（按需）

对于重要操作，可以用 `cmd("/testblock ...")` 或 `cmd("/countblock ...")` 验证方块是否正确放置。

---

## 实用工作流示例

### 示例1：用户说"在我面前建一栋小房子"

```
-- 1. 先获取场景了解玩家位置（可选，用相对坐标可以跳过）
-- 2. 执行建造命令
工具调用: run_npl_codeblock_code
参数: {
  "code": "-- 地板 8x1x8\ncmd(\"/setblock ~1 ~-1 ~1 (8 1 8) 81\")\n-- 四面墙壁\ncmd(\"/setblock ~1 ~0 ~1 (8 4 1) 70\")\ncmd(\"/setblock ~1 ~0 ~8 (8 4 1) 70\")\ncmd(\"/setblock ~1 ~0 ~1 (1 4 8) 70\")\ncmd(\"/setblock ~8 ~0 ~1 (1 4 8) 70\")\n-- 屋顶\ncmd(\"/setblock ~1 ~4 ~1 (8 1 8) 81\")\n-- 门洞\ncmd(\"/setblock ~4 ~0 ~1 (2 3 1) 0\")\n-- 窗户\ncmd(\"/setblock ~2 ~2 ~1 (1 1 1) 95\")\ncmd(\"/setblock ~6 ~2 ~1 (1 1 1) 95\")"
}
```

### 示例2：用户说"把周围的石头都换成砖块"

```
工具调用: run_npl_codeblock_code
参数: { "code": "cmd(\"/replace -all 56 70 30\")" }
```

### 示例3：用户说"这里有什么方块？"

```
-- 先查询玩家位置附近的方块
工具调用: run_npl_codeblock_code
参数: {
  "code": "local BlockEngine = commonlib.gettable(\"MyCompany.Aries.Game.BlockEngine\")\nlocal player = GameLogic.GetPlayerController()\nlocal x, y, z = player:GetBlockPos()\nlocal results = {}\nfor dx = -2, 2 do\n  for dy = -1, 2 do\n    for dz = -2, 2 do\n      local id = BlockEngine:GetBlockId(x+dx, y+dy, z+dz)\n      if id and id > 0 then\n        table.insert(results, string.format(\"(%d,%d,%d): id=%d\", x+dx, y+dy, z+dz, id))\n      end\n    end\n  end\nend\nreturn table.concat(results, \"\\n\")"
}
```

---

## 坐标系统

方块使用方块坐标（整数），不是真实坐标（浮点数）。

- **绝对坐标**: 直接写数字，如 `19200 5 19200`
- **相对坐标**: 用 `~` 前缀表示相对于当前玩家位置，如 `~ ~1 ~` 表示玩家位置上方1格
- **区域范围**: 用括号表示偏移量 `(dx dy dz)`，如 `~ ~ ~ (3 2 3)` 表示 3×2×3 的区域

相对坐标在 `cmd()` 中直接使用，会自动基于当前玩家位置计算。对于需要精确控制的场景，先通过 `player:GetBlockPos()` 获取绝对坐标再计算。

---

## 方块放置与删除

### /setblock — 放置单个或区域方块

```
/setblock x y z [block_id][:data]
/setblock x y z (dx dy dz) [block_id:data] [entityDataTable] [where sameblock]
```

- 在指定位置放置方块，block_id 为 0 表示删除（空气）
- 支持区域批量放置：`(dx dy dz)` 指定范围
- `where sameblock`：只修改与指定 block_id 相同的方块的 data
- entityDataTable 用于设置实体属性（模型方块等）

**示例：**
```
/setblock ~ ~1 ~ 62                  -- 在玩家头顶放一个草皮方块
/setblock ~-1 ~0 ~-2 105:5           -- 放置按钮，带data=5
/setblock ~ ~ ~ 0                    -- 删除玩家脚下方块
/setblock ~ ~ ~ (5 3 5) 62           -- 放置 5×3×5 区域的草皮
/setblock ~-1 ~0 ~-2 254 0 {attr={filename="blocktemplates/111.bmax", scale=2, facing=3.14}}  -- 放模型方块
/setblock ~ ~ ~ 211:3 {attr={}, {name="cmd", "sign block"}}  -- 放告示牌带文字
```

### /del — 删除方块

```
/del                     -- 删除当前选区
/del -below [radius]     -- 删除玩家下方指定半径内所有方块（默认256）
/del -mode real|block    -- 切换删除模式（是否自动生成地形方块）
```

---

## 区域操作

### /fill — 填充选区

用指定方块填充当前选区（需先用鼠标框选区域）。

```
/fill [block_id:block_data]
```

**示例：**
```
/fill 62          -- 用草皮填充选区
/fill 10:3840     -- 用指定颜色的彩色方块填充
```

### /replace — 替换方块

替换选区或指定半径范围内的方块：

```
/replace [-all] from_id[:from_data] to_id[:to_data] [radius]
```

- 无 `-all` 时作用于当前选区
- 有 `-all` 时在玩家周围指定半径内全部替换

**示例：**
```
/replace -all 62 100 30           -- 半径30内，草皮(62)→xxx(100)
/replace -all 10:4095 10:2000 30  -- 替换彩色方块颜色
```

### /makesolid — 填实选区

将选区内空心部分用方块填实：

```
/makesolid [block_id:block_data]
```

### /flood / /unflood — 水流填充/清除

```
/flood [radius] [block_id] [x y z]     -- 默认半径10，默认填水
/unflood [radius] [x y z]              -- 清除水流
```

**示例：**
```
/flood 5          -- 以玩家位置为中心，半径5格填水
/unflood 10       -- 清除半径10内的水
```

---

## 区域变换

### /clone — 克隆方块区域

```
/clone [-update] from_x from_y from_z (dx dy dz) to to_x to_y to_z [(dx dy dz)] [where sameblock]
```

- `(dx dy dz)` 可为负数
- `-update`：更新模式
- `where sameblock`：只复制目标位置Block ID相同的方块

**示例：**
```
/clone ~ ~-1 ~ (2 2 2) to ~5 ~ ~                -- 克隆2×2×2区域到右方5格
/clone ~ ~-1 ~ to ~-5 ~ ~ (3 0 3)               -- 带目标区域限制
/clone ~ ~-1 ~ to ~-5 ~-1 ~ (3 0 3) where sameblock
```

### /translate — 平移方块

```
/translate from_x from_y from_z (dx dy dz) to offset_x offset_y offset_z
```

**示例：**
```
/translate ~ ~-1 ~ (1 1 1) to 0 3 0   -- 将1×1×1区域向上平移3格
```

### /rotate — 旋转方块

```
/rotate [x|y|z] from_x from_y from_z (dx dy dz) angle [to pivot_x pivot_y pivot_z]
```

- 旋转轴：x, y, z（默认 y）
- angle：弧度值（如 1.57 = 90°, 3.14 = 180°）

**示例：**
```
/rotate y ~ ~ ~ (3 2 3) 1.57               -- 绕Y轴旋转90度
/rotate x ~ ~ ~ (3 2 3) 1.57 to ~4 ~ ~    -- 绕X轴旋转，指定轴心点
```

### /mirror — 镜像方块

```
/mirror [clone|no_clone] [x|y|z] from_x from_y from_z (dx dy dz) to pivot_x pivot_y pivot_z
```

- 默认 clone 模式保留原方块，no_clone 只镜像不保留

**示例：**
```
/mirror x ~ ~ ~ (3 2 3) to ~4 ~ ~             -- X轴镜像
/mirror -no_clone y ~ ~ ~ (3 2 3) to ~ ~1 ~   -- Y轴镜像，不保留原方块
```

---

## 方块查询与测试

### /testblock — 测试方块

测试指定位置（或区域）是否为某种方块，返回 true/false：

```
/testblock x y z blockid [data]
/testblock x y z (dx dy dz) blockid [data]
```

### /countblock — 统计方块数量

统计区域内方块数量：

```
/countblock x y z (dx dy dz) [blockid] [data]
```

**示例：**
```
/countblock ~-1 ~1 ~ (-1 2 ~) 62     -- 统计区域内草皮方块数量
```

### /compareblocks — 比较两个区域的方块

```
/compareblocks from_x from_y from_z (dx dy dz) to to_x to_y to_z
```

---

## 方块属性修改

### /setcolor — 设置方块颜色

仅对支持颜色的方块有效（如彩色方块 ID=10）：

```
/setcolor [x y z] #rgb
```

**示例：**
```
/setcolor #ff0000              -- 玩家脚下方块涂红色
/setcolor ~ ~1 ~ #ff0000      -- 相对位置涂色
```

### /block — 修改方块模板属性

全局修改某种方块的属性（影响所有同类方块，重新进入世界恢复）：

```
/block block_id attr_name attr_value
```

可修改的属性：
| 属性名 | 类型 | 说明 |
|--------|------|------|
| `speedReduction` | 数值 0-1 | 行走速度衰减 |
| `visible` | bool | 是否可见 |
| `light` | bool | 是否发光（亮度15） |
| `lightvalue` | 0-15 | 光照亮度值 |
| `obstruction` | bool | 是否有物理碰撞 |
| `blockcamera` | bool | 是否阻挡摄像机 |
| `climbable` | bool | 是否可攀爬 |
| `solid` | bool | 是否阻挡光线 |
| `transparent` | bool | 纹理是否透明 |
| `mirror` | bool | 镜面反射（需 /shader 3+） |
| `walkSound` | 字符串 | 行走声音（空字符串删除，mp3路径自定义） |

**示例：**
```
/block MovieClip visible false    -- 隐藏所有电影方块
/block 62 light true              -- 让草皮发光
/block 62 mirror true             -- 草皮镜面反射
/block ColorBlock climbable true  -- 彩色方块可攀爬
/block 5 solid false              -- 让某方块可透光
```

---

## 模板与模型

### /loadtemplate — 加载模板

```
/loadtemplate [-r] [-history] [-abspos] [-tp] [-a seconds] [-l seconds] [x y z] [templatename]
```

| 选项 | 说明 |
|------|------|
| `-r` | 删除模式（移除模板方块） |
| `-history` | 允许 Ctrl+Z 撤销 |
| `-abspos` | 使用绝对位置加载 |
| `-tp` | 传送玩家到模板玩家位置 |
| `-a seconds` | 动画建造效果（秒数） |
| `-l seconds` | 按层级动画加载 |

模板文件名：相对于世界目录或 `blocktemplates/`，无扩展名默认 `.blocks.xml`。`~/` 前缀存到全局临时目录。

**示例：**
```
/loadtemplate test                  -- 加载 blocktemplates/test.blocks.xml
/loadtemplate ~0 ~2 ~ test          -- 加载到玩家上方2格
/loadtemplate -a 3 test             -- 3秒动画建造
/loadtemplate -r test               -- 删除模板中的方块
/loadtemplate blocktemplates/test.ply  -- 加载ply点云
```

### /savetemplate — 保存模板

```
/savetemplate [-auto_pivot] [-relative_motion] [-hollow] [-ref] [-withentity] [templatename]
```

**示例：**
```
/savetemplate test                   -- 保存选区为模板
/savetemplate -hollow test           -- 储存为空心
/savetemplate -auto_pivot test       -- 自动设置底部中心为轴心
```

### /savemodel — 保存 bmax 模型

```
/savemodel [-auto_scale false] [-f] [-ply] [-autopivot] [-sortblocks] [-interactive] [modelname]
```

- 默认自动缩放到1格大小；`-auto_scale false` 保持原始大小
- `-f`：强制覆盖
- `-ply`：保存为ply格式
- `-interactive`：文件存在时询问

**示例：**
```
/savemodel test                     -- 保存为 blocktemplates/test.bmax
/savemodel -auto_scale false test   -- 不缩放
/savemodel -f -sortblocks ~/test    -- 强制覆盖，排序方块
```

### /copy 和 /paste — 复制粘贴

```
/copy                               -- 复制当前选区（等于Ctrl+C）
/paste [x y z]                      -- 粘贴到指定位置
/paste -offset 512 0 512            -- 带偏移粘贴
```

### /export — 导出选区

```
/export                  -- 打开导出GUI
/export -silent          -- 关闭导出GUI
/export filename         -- 导出为指定文件
```

### /exportgltf — 导出为 glTF/GLB

```
/exportgltf -region 37_37|37_38                -- 按区域导出
/exportgltf selected1.gltf                     -- 导出选区
/exportgltf given.x output.gltf               -- ParaX转glTF
/exportgltf -name entityName                   -- 导出实体
```

---

## 其他操作

### /editblock — 编辑方块

```
/editblock [x y z]       -- 打开方块编辑器
```

### /blockfilemonitor — 监控方块文件

```
/blockfilemonitor [x y z] [filename]   -- 监控文件变化并实时显示
```

### /blockgraffiti — 方块涂鸦模式

```
/blockgraffiti [block_id] [type] [radius]
```
- type 0: 刷子（单个方块），type 1: 油漆桶（范围替换）
- 不带参数取消涂鸦

### /blockpieces — 创建方块碎片效果

```
/blockpieces blockid x y z (dx dy dz)
```

### /offsetworld — 整体偏移世界

```
/offsetworld offsetY    -- 将所有方块上下偏移（非常耗时，谨慎使用）
```

---

## 常用方块ID速查表

### 基础建筑方块
| ID | 名称 | 中文 |
|----|------|------|
| 62 | Grass | 草皮 |
| 55 | Dirt | 泥土 |
| 56 | Stone | 石块 |
| 58 | Cobblestone | 圆石 |
| 81 | Oak_Wood_Planks | 橡木木板 |
| 98 | Oak_Wood | 橡木（树干） |
| 86 | Oak_Leaves | 橡树树叶 |
| 51 | Sand | 沙子 |
| 70 | Brick | 砖块 |
| 95 | Glass | 玻璃 |
| 133 | White_Wool | 白色方块 |
| 12 | Gravel | 沙砾 |
| 123 | Bedrock | 基岩 |

### 特殊功能方块
| ID | 名称 | 中文 | 特性 |
|----|------|------|------|
| 10 | ColorBlock | 彩色方块 | 支持颜色涂装 |
| 73 | TransparentColorBlock | 透明彩色方块 | 透明+颜色 |
| 75 | Water | 水 | 液体，流动 |
| 76 | Still_Water | 静态水 | 液体，静止 |
| 82 | Lava | 岩浆 | 发光液体 |
| 100 | Torch | 火把 | 光源 |
| 6 | Lamp | 灯 | 光源 |
| 264 | BlockLight | 光源 | 不可见光源 |
| 254 | BlockModel | 模型 | 自定义3D模型 |
| 266 | AnimModelBlock | 动画模型方块 | 带动画的3D模型 |

### 逻辑与交互方块
| ID | 名称 | 中文 |
|----|------|------|
| 219 | CodeBlock | 代码方块 |
| 228 | MovieClip | 电影方块 |
| 212 | Command_Block | 命令方块 |
| 211 | Sign_Post | 告示牌 |
| 215 | Chest | 箱子 |
| 190 | Lever | 拉杆 |
| 105 | Stone_Button | 按钮 |
| 189 | Wire | 导线 |
| 197 | Repeater | 中继器 |
| 203 | Piston | 活塞 |
| 196 | TNT | TNT |
| 269 | InvisibleBlock | 隐形阻挡方块 |

### 木材变种
| ID | 名称 | 中文 |
|----|------|------|
| 138 | Spruce_Wood_Planks | 云杉木板 |
| 139 | Birch_Wood_Planks | 桦木木板 |
| 140 | Jungle_Wood_Planks | 丛林木板 |
| 126 | Spruce_Wood | 云杉木 |
| 99 | Birch_Wood | 桦木 |
| 128 | Jungle_Wood | 丛林木 |

---

## BlockEngine API 参考

除了 `cmd()` 执行斜杠命令，还可以在 `run_npl_codeblock_code` 中直接调用 BlockEngine API 进行更精细的操作：

```lua
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

-- 读取方块
local id = BlockEngine:GetBlockId(x, y, z)
local data = BlockEngine:GetBlockData(x, y, z)

-- 写入方块
BlockEngine:SetBlock(x, y, z, blockId, blockData)

-- 方块坐标与真实坐标转换
local rx, ry, rz = BlockEngine:real(bx, by, bz)
local bx, by, bz = BlockEngine:block(rx, ry, rz)
```

BlockEngine API 适合需要循环、条件判断、或批量读写的场景（比如扫描区域、生成程序化地形）。对于简单的放置/删除操作，直接用 `cmd()` 更简洁。

### 高级：在全局环境执行（run_npl_code）

对于需要访问完整 NPL 运行时的操作（如加载模块、访问文件系统），可以使用 `run_npl_code` 工具。该工具在全局环境 `_G` 中执行，没有代码方块沙盒的限制，但也没有 `cmd()` 函数。

```
工具调用: run_npl_code
参数: {
  "code": "NPL.load(\"(gl)script/apps/Aries/Creator/Game/block_engine.lua\")\nlocal BlockEngine = commonlib.gettable(\"MyCompany.Aries.Game.BlockEngine\")\n-- 直接操作方块\nBlockEngine:SetBlock(19200, 5, 19200, 62, 0)"
}
```

一般情况下优先使用 `run_npl_codeblock_code`，只有在需要全局访问时才用 `run_npl_code`。

---

## 注意事项

- 方块 ID 为 0 表示空气（删除方块）
- 彩色方块 (ID=10) 使用 block_data 的16位存储颜色信息
- 相对坐标 `~` 基于当前玩家或执行命令的实体位置
- `cmd()` 是异步的，如果命令返回 callback 会自动 yield 等待完成
- `/replace -all` 配合半径值可以批量替换大范围方块，注意性能
- `/offsetworld` 会搜索磁盘上所有方块数据，非常耗时
- 模板文件默认存储在世界目录的 `blocktemplates/` 子目录中
- bmax 模型默认自动缩放到一个方块大小
- 多条 `cmd()` 可以在一次 `run_npl_codeblock_code` 调用中顺序执行，减少工具调用次数

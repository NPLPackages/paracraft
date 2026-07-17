# CompetitionManager 类功能分析

> **文件路径**: `script/apps/Aries/Creator/Game/Educate/Competition/CompetitionManager.lua`
> **命名空间**: `MyCompany.Aries.Game.Educate.Competete.Manager`
> **作者**: pbb
> **创建日期**: 2023/6/9
> **用途**: Paracraft 教育版竞赛/考试系统核心管理器

---

## 一、总体概述

`CompetitionManager` 是 Paracraft 教育版**竞赛（赛事/考试）系统**的核心单例管理类。它负责从服务端拉取赛事数据、加载/创建/fork 赛事世界、管理答题倒计时、提交成绩与世界、以及处理赛事世界异常修复等完整生命周期。

该类与 `CompetitionApi`（网络接口）、`CompetitionUtils`（工具函数）、`ShareWorld`（世界同步）、`EducateProjectManager`（项目管理）等模块协作，构成完整的赛事闭环。

### 依赖模块

| 模块 | 作用 |
|------|------|
| `CompeteRepairPage` | 修复中提示 UI |
| `CompetitionCreatePaper` | 试卷展示页面 |
| `KpChatChannel` | 聊天频道 |
| `CompetitionUtils` | 时间格式化、房间、广播、压缩、上传等工具 |
| `CompetitionApi` | 赛事相关 HTTP 接口 |
| `EducateProjectManager` | 教育项目管理 |
| `ShareWorld` | 世界同步上传 |

---

## 二、核心数据结构

| 字段 | 类型 | 说明 |
|------|------|------|
| `compete_data` | table | 比赛基础信息（competeId、competePaperId、competeQuestionId、enrolmentId、type、projectId 等） |
| `compete_info_data` | table | 考试详情（createdAt、answerEndAt、countDown、isCountDown 等） |
| `compete_paper_data` | table | 试卷/题目信息（creativeType、isLockEdit、countDown、isUploadScore、real_answer_time 等） |
| `compete_record_data` | table | 答卷记录（id、status、competePaperId 等） |
| `custom_answer_score` | table | 自定义成绩项（多字段评分） |
| `answer_score` | number | 普通成绩 |
| `surplus_time` | number | 剩余答题秒数 |
| `isWorldLoaded` | bool | 世界是否加载完成 |
| `isSwfpageClosed` | bool | 加载页是否关闭 |
| `isFirstSyncWorld` | bool | 是否首次同步世界 |
| `isCompeteFinished` | bool | 赛事是否已结束 |
| `isSubmitScore` | bool | 是否处于提交成绩阶段 |
| `bIgnoreCompeteScore` | bool | 仅提交世界、暂不上报成绩 |
| `isCompeteWorldLock` | bool | 世界是否锁定编辑 |
| `sync_world_time` | number | 同步计时累计 |
| `CurrentCreateWorldName` | string | 当前创建/上传的世界名 |

---

## 三、生命周期与事件绑定

### 1. `Init()` —— 初始化

- 清空所有状态字段
- 注册过滤器（filters）：
  - `swf_loading_bar.close_page` → 加载页关闭回调
  - `SyncWorldFinishBegin` / `SyncWorldFinish` / `SyncWorldEnded` / `SyncWorldInfoFinish` → 世界同步各阶段
  - `CodeBlockWindow.IsDragable` → 代码方块是否可拖动（锁定编辑）
  - `save_world_info` / `load_world_info` → 世界信息读写（设置 channel/visibility）
  - `OnWorldCreate` → 记录新建世界名
  - `EducateLogout` → 教育版登出封装
- 连接信号：`WorldLoaded`、`WorldUnloaded`
- 监听事件：`createworld_callback`

### 2. 世界加载/卸载回调

- `OnWorldLoaded()`：标记 `isWorldLoaded`，触发 `CheckCompeteStatus()`，关闭修复页
- `OnWorldUnload()`：关闭试卷页面
- `OnSwfLoadingCloesed()`：标记加载页关闭，触发 `CheckCompeteStatus()`，并注册三个代码块文本事件：
  - `SubmitCompeteScore`：提交分数（支持 number / table 两种格式）
  - `RepairCompeteWorld`：修复赛事世界
  - `UploadCompeteWorld`：上传赛事世界
  - `LockCompeteWorld`：锁定/解锁世界编辑

---

## 四、赛事启动流程

### `SetCompeteData(data)` → `StartCompete()`（debounce 5s）

```
SetCompeteData
   └─> CompeteStartImp (debounce 5s)
         └─> StartCompete
               ├─ GetCompeteInfo(competeContentId)  // 拉取考试详情
               ├─ 根据 action_type 分发：
               │     ├─ "retryWorld"   → StartUploadCompeteWorld()  // 重传世界
               │     ├─ "loadworld"    → /loadworld -s -auto <projectId>
               │     ├─ "forkworld"    → ForkWorkd(worldId)
               │     └─ "createworld"  → CreateWorld()
               └─ projectId 为空 → 提示并 CreateWorld()
```

### 世界创建方式

| 方式 | 函数 | 说明 |
|------|------|------|
| 创建空世界 | `CreateWorld()` | 生成 `exam_worldYYYY_MM_DD_paperId_questionId` 命名，superflat 模式 |
| Fork 世界 | `ForkWorkd(worldId)` | 从 keepwork fork，含 keepwork 加载 + DelayLoadWorld + 15s 超时兜底 |
| 加载世界 | `/loadworld` 命令 | 直接加载已有世界 |

### 世界命名规则

```
exam_world<YYYY_MM_DD>_<competePaperId>_<competeQuestionId>
```

校验正则：`^exam_world%d+_%d+_%d+_%d+`

### ForkWorkd 关键设计

为避免"人变摄像机"bug（重复 `/loadworld` 导致），采用三重防护：
1. **keepwork 主路径**：`/createworld -forkType keepwork` 内部自动加载
2. **DelayLoadWorld 兜底**：仅在 `IsForkWorldLoaded()` 为 false 时补加载
3. **15s 超时兜底**：定时器检查，若世界未进入且本地文件就绪则直接加载

---

## 五、赛事状态检查与时间管理

### 1. `CheckCompeteStatus()`

世界加载完成 + 加载页关闭后触发：
- 调用 `PostCompeteRecord` 上报答卷记录
- 若 `status == 1` → 答题已结束
- 否则 → `CheckCompetePaperStatus()` → `StartCurrentCompete()`

### 2. `StartCurrentCompete()`

四类数据齐全时：
- `UpdateSurplusTime()` —— 启动倒计时
- `AdjustCompeteTime()` —— 启动 20s 轮询校准
- `JoinCompeteRoom()` —— 加入答题房间
- `InitCompeteStatus()` —— 初始化锁定状态
- `CompetitionCreatePaper.ShowPage()` —— 显示试卷页

### 3. 倒计时与校准

| 定时器 | 周期 | 作用 |
|--------|------|------|
| `timer` | 1s | 倒计时 `surplus_time`，归零后 `CheckCompeteTimeEnd` → `ForceSubmitScore` |
| `adjustTimer` | 20s | `CheckInValidCompete`：更新试卷状态 + 同步世界 + 拉取最新赛事详情 |

### 4. 答题结束时间计算 `GetAnswerEndTime()`

取以下三者中**最早**的结束时间：
- 赛事最终结束时间 `answerEndAt`
- 试卷级倒计时：`real_answer_time + countDown * 60`（当 `isCountDown == 1`）
- 题目级倒计时：`real_answer_time + countDown * 60`

### 5. 定时同步世界 `SyncCompeteWorld()`

- 正式版：每 20 分钟同步一次
- 内部版（`isInternal`）：每 60 秒同步一次

---

## 六、成绩与世界提交

### 1. 普通赛事 `UploadCompeteScore(score)`

- score 为 number → `UpdateAnswerScore` → `SubmitAnswerRecord("score", score)`
- score 为 table（含 kpProjectId）→ 获取 commitId → `UpdateAnswerWorld(commitId)`

### 2. 自定义赛事 `SetCustomAnswerScore(params, isUp)`

当 `compete_paper_data.isUploadScore == 1` 时为自定义赛事：
- 支持多字段评分（score/time 等，`isScore=true` 的字段作为主分数）
- `isUp=true` 时触发 `SubmitWorld()` 或 `UploadCustomCompeteScore()`

### 3. `SubmitAnswerRecord(key, value)`

仅在 `isSubmitScore == true` 时真正上报服务端：
- 构造 `answerRecord`（projectId、answerSheetRecordId、competeQuestionId、answer、questionType）
- 调用 `CompetitionApi.SubmitAnswerRecord`
- 成功后广播 `edu_compete_submited` 事件

### 4. `UploadCompeteWorld()`（用户主动重传）

从 web 端拉起客户端场景：
- 校验本地世界有效性
- 压缩为 zip → 上传七牛 → 调用 `ReSubmitAnswerRecord`
- 通过 `SendRepairResult` 广播修复结果

### 5. 强制提交 `ForceSubmitScore()`

倒计时归零或试卷已提交时强制提交：
- `isSubmitScore = true`
- `SubmitWorld(true)`

---

## 七、世界同步与可见性

### `OnSyncWorldFinish()`

- 非首次上传：仅设置可见性
- 首次上传：提示"首次同步世界成功"

### `SyncWorldInfoFinish(bSuccess)`

世界信息同步完成回调，根据状态分发：
- 首次同步且未提交成绩 → 返回
- `bIgnoreCompeteScore` → 仅提交世界，不出成绩
- 普通赛事 → `UploadCompeteScore`
- 自定义赛事 → `UploadCustomCompeteScore`

### `SetVisibility()`

将赛事世界可见性设为 1（公开），通过 `KeepworkServiceProject:UpdateProject` 更新。

---

## 八、房间与广播

### 房间机制

- **答题房间**：`__answerSheetRecord_EDU_<answerSheetRecordId>__`
  - `JoinCompeteRoom()` / `LeaveCompeteRoom()`
- **修复房间**：`__platformUser_EDU_<userId>__`

### `BroadcastMsg(msgdata, callback)`

向答题房间广播 `edu_compete_submited` 事件，payload 含 userId、competeQuestionId、answerSheetRecordId、completeTime。

### `SendRepairResult(result)`

向修复房间广播 `retry_project_upload` 事件，通知 web 端修复结果。

---

## 九、赛事世界修复

### 触发方式

1. 代码块事件 `RepairCompeteWorld`（支持自定义 UI）
2. `ShowCommonMsgBox` 弹窗确认

### 修复流程 `RepairCompeteWorldFunc()`

```
RepairCompeteWorld
  ├─ ShowPage (修复中提示)
  └─ RepairCompeteWorldFunc
       ├─ 备份 compete_data
       ├─ DoExitWorld()  // 退出当前世界
       ├─ DeleteCompeteWorld(currentWorld)  // 删除错误世界
       │     ├─ 远程世界：DeleteWorldSilent → DeleteLocal
       │     └─ 本地世界：DeleteLocal
       ├─ Init()  // 重新初始化
       ├─ ClearCompeteData()
       └─ SetCompeteData(compete_data)  // 重新进入赛事
```

### `DeleteCompeteWorld(worldData, callback)`

- 有 `kpProjectId`：先 `DeleteWorldSilent`（删远程）再 `DeleteLocal`（删本地）
- 无 `kpProjectId`：仅 `DeleteLocal`
- 删除后刷新世界列表 `Create:GetWorldList`

---

## 十、世界导出

### `StartExportCompeteWorld()`

- `WorldCommon.SaveWorldAsImp` 导出到临时目录
- `P3DFileManager:ZipWorldImp` 打包为 p3d
- 复制到 `competeExport/export_world.p3d`
- 打开资源管理器定位

---

## 十一、代码方块编辑控制

### `IsCodeWindowDragable()`

当满足以下条件时**禁止**代码方块拖动/编辑：
- 存在 `compete_paper_data`、`compete_info_data`、`compete_data`
- 且（`isCompeteFinished` 或 `isCompeteWorldLock`）
- 且 `compete_paper_data.isLockEdit == 1`

### `LockCompeteWorld(msg)`

通过代码块事件锁定世界编辑（`isCompeteWorldLock`）。

---

## 十二、登出与退出

### `EducateLogout` 过滤器

封装登出流程：
- `apply_filters('logout')` + `apply_filters("OnKeepWorkLogout", true)`
- `GameLogic.CheckSignedIn` 检查登录
- 成功后执行回调

### `DoExitWorld()` / `RealExitWorld()`

- `DoExitWorld`：清理 Store、初始化 CustomCharItems、`Game.Exit()`
- `RealExitWorld`：调用 `WorldExitDialog.OnDialogResult(No)`

### `OpenWebPaperUrl()`

打开 web 端试卷页面（根据环境选择 cp-dev/cp-rls/cp.palaka.cn）。

---

## 十三、关键设计要点

### 1. 防抖启动
`SetCompeteData` 使用 `commonlib.debounce(5000)` 防止频繁点击导致重复启动赛事。

### 2. Fork 世界防重入
三重加载路径 + `IsForkWorldLoaded()` 判断，避免重复 `/loadworld` 导致"人变摄像机"bug。

### 3. 时间校准机制
- 20s 轮询拉取服务端最新赛事详情
- 倒计时归零后再次 `CheckCompeteTimeEnd` 二次确认，防止本地时间漂移误判

### 4. 成绩提交阶段控制
通过 `isSubmitScore` 区分"仅上传世界"与"上传世界+上报成绩"两个阶段：
- `UploadCompeteWorld` 事件：`bIgnoreCompeteScore = true`，仅同步世界
- `SubmitCompeteScore` 事件：`isSubmitScore = true`，进入成绩上报阶段

### 5. 401 自动重登
所有关键 API 在 `err == 401` 时自动触发 `EducateLogout` 重新登录后重试。

### 6. 容错保护
- `OnWorldLoaded` / `OnWorldUnload` / `OnSwfLoadingCloesed` 均包裹 `TimerManager.SetTimeout`，即使报错也不中断主流程
- 世界加载超时检测（`DelayLoadWorld` 最多 120 次 × 500ms = 60s）

---

## 十四、外部调用接口

### 代码块事件（CodeGlobal TextEvent）

| 事件名 | 参数 | 作用 |
|--------|------|------|
| `SubmitCompeteScore` | `{score=number/table, isUp=bool}` | 提交分数 |
| `RepairCompeteWorld` | `{isCustomUI=bool}` | 修复赛事世界 |
| `UploadCompeteWorld` | - | 上传赛事世界（不出成绩） |
| `LockCompeteWorld` | `{isLock=bool}` | 锁定世界编辑 |

### 命令示例

```lua
-- 提交分数
cmd("/sendevent SubmitCompeteScore {score = 10, isUp = true}")

-- 自定义多字段分数
broadcast("SubmitCompeteScore", {
    score = {
        {key="score", value=10, name="分数", isScore=true},
        {key="time",  value=20, name="时间"}
    },
    isUp = true
})
```

### 广播事件

| 事件名 | 方向 | 说明 |
|--------|------|------|
| `edu_compete_submited` | 客户端 → 答题房间 | 答题完成通知 |
| `retry_project_upload` | 客户端 → 修复房间 | 世界修复结果通知 |

---

## 十五、模块依赖关系图

```mermaid
graph TD
    CM[CompetitionManager]
    CM -->|API| CompetitionApi
    CM -->|工具| CompetitionUtils
    CM -->|UI| CompetitionCreatePaper
    CM -->|UI| CompeteRepairPage
    CM -->|UI| RepairDialog
    CM -->|世界同步| ShareWorld
    CM -->|项目| EducateProjectManager
    CM -->|删除| DeleteWorld
    CM -->|创建| CreateWorld
    CM -->|同步| SyncWorld
    CM -->|本地服务| LocalService
    CM -->|Keepwork| KeepworkServiceProject
    CM -->|文件| P3DFileManager
    CM -->|世界通用| WorldCommon
    CM -->|事件| GameLogic Filters/Events
```

---

## 十六、潜在改进点

1. **命名空间拼写**：`Competete` 应为 `Compete`（历史遗留，改动风险大）
2. **`ForkWorkd` 拼写**：应为 `ForkWorld`
3. **魔法数字**：倒计时周期、超时时间等建议提取为常量
4. **错误处理**：部分 API 失败仅 `AddBBS` 提示，缺少重试机制

---

## 十七、深入代码后的补充分析（漏洞与优化）

> 下列为对照源码逐行复核后新增的发现，优先级高于第十六节的"拼写/魔法数字"。
> 其中 ①② 已在代码中修复。

### A. 真实漏洞（bug）

#### ① `Init()` 中 4 个匿名 filter 会随每次修复无限累积 —— 最严重【已修复】

`Init()` 里 `save_world_info`、`load_world_info`、`OnWorldCreate`、`EducateLogout` 四个 filter 原先**只 `add_filter` 没有配对的 `remove_filter`**，而其它 filter 都是 remove+add 成对出现。

底层 `Filters:add_filter` 用 `UnorderedArraySet:add` 按**对象相等**去重，上面注册的是**匿名闭包**，每次 `Init()` 都是新对象，Set 无法去重 → 只增不减。

关键在于 `RepairCompeteWorldFunc` 会再次调用 `self:Init()`，因此**每修复一次赛事世界，这四个 filter 各多注册一份**：

- `EducateLogout`：`apply_filters("EducateLogout", ...)` 会把闭包跑 N 次 → 触发 N 次 `logout` + N 次登录检查 + N 次 callback，`StartCompete` 重试回调随之叠加。
- `OnWorldCreate` / `save_world_info` / `load_world_info`：虽是幂等赋值，但每次保存/加载世界都被重复调用，属隐性性能与行为污染。

**修复**：已改为具名函数 `OnSaveWorldInfoFilter` / `OnLoadWorldInfoFilter` / `OnWorldCreateFilter` / `OnEducateLogoutFilter`，并与其它 filter 一样在 `Init()` 中成对 `remove_filter` + `add_filter`。

#### ② `DeleteCompeteWorld` 中 `kpProjectId > 0` 可能抛运行时错误【已修复】

原代码 `selectedWorld.kpProjectId > 0`，若 `kpProjectId` 是字符串（tag/接口返回常见），Lua 中 `"123" > 0` 会直接抛 `attempt to compare string with number`，导致整条**修复链**中断。对比 `CheckIsRemoteWorld` 用的是 `tonumber(kpProjectId) > 0`。

**修复**：已统一改为 `tonumber(selectedWorld.kpProjectId) and tonumber(selectedWorld.kpProjectId) > 0`。

#### ③ 双重强制提交的竞态未完全护住【已修复】

时间到时两条独立路径会调用 `ForceSubmitScore`：1s 倒计时归零 → `CheckCompeteTimeEnd` 回调；20s 校准 → `UpdateCompetePaperStatus`。两处都用 `if not self.isCompeteFinished` 保护，但 `isCompeteFinished` 是在**异步回调**里才置 `true`（跨了 API 请求 / `SetTimeout(500)`），无法跨路径互斥。两条链几乎同时进入、都在对方置位前通过判断时，会各提交一次成绩并各广播一次 `edu_compete_submited`。

**修复**：在 `ForceSubmitScore` 内引入一次性闸门 `isForceSubmitting`（幂等保护），保证每场赛事最终只提交/报分一次；该闸门在 `Init()` 与 `SetCompeteData()`（新一场赛事入口）中复位，修复后重进不受影响。

#### ④ `ForceSubmitScore` 调 `SubmitWorld(true)`，但 `SubmitWorld` 无参【待确认】

参数被忽略，目前无害，但疑似丢失了"强制"分支意图（如强制提交本应跳过 `IsReadOnly` 判断），需确认。

### B. 可优化 / 清理

1. **`CheckCompeteOldData` 是死代码**：`CreateWorld` / `ForkWorkd` 两处调用均已注释，函数无人调用；且内部 `paperId == competePaperId` 是 string 与 number 比较恒为 false，即便启用也是坏的。建议删除。
2. **`StartExportCompeteWorld` 用 `ParaIO.DeleteFile` 删目录**：`destForder` 是目录，`DeleteFile` 对目录通常无效，应为 `DeleteDirectory`，否则临时导出目录残留。
3. **i18n 不一致**：修复/删除链路大量裸中文串 `AddBBS(nil, "删除错误项目失败...")`，而其它地方用 `L"..."`，若有本地化需求需统一。
4. **调试输出未清理**：`print("ClearCompeteData===")`、`StartCurrentCompete` 的多行 `echo(...)`、`print("cmd====")` 等散落在正式路径上，建议收敛到 `if System.options.isDevMode` 之下。

### C. 文档补充说明

- **`Init()` 不重置 `CompeteStartImp`**：debounce 实例在 repair 后被复用（这是对的），但值得写明，否则读者会误以为 Init 会重建它。
- **`CheckWorldValid` 带副作用**：当缺 `worldconfig.txt` 时会 `WriteConfigFile` + `Game.Start(worldPath)` 直接启动世界。这是"校验函数带副作用"的隐藏行为，排障时容易踩坑，第四/九节未提及。

---

**分析完成日期**: 2026-07-06
**补充与修复日期**: 2026-07-06（新增第十七节；修复 ①②）

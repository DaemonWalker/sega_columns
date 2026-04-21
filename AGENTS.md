<!-- From: e:\workspace\godot\columns\AGENTS.md -->
<!-- From: e:\workspace\godot\columns\AGENTS.md -->
# Columns — Agent 开发指南

> 本文档面向 AI 编程助手。阅读前请确认你了解：这是一个基于 **Godot 4.6 (GDScript)** 的本地 Match-3 掉落式益智游戏，类似经典《Columns》。
> 本文档必须基于实际代码内容编写，禁止添加假设或推测。

---

## 项目概述

- **引擎**: Godot 4.6（GDScript 版本）
- **脚本语言**: GDScript
- **脚本扩展名**: `.gd`
- **项目类型**: 2D 益智游戏
- **主场景**: `res://scenes/start_menu.tscn`
- **游戏场景**: `res://scenes/single_player.tscn`
- **类型**: 2D 益智游戏（6×13 网格），玩家控制 3 颗宝石组成的垂直长条下落，通过移动/循环/软降达成 3 颗及以上同色相连（纵/横/斜向）进行消除。

---

## 技术栈与构建方式

### 必备工具
- **Godot 4.6 Editor**（Windows 路径如 `E:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`）
- **Python + PIL**（可选，用于 `tools/generate_jewels.py` 生成宝石纹理）
- 如需使用 Python，请使用 **conda 中的 Python** 或任何带有 `Pillow` 的环境。

### 构建说明
- 修改 GDScript 脚本后直接在 Godot 编辑器中运行即可，**无需额外编译**。
- Godot 编辑器会在保存时自动解析 GDScript。
- 场景中的 `ext_resource` 引用的是 `.gd` 脚本。
- 项目已**彻底从 C# 迁移至 GDScript**，原 `columns.csproj` 已移除，不再存在任何 C# 业务代码。

### 无测试套件
- 当前项目 **没有任何自动化测试**（无单元测试、无集成测试、无 CI 配置）。
- 所有验证依赖在 Godot 编辑器中直接运行场景（F5 / 播放按钮）进行手工测试。

---

## 目录结构与核心文件

```
res://
├── project.godot              # Godot 项目配置（主场景、Autoload、显示设置）
├── .editorconfig              # 编码声明: charset = utf-8
├── .gitattributes             # LF 行尾: * text=auto eol=lf
├── scenes/
│   ├── start_menu.tscn        # 开始菜单（Start / Options / Leaderboard / Demo / Quit）
│   ├── leaderboard.tscn       # 排行榜（Score / Cleared 两栏标签页，展示数值与日期）
│   ├── options_menu.tscn      # 选项菜单（Game/Display/Controls 三栏标签页）
│   ├── single_player.tscn     # 单人游戏主场景（Background / GameBoard / UI / StateMachine / DemoController）
│   ├── music_player.tscn      # 背景音乐播放器（AudioStreamPlayer + music_player.gd）
│   └── jewel.tscn             # 宝石预制体（Sprite2D + jewel.gd）
├── scripts/
│   ├── jewel_data.gd          # JewelType 枚举 + 颜色/纹理/TileSourceId 映射
│   ├── jewel.gd               # 单个宝石节点（纹理、消除缩放动画、下落位移动画）
│   ├── active_column.gd       # 当前受控柱子的数据模型与循环切换逻辑
│   ├── grid_lines.gd          # Node2D 绘制 6×13 网格线
│   ├── game_manager.gd        # 核心状态机、输入处理、消除算法、重力坍塌、分数系统、SFX 生成
│   ├── settings_manager.gd    # 全局 Autoload 单例：设置持久化（user://settings.json）
│   ├── leaderboard_manager.gd # 全局 Autoload 单例：排行榜数据持久化（user://leaderboard.json）
│   ├── start_menu.gd          # 开始菜单按钮逻辑 + 15秒闲置自动进入排行榜
│   ├── leaderboard.gd         # 排行榜 UI 逻辑与列表刷新
│   ├── options_menu.gd        # 选项菜单 UI 逻辑与键位重映射
│   ├── music_player.gd        # 背景音乐播放（循环播放 assets/music/bgm.mp3）
│   ├── hint_manager.gd        # 提示系统：在当前游戏板上标记可消除位置（黄色闪烁方框）
│   ├── hint_calculator.gd     # 提示计算：枚举所有排列与落点，模拟消除与连锁
│   ├── hint_mode.gd           # 提示模式枚举（AllMatches / RandomMatch / MaxScore / MaxCleared）
│   ├── placement_result.gd    # 提示模拟结果的数据结构
│   ├── demo_state.gd          # Demo 模式全局状态标记（static var is_demo）
│   ├── demo_controller.gd     # Demo 模式 AI 控制器（自动移动/循环/软降）
│   ├── pause_menu.gd          # 暂停菜单（Resume / Restart / Quit to Menu）
│   ├── grid.gd                # 网格数据结构（PackedInt32Array 封装）
│   └── board_utils.gd         # 网格坐标转换与碰撞检测工具函数
├── tools/
│   └── generate_jewels.py     # 使用 PIL 生成 7 种宝石纹理（192×192 PNG，运行时缩放）
└── assets/
    ├── jewels/                # 7 种宝石纹理（jewel_red/blue/green/yellow/purple/orange/magic.png）
    ├── backgrounds/           # 背景砖墙纹理（bg_brick.png）
    ├── fonts/                 # PressStart2P-Regular.ttf（像素风格字体）
    ├── music/                 # 背景音乐（bgm.mp3）+ 未使用的 Faith - Invasion!.ogg
    ├── sounds/                # （当前为空，SFX 由程序实时生成）
    └── shaders/               # （当前为空）
```

---

## 架构与核心设计

### 1. 网格与数据结构
- **网格尺寸**: `6 列 × 13 行`
- **格子大小**: `48 px`
- **左上角为原点 `(0,0)`**，最底行为 `12`。
- 逻辑层使用 `Grid` 类（内部为 `PackedInt32Array`，大小固定 `6*13=78`）表示网格状态，通过 `get_cell/set_cell` 访问，比 `Dictionary[Vector2i, int]` 更省内存、duplicate 更快。
- 视觉层使用 `Jewel`（Sprite2D）节点和 `TileMapLayer`（`BoardLayer`）混合渲染：
  - **已锁定宝石**：使用 `TileMapLayer` 批量渲染，显著减少运行时的节点数量。
  - **ActiveColumn / NextPreview / 动画特效**：使用独立的 `Sprite2D` 节点（`jewel.gd`），以便进行实时位置控制、消除缩放、下落插值等动画效果。
  - 动画结束后，临时 `Jewel` 节点被销毁，对应状态由 `BoardLayer`（TileMapLayer）接管。

### 2. Timer 驱动状态机
`game_manager.gd` 使用 `enum State` 和多个 `Timer` 驱动游戏节奏，避免在 `_Process` 中手动累积 `delta`：

```
FALLING   → LOCKING → CHECKING ──(无匹配)──→ FALLING (生成新柱子)
                        ↓
                    CLEARING → COLLAPSING → CHECKING (循环检测连锁反应)
```

- **FALLING**: `FallTimer` 驱动 `ActiveColumn` 自动下落。基础间隔为 `0.8s`，随等级提升缩短（公式：`maxf(0.05, 0.8 - level * 0.07)`）。
- **LOCKING**: 触底后启动 `LockTimer(0.5s)`，期间仍可移动/循环；若移出底部则恢复为 FALLING。
- **CHECKING**: 扫描整个网格的纵/横/双斜向匹配。
- **CLEARING**: 播放消除动画，累计分数和消除数量。
- **COLLAPSING**: 上方宝石下落填充空位，再次进入 CHECKING 直到无连锁。
- **GAME_OVER**: 顶部溢出时触发，按 `ui_accept`（空格/回车/手柄 A）重启当前场景。

### 3. 消除算法
扫描 4 个方向向量：`(1,0)` 横向、`(0,1)` 纵向、`(1,1)` 右斜、`(1,-1)` 左斜。对每个非空格子向每个方向统计连续同色长度，`≥3` 时加入 `Dictionary`（以 `Vector2i` 为键，去重）统一消除。

### 4. 分数与等级系统
- **等级提升**: 每消除 35 颗宝石升 1 级。
- **连锁倍率**: `chain_multiplier = 1 << _chain_count`（即 1, 2, 4, 8...）。
- **单次消除得分**: `count * 10 * (_level + 1) * chain_multiplier`。
- **UI 数字滚动**: `ScoreValue` 和 `JewelsValue` 使用平滑插值（`display += (target - display) * delta * 14`），避免瞬间跳变。

### 5. 动画使用 async/await
`Jewel.play_clear()` 和 `animate_fall()` 使用 `await tween.finished` 协程。`GameManager` 在 `on_clear_timer_timeout()` 与 `apply_gravity()` 中使用 `await get_tree().create_timer(delay).timeout` 等待批量动画完成。临时动画节点在动画结束后被销毁，对应的宝石状态由 `BoardLayer`（TileMapLayer）接管。

### 6. 输入系统
使用自定义 `InputMap` 动作，不依赖 Godot 默认 UI 动作：
- `move_left` / `move_right`: 水平移动
- `cycle`: 循环切换宝石顺序 `[A,B,C] → [C,A,B]`
- `soft_drop`: 软降加速（将 `FallTimer` 间隔临时设为 `0.05s`）

为避免手柄摇杆持续触发导致移动过快，摇杆持续输入在 `_Process` 中轮询，并带有 **`0.18s` 冷却时间**。键盘按键和手柄按钮仍保持即时单次触发（在 `_UnhandledInput` 中处理）。

### 7. 提示系统 (HintManager)
`HintManager` 在 `single_player.tscn` 中作为 `GameBoard/HintLayer` 的子节点存在，默认模式为 `HintMode.Mode.MAX_CLEARED`。
- `HintCalculator.calculate()` 枚举当前 `ActiveColumn` 的所有唯一排列和可落点列。
- 对每个落点进行完整模拟（包括消除、重力坍塌、连锁反应），计算总消除数和总得分。
- `HintManager` 根据 `HintMode` 选择最优结果，并在对应格子位置绘制黄色闪烁方框标记。
- 提示仅在 `FALLING` 和 `LOCKING` 状态下刷新，其他状态自动清除。
- **HintMode 选项菜单映射**（OptionsMenu 中的索引）：
  - `0` = Off（不在 enum 中，实际表现为 `select_positions` 的 `match` 无命中，返回空数组）
  - `1` = ALL_MATCHES
  - `2` = RANDOM_MATCH
  - `3` = MAX_SCORE
  - `4` = MAX_CLEARED

### 8. 音效系统
- **BGM**: `MusicPlayer`（Autoload）循环播放 `assets/music/bgm.mp3`。
- **SFX**: `GameManager` 在 `setup_sfx()` 中通过 `generate_tone()` / `generate_clear_sound()` 实时生成 `AudioStreamWAV`：
  - `cycle`: 880Hz 短音（0.08s）
  - `lock`: 330Hz 短音（0.12s）
  - `clear`: 三和弦琶音（523.25Hz / 659.25Hz / 783.99Hz，0.25s）
- `assets/sounds/` 目录当前为空，所有音效均为程序生成。
- **提示系统缓存**：`HintManager` 对 `HintCalculator.calculate()` 的结果做 100ms 冷却 + 缓存，避免软降时频繁重算。
- **Demo AI 决策缓存**：`DemoController` 对每个 `ActiveColumn` 生命周期只计算一次最优落点，cycle 后或新柱子生成时才重算。
- **临时 Jewel 节点池**：`GameManager` 维护 `_jewel_pool`，消除动画和重力坍塌动画的 `Jewel` 节点不再直接 `queue_free()`，而是回收复用。
- `assets/music/Faith - Invasion!.ogg` 存在于目录但**未被代码引用**。

### 9. 设置持久化 (SettingsManager)
`SettingsManager` 是在 `project.godot` 中注册的 **Autoload 单例**。
- 持久化文件: `user://settings.json`
- 首次启动或配置文件缺失/损坏时，会自动写入默认设置与绑定。
- 支持：难度（当前仅有 "normal"）、分辨率（4 档）、窗口模式（窗口/全屏/无边框全屏）、VSync、HintMode、键位/手柄映射。
- 自定义绑定序列化格式：`K|keycode`、`JB|buttonIndex`、`JM|axis|value`，以 `;` 分隔。

### 10. 排行榜系统 (LeaderboardManager)
`LeaderboardManager` 是在 `project.godot` 中注册的 **Autoload 单例**。
- 持久化文件: `user://leaderboard.json`
- 保存内容：分数榜与消除数榜，各保留前 **10 条**记录（降序）。
- 每条记录包含 `value`（数值）与 `timestamp`（达成时间，本地时间 ISO 8601 格式）。
- **入口**: StartMenu 上的 "Leaderboard" 按钮，或**闲置 15 秒**自动跳转（`idle_timer`）。
- 游戏结束时（`enter_game_over`）自动写入本次的分数与消除数。

### 11. Demo 模式
- **入口**: StartMenu 上的 "Demo" 按钮。
- **状态**: 由 `DemoState.is_demo`（static bool）全局标记。
- **行为**: `DemoController` 接管输入，使用 `HintCalculator` 计算最佳落点，自动执行循环、水平移动和软降（等级 < 8 时启用软降）。
- **退出**: 玩家按下任意键/按钮时立即退出 Demo，返回 StartMenu。
- **游戏场景**: `single_player.tscn` 中的 `DemoController` 节点读取 `DemoState.is_demo` 并设置 `GameManager.is_demo_mode = true`。

### 12. 暂停菜单 (PauseMenu)
`single_player.tscn` 中的 `UI/PauseMenu` 节点，使用 `process_mode = 3`（PROCESS_MODE_ALWAYS）保证在暂停时仍能响应输入。
- 触发键：`ui_cancel`（Esc）或手柄 `START` 键。
- 提供 Resume、Restart、Quit to Menu 三个选项。
- Demo 模式下禁止暂停。

---

## 代码风格规范

### 语言与格式
- **GDScript**
- 文件编码：**UTF-8**（`.editorconfig` 已声明 `charset = utf-8`）
- 行尾符：Git 配置为 `* text=auto eol=lf`，请保持 LF。
- 使用 **4 空格缩进**。

### 命名约定
- 类/枚举/方法：**PascalCase**
- 局部变量/参数：**camelCase**
- 私有字段：**`_camelCase`**（以下划线开头）
- 常量：**PascalCase**（如 `CellSize`, `LockDelay`）

### GDScript 特定约定
- 使用文件作用域，无需 namespace。
- Godot 节点脚本类使用 `class_name` 注册全局类。
- 节点字段在 `_ready()` 中赋值，声明时无需可空标记。
- `await` / `Signal` 用于动画等待，避免回调地狱。
- 信号连接在 `_exit_tree()` 中断开，避免游离引用。

### 注意事项
- 新增 GDScript 脚本后，确保文件名使用 snake_case。
- 项目已全面迁移至 GDScript，**禁止重新引入 C# 依赖**。
- 修改纹理或场景后，建议在 Godot 编辑器中重新保存场景，确保 `uid` 和资源引用已刷新。

---

## 运行与调试

### 在 Godot 编辑器中运行
1. 使用 Godot 打开项目根目录。
2. 按 F5 运行主场景。
3. 主场景为 `start_menu.tscn`，流程：StartMenu → single_player（游戏）或 Demo。

### 常见调试快捷键
- `F5`: 运行项目
- `F6`: 运行当前场景
- `F8`: 停止

---

## 安全与部署

- **无网络通信**：这是一个纯本地单机游戏，没有联网、没有用户账户系统、没有敏感数据处理。
- **持久化位置**: `user://settings.json` 与 `user://leaderboard.json` 写入用户数据目录（平台相关，如 Windows 的 `%APPDATA%`）。
- **部署**: 标准 Godot 导出流程。`export_presets.cfg` 中已配置 Windows Desktop 预设，导出路径为 `build/Columns.exe`。

---

## 待扩展方向（供参考）

项目中已有明确的 TODO 记录（来自 `CLAUDE.md`）：
- 音效（移动、锁定、消除、升级）—— 目前已有基础程序生成 SFX
- 粒子特效（消除时的闪光/碎片）
- Hold（暂存柱子）功能
- 双人/联机对战
- `assets/music/Faith - Invasion!.ogg` 可作为备用 BGM 接入

---

*最后更新: 基于当前代码库实际内容生成。请勿在其中添加假设性信息。*

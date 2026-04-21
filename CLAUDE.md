<!-- From: e:\workspace\godot\columns\AGENTS.md -->
# Columns — Agent 开发指南

> 本文档面向 AI 编程助手。阅读前请确认你了解：这是一个基于 **Godot 4.6 (GDScript)** 的本地 Match-3 掉落式益智游戏，类似经典《Columns》。

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
- **Python**（可选，用于 tools/generate_jewels.py）
- **Python**: 如需使用 Python，请使用 **conda 中的 Python**。项目包含 `tools/generate_jewels.py` 用于生成宝石纹理。

### 构建说明
- 修改 GDScript 脚本后直接在 Godot 编辑器中运行即可，无需额外编译。
- Godot 编辑器会在保存时自动解析 GDScript。
- 场景中的 `ext_resource` 引用的是 `.gd` 脚本。

### 无测试套件
- 当前项目 **没有任何自动化测试**（无单元测试、无集成测试、无 CI 配置）。
- 所有验证依赖在 Godot 编辑器中直接运行场景（F5 / 播放按钮）进行手工测试。

---

## 目录结构与核心文件

```
res://
├── project.godot              # Godot 项目配置
├── columns.csproj             # （已废弃，原 C# 项目文件）
├── .editorconfig              # 编码声明: charset = utf-8
├── .gitattributes             # LF 行尾: * text=auto eol=lf
├── scenes/
│   ├── start_menu.tscn        # 开始菜单（Start / Options / Quit）
│   ├── options_menu.tscn      # 选项菜单（分辨率、窗口模式、VSync、键位映射）
│   ├── single_player.tscn     # 单人游戏场景（UI、GameBoard、BoardLayer、StateMachine、Timer）
│   ├── music_player.tscn      # 背景音乐播放器（AudioStreamPlayer + MusicPlayer.cs）
│   └── jewel.tscn             # 宝石预制体（Sprite2D + Jewel.cs）
├── scripts/
│   ├── jewel_data.gd          # JewelType 枚举 + 颜色/纹理/TileSourceId 映射
│   ├── jewel.gd               # 单个宝石节点（纹理、消除动画、下落动画）
│   ├── active_column.gd       # 当前受控柱子的数据模型与循环切换逻辑
│   ├── grid_lines.gd          # Node2D 绘制 6×13 网格线
│   ├── game_manager.gd        # 核心状态机、输入处理、消除算法、重力坍塌、分数系统、SFX 生成
│   ├── settings_manager.gd    # 全局 Autoload 单例：设置持久化（user://settings.json）
│   ├── start_menu.gd          # 开始菜单按钮逻辑
│   ├── options_menu.gd        # 选项菜单 UI 逻辑与键位重映射
│   ├── music_player.gd        # 背景音乐播放（循环播放 assets/music/bgm.mp3）
│   ├── hint_manager.gd        # 提示系统：在当前游戏板上标记可消除位置
│   ├── hint_calculator.gd     # 提示计算：枚举所有排列与落点，模拟消除与连锁
│   ├── hint_mode.gd           # 提示模式枚举（AllMatches / RandomMatch / MaxScore / MaxCleared）
│   └── placement_result.gd    # 提示模拟结果的数据结构
├── tools/
│   └── generate_jewels.py     # 使用 PIL 生成 7 种宝石纹理（48×48 PNG）
└── assets/
    ├── jewels/                # 7 种宝石纹理（jewel_red/blue/green/yellow/purple/orange/magic.png）
    ├── backgrounds/           # 背景砖墙纹理（bg_brick.png）
    ├── fonts/                 # PressStart2P-Regular.ttf（像素风格字体）
    ├── music/                 # 背景音乐（bgm.mp3）
    ├── sounds/                # （当前为空，SFX 由程序实时生成）
    └── shaders/               # （当前为空）
```

---

## 架构与核心设计

### 1. 网格与数据结构
- **网格尺寸**: `6 列 × 13 行`
- **格子大小**: `48 px`
- **左上角为原点 `(0,0)`**，最底行为 `12`。
- 逻辑层使用 `Dictionary[Vector2i, int]` 表示网格状态。
- 视觉层使用 `Jewel`（Sprite2D）节点和 `TileMapLayer`（`BoardLayer`）混合渲染：
  - **已锁定宝石**：使用 `TileMapLayer` 批量渲染，显著减少运行时的节点数量。
  - **ActiveColumn / NextPreview / 动画特效**：使用独立的 `Sprite2D` 节点（`jewel.gd`），以便进行实时位置控制、消除缩放、下落插值等动画效果。
  - 动画结束后，临时 `Jewel` 节点被销毁，对应状态由 `BoardLayer` 接管。

### 2. Timer 驱动状态机
`game_manager.gd` 使用 `enum State` 和多个 `Timer` 驱动游戏节奏，避免在 `_Process` 中手动累积 `delta`：

```
FALLING   → LOCKING → CHECKING ──(无匹配)──→ FALLING (生成新柱子)
                        ↓
                    CLEARING → COLLAPSING → CHECKING (循环检测连锁反应)
```

- **FALLING**: `FallTimer` 驱动 `ActiveColumn` 自动下落。
- **LOCKING**: 触底后启动 `LockTimer(0.5s)`，期间仍可移动/循环。
- **CHECKING**: 扫描整个网格的纵/横/双斜向匹配。
- **CLEARING**: 播放消除动画，累计分数和消除数量。
- **COLLAPSING**: 上方宝石下落填充空位，再次进入 CHECKING 直到无连锁。
- **GAME_OVER**: 顶部溢出时触发，按 `ui_accept`（空格/回车/手柄 A）重启场景。

### 3. 消除算法
扫描 4 个方向向量：`(1,0)` 横向、`(0,1)` 纵向、`(1,1)` 右斜、`(1,-1)` 左斜。对每个非空格子向每个方向统计连续同色长度，`≥3` 时加入 `HashSet<Vector2I>` 统一消除。

### 4. 动画使用 async/await
`Jewel.play_clear()` 和 `animate_fall()` 使用 `await tween.finished` 协程。`GameManager` 在 `on_clear_timer_timeout()` 与 `apply_gravity()` 中使用 `await get_tree().create_timer(delay).timeout` 等待批量动画完成。临时动画节点在动画结束后被销毁，对应的宝石状态由 `BoardLayer`（TileMapLayer）接管。

### 5. 输入系统
使用自定义 `InputMap` 动作，不依赖 Godot 默认 UI 动作：
- `move_left` / `move_right`: 水平移动
- `cycle`: 循环切换宝石顺序 `[A,B,C] → [C,A,B]`
- `soft_drop`: 软降加速

为避免手柄摇杆持续触发导致移动过快，摇杆持续输入在 `_Process` 中轮询，并带有 **`0.18s` 冷却时间**。键盘按键和手柄按钮仍保持即时单次触发（在 `_UnhandledInput` 中处理）。

### 6. 提示系统 (HintManager)
`HintManager` 在 `single_player.tscn` 中作为 `GameBoard` 的子节点存在，默认模式为 `HintMode.MaxCleared`。
- `HintCalculator.Calculate()` 枚举当前 `ActiveColumn` 的所有唯一排列和可落点列。
- 对每个落点进行完整模拟（包括消除、重力坍塌、连锁反应），计算总消除数和总得分。
- `HintManager` 根据 `HintMode` 选择最优结果，并在对应格子位置绘制黄色闪烁方框标记。
- 提示仅在 `FALLING` 和 `LOCKING` 状态下刷新，其他状态自动清除。

### 7. 音效系统
- **BGM**: `MusicPlayer`（Autoload）循环播放 `assets/music/bgm.mp3`。
- **SFX**: `GameManager` 在 `SetupSfx()` 中通过 `GenerateTone()` / `GenerateClearSound()` 实时生成 `AudioStreamWav`：
  - `cycle`: 880Hz 短音
  - `lock`: 330Hz 短音
  - `clear`: 三和弦琶音（523.25Hz / 659.25Hz / 783.99Hz）
- `assets/sounds/` 目录当前为空，所有音效均为程序生成。

### 8. 设置持久化 (SettingsManager)
`SettingsManager` 是在 `project.godot` 中注册的 **Autoload 单例**。
- 持久化文件: `user://settings.json`
- 首次启动或配置文件缺失/损坏时，会自动写入默认设置与绑定。
- 支持：难度、分辨率（4 档）、窗口模式（窗口/全屏/无边框全屏）、VSync、键位/手柄映射。
- 自定义绑定序列化格式：`K|keycode`、`JB|buttonIndex`、`JM|axis|value`，以 `;` 分隔。

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
- GDScript 类无需 `partial` 关键字。
- 节点字段在 `_ready()` 中赋值，声明时无需可空标记。
  ```csharp
  private Node2D _jewelContainer = null!;
  ```
- `await` / `Signal` 用于动画等待，避免回调地狱。

### 注意事项
- 新增 GDScript 脚本后，确保文件名使用 snake_case。
- 项目已全面迁移至 GDScript。
- 修改纹理或场景后，建议在 Godot 编辑器中重新保存场景，确保 `uid` 和资源引用已刷新。

---

## 运行与调试

### 在 Godot 编辑器中运行
1. 使用 Godot 打开项目根目录。
2. 按 F5 运行主场景。
3. 主场景为 `start_menu.tscn`，流程：StartMenu → single_player（游戏）。

### 常见调试快捷键
- `F5`: 运行项目
- `F6`: 运行当前场景
- `F8`: 停止

---

## 安全与部署

- **无网络通信**：这是一个纯本地单机游戏，没有联网、没有用户账户系统、没有敏感数据处理。
- **持久化位置**: `user://settings.json` 写入用户数据目录（平台相关，如 Windows 的 `%APPDATA%`）。
- **部署**: 标准 Godot 导出流程。

---

## 待扩展方向（供参考）

项目中已有明确的 TODO 记录（来自 `CLAUDE.md`）：
- 音效（移动、锁定、消除、升级）—— 目前已有基础程序生成 SFX
- 粒子特效（消除时的闪光/碎片）
- 高分记录本地存储
- Hold（暂存柱子）功能
- 双人/联机对战

---

*最后更新: 基于当前代码库实际内容生成。请勿在其中添加假设性信息。*

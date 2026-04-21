# Columns 益智游戏实现计划

## Context
用户希望在一个全新的 Godot 4.x 项目中实现一个类《Columns》（俄罗斯宝石）的 Match-3 掉落式益智游戏。需求文档详细说明了网格、数据结构、输入控制、消除逻辑、物理状态机和难度系统。

## 推荐方案
使用纯 GDScript 实现，场景结构简洁：一个主场景包含游戏板、UI 层和状态机脚本。不使用 TileMap（因为需要动态控制每个宝石的精灵和动画），改用 `GridContainer` 或基于 Node2D 的坐标系统，配合二维数组记录网格状态。

### 1. 场景树结构
```
Main (Node)
├── GameBoard (Node2D)
│   ├── GridBackground (ColorRect / Sprite2D)  # 可选，显示网格背景
│   ├── JewelContainer (Node2D)                # 所有静态宝石的父节点
│   └── ActiveColumnContainer (Node2D)         # 当前下落柱的父节点
├── UI (CanvasLayer)
│   ├── ScoreLabel (Label)
│   ├── LevelLabel (Label)
│   └── GameOverLabel (Label, 默认隐藏)
├── StateMachine (Node)  ← 挂载主脚本 GameManager.gd
│   ├── FallTimer (Timer)
│   ├── LockTimer (Timer)
│   ├── ClearTimer (Timer)
│   └── CollapseTimer (Timer)
```

### 2. 文件与职责

| 文件 | 职责 |
|------|------|
| `scripts/game_manager.gd` | 主状态机、网格管理、输入分发、分数/等级计算 |
| `scripts/jewel_data.gd` | 枚举 `JewelType`、颜色映射、辅助函数 |
| `scripts/active_column.gd` | 封装当前受控柱的数据（3个宝石类型、网格坐标）和逻辑 |
| `scripts/jewel.gd` | 单个宝石的 Sprite2D 扩展，处理消除动画、下落动画 |
| `scenes/main.tscn` | 主场景 |
| `scenes/jewel.tscn` | 宝石预制体（Sprite2D + 脚本）|

### 3. 关键数据结构

**`jewel_data.gd`**
```gdscript
enum JewelType { EMPTY = -1, RED, BLUE, GREEN, YELLOW, PURPLE, ORANGE, MAGIC }
const COLORS = {
    JewelType.RED: Color.RED,
    ...
}
```

**`game_manager.gd`**
```gdscript
const COLS = 6
const ROWS = 13
var grid: Array[Array] = []  # grid[col][row] = JewelType
var jewel_nodes: Array[Array] = []  # 对应 Sprite2D 引用，null 表示空
```

### 4. 状态机实现

使用 `enum State { FALLING, LOCKING, CHECKING, CLEARING, COLLAPSING, GAME_OVER }`，由 Timer 驱动状态转换：

- **FALLING**: `FallTimer` 每隔 `fall_interval` 秒触发，让 `ActiveColumn` 下移一格。玩家输入在此状态下实时响应。
- **LOCKING**: 当 `ActiveColumn` 触碰到底部或已有宝石时，启动 `LockTimer`（约 0.3s）。期间玩家仍可移动/循环。计时器超时后将 3 颗宝石写入 `grid` 和 `jewel_nodes`，切换到 CHECKING。
- **CHECKING**: 调用 `find_matches()`，若有匹配则进入 CLEARING，否则生成新柱或判负（顶部溢出即 GAME_OVER）。
- **CLEARING**: 启动 `ClearTimer`（约 0.2s），播放消除动画，同时累加分数和等级。超时后进入 COLLAPSING。
- **COLLAPSING**: 启动 `CollapseTimer`（约 0.1s/格），让悬空宝石逐格下落。超时后回到 CHECKING（检测连锁）。

### 5. 输入处理

在 `game_manager.gd` 的 `_unhandled_input(event)` 中处理：
- `ui_left` / `ui_right`: 尝试水平移动 `ActiveColumn`（需做边界和碰撞检测）。
- `ui_up` / `ui_accept` (Space): 循环切换 `ActiveColumn` 的宝石顺序。
- `ui_down`: 软降，临时将 `FallTimer.wait_time` 设为更快值（如 0.05s），松开时恢复。

### 6. 匹配检测算法

使用方向向量扫描法：
```gdscript
var dirs = [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,-1)]
```
对网格中每个非空格子，沿 4 个方向统计连续同色长度。长度 >= 3 时，将整条线段坐标加入 `to_remove: Dictionary[Vector2i, bool]`。扫描结束后统一清除。

复杂度：O(COLS * ROWS * 4 * max(COLS,ROWS))，对于 6x13 网格可忽略不计。

### 7. 重力坍塌逻辑

按列处理：
```gdscript
for col in range(COLS):
    var write_row = ROWS - 1
    for row in range(ROWS - 1, -1, -1):
        if grid[col][row] != JewelType.EMPTY:
            if write_row != row:
                # 移动数据
                grid[col][write_row] = grid[col][row]
                grid[col][row] = JewelType.EMPTY
                # 移动节点并播放下落动画
                ...
            write_row -= 1
```

### 8. 速度公式

```gdscript
var level = 0
var jewels_cleared = 0
var base_interval = 0.8

func update_speed():
    level = jewels_cleared / 35
    fall_interval = max(0.05, base_interval - level * 0.07)
    FallTimer.wait_time = fall_interval
```

### 9. 文件夹结构
```
res://
├── scenes/
│   ├── main.tscn
│   └── jewel.tscn
├── scripts/
│   ├── game_manager.gd
│   ├── jewel_data.gd
│   ├── active_column.gd
│   └── jewel.gd
├── assets/
│   └── (placeholder textures or colored squares)
├── project.godot
└── icon.svg
```

### 10. 验证方式
1. 在 Godot 编辑器中打开项目，运行 `main.tscn`。
2. 测试基础控制：左右移动、循环切换（观察颜色顺序变化）、软降加速。
3. 测试消除：手动排列出横向、纵向、斜向三连，确认消除和重力坍塌正常。
4. 测试连锁：构造能引发多次连锁的布局，观察状态机循环。
5. 测试难度：持续消除宝石，观察下落速度是否随等级提升而加快。
6. 测试 Game Over：堆满到顶行，确认游戏结束。

## 设计权衡
- **不使用 TileMap**：TileMap 更适合瓦片地图，而本游戏每个宝石需要独立的动画（消除闪光、下落插值）和可能的后续特效，使用 Sprite2D 节点更灵活。
- **Timer 驱动而非 `_process` 逐帧计算**：保证逻辑与渲染帧率解耦，消除和坍塌的节奏更稳定，也更适合后续加入联网同步。

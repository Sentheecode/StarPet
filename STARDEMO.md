# 星露谷风格竖屏演示场景

## 场景结构

### 1. 项目设置 (project.godot)
```
[display]
viewport_width=400
viewport_height=720
window/size/viewport_width=400
window/size/viewport_height=720
```

### 2. 场景元素建议

**背景层 (z-index: 0)**
- 草地/农田背景
- 天空渐变

**中层 (z-index: 1-10)**
- 农作物 (玉米、南瓜、萝卜等)
- 围栏
- 水井
- 仓库

**前层 (z-index: 20+)**
- 玩家角色
- 宠物

**UI层**
- 顶部状态栏 (金币、时间)
- 底部工具栏

### 3. 素材建议

使用 Star-Office-UI 素材：
- office_bg.png → 改造为农田背景
- plants.png → 农作物
- desk.png → 可改为仓库

需要我帮你创建哪个部分？
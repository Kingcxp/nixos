# NixOS 使用指南

这份指南假设你对 NixOS 完全陌生。读完它，你会理解 NixOS 的核心理念，
知道怎么日常使用、装软件、改配置、排查问题。

---

## 1. NixOS 和其他 Linux 有什么不同？

传统 Linux（如 Arch）的软件装在"系统里"，配置分散在 `/etc`、`~/.config`，
升级和卸载经常互相影响。

NixOS 的核心是**声明式配置**：

- 整个系统（装了哪些软件、开了哪些服务、写了什么配置）都由一个"配方"
  （本仓库的 `flake.nix` + 各个 `.nix` 文件）描述。
- 你**不改文件、不手动装包**，而是改配方，然后执行一次 `nixos-rebuild switch`。
- Nix 会构建一套完整的新系统（所有依赖都在 `/nix/store` 里，互不打架），
  然后把当前系统切换过去。旧系统还在，随时可以回滚。

好处：系统状态完全由仓库决定、可复现、可回滚、可在一台新机器上重建。

---

## 2. 日常最常用的命令

这些是你在桌面上最常用的（本仓库已把 `fish` 设为默认 shell，
并在 `home-manager/fish.nix` 里加了 `update` 别名）：

```fish
# 改完配置后应用（最常用！）—— 等价于 sudo nixos-rebuild switch --flake /etc/nixos#thinkbook
update

# 完整写法（不依赖别名时）
sudo nixos-rebuild switch --flake /etc/nixos#thinkbook

# 只构建不切换（先看看会不会出错，安全）
sudo nixos-rebuild build --flake /etc/nixos#thinkbook

# 干跑：检查配置是否有效、会构建什么，不实际安装
sudo nixos-rebuild dry-run --flake /etc/nixos#thinkbook
```

> `/etc/nixos` 是仓库的**符号链接**（安装时创建），指向本仓库。
> 所以改的是仓库文件，`switch` 时 NixOS 读的就是它们。

**Home Manager（用户级配置）**：本仓库的桌面、应用配置大多是 Home Manager
管理的，`nixos-rebuild switch` 会同时应用它们，不需要单独的命令。

---

## 3. 系统配置与用户配置在哪

| 位置 | 管什么 | 举例 |
| --- | --- | --- |
| `hosts/thinkbook/` | 这台机器的系统级设置 | 内核、TLP 电源、硬件 |
| `modules/software/system/main.nix` | 系统基础策略 | 用户、git、fwupd、nix 设置 |
| `modules/software/desktop/` | 桌面系统组件 | greetd 登录、niri 合成器 |
| `home-manager/` | 用户级软件和配置 | kitty、waybar、nvim、fish 等 |
| `home-manager/desktop/niri/config/*.kdl` | niri 窗口管理器配置 | 快捷键、输出、布局 |

改完任何 `.nix` 文件后，执行 `update` 生效。

---

## 4. 怎么装/卸载软件（新手最容易困惑的部分）

NixOS 上有**两种**装软件的方式：

### 方式 A：声明式（推荐，跟着仓库走）

想长期使用某个软件，就把它写进配置里，然后 `update`：

1. 打开 `home-manager/applications.nix`（用户级软件）或
   `modules/software/system/main.nix`（系统级软件）
2. 在 `home.packages` / `environment.systemPackages` 里加一行，例如：

```nix
# home-manager/applications.nix
home.packages = with pkgs; [
  # ...已有的...
  ripgrep   # 新增：rg 搜索工具
  fd        # 新增：更友好的 find
];
```

3. 保存，执行 `update`。软件装好，卸载就删掉那一行再 `update`。

> 找包名用网页搜索 <https://search.nixos.org/packages>，
> 或命令行 `nix search nixpkgs <关键词>`。

### 方式 B：临时使用（不写入配置）

只是想试试某个软件，不用改配置：

```bash
# 直接运行一个包，不安装
nix run nixpkgs#btop

# 进入一个带有该软件的环境（退出即消失）
nix shell nixpkgs#ripgrep nixpkgs#fd
```

没有 root、不影响系统、用完即弃。

---

## 5. 本仓库已经装好的常用软件

装完系统后你已经有这些（全部来自 `home-manager/` 和 `modules/`）：

| 软件 | 用途 | 怎么启动 |
| --- | --- | --- |
| niri | 平铺式 Wayland 合成器（桌面） | 登录后自动进入 |
| waybar | 顶部状态栏（含电池/音量/亮度/网络） | 自动启动 |
| kitty | 终端 | `SUPER+Q` |
| wofi | 应用启动器 | `SUPER+R` |
| firefox | 浏览器 | `SUPER+F` |
| dolphin | 文件管理器 | `SUPER+E` |
| fish | 默认 shell | 打开终端即用 |
| nvim / micro / nano | 编辑器 | `nvim` / `micro` / `nano` |
| yazi | 终端文件管理器 | `yazi` |
| btop | 系统监控 | `btop`，或在 waybar 点 CPU/内存 |
| tmux | 终端复用 | `tmux` |
| dunst | 通知守护 | 自动运行 |
| wlogout | 注销/关机菜单 | `SUPER+M` |
| powertop | 电源管理 | waybar 电池右键菜单 |

### 快捷键速查（niri，来自 `bind.kdl`）

| 按键 | 动作 |
| --- | --- |
| `SUPER+Q` | 打开终端 (kitty) |
| `SUPER+R` | 运行程序 (wofi) |
| `SUPER+F` | 打开浏览器 (firefox) |
| `SUPER+E` | 打开文件管理器 (dolphin) |
| `SUPER+C` | 关闭窗口 |
| `SUPER+M` | 注销菜单 (wlogout) |
| `SUPER+V` | 切换窗口浮动 |
| `SUPER+P` | 截图 |
| `ALT+Tab` | 在最近两个工作区之间切换 |
| `SUPER+1..9` | 切换工作区 |
| `SUPER+Shift+1..9` | 移动窗口到工作区 |
| `SUPER+左/右/H/L` | 焦点左右移动 |
| `SUPER+上/下/J/K` | 焦点上下移动 |
| `SUPER+Delete` | 锁屏 (swaylock) |

### 音量 / 亮度

- 音量：`XF86AudioRaiseVolume/LowerVolume`（Fn 键），或 waybar 音量模块滚动
- 亮度：`XF86MonBrightnessUp/Down`（Fn 键），或 waybar 亮度模块滚动
  最低亮度已钳制在 5%，不会黑屏

---

## 6. 常用软件的中文使用要点

### fish（shell + oh-my-posh）
- 配置在 `home-manager/fish.nix`；提示符由 **oh-my-posh** 渲染，主题为
  Catppuccin Macchiato 配色的 clean-detailed 定制版。
- 提示符信息：完整路径、Git 分支、退出码（成功 `✔`，失败显示错误码）、
  执行耗时、当前项目语言（Python/Node/Go/Rust 自动检测）。
- 插件**声明式管理**（`programs.fish.plugins`，来自 nixpkgs fishPlugins）：
  fzf-fish（Ctrl+R 历史搜索）、done（长命令完成通知）、forgit、colored-man-pages。
- 辅助工具：fzf、fd、bat、eza、zoxide（`z` 智能跳转）、ripgrep、tldr。
- 想加别名/环境变量，编辑 `fish.nix` 的 `shellInit` 后 `update`。
- **关于 fisher**：NixOS 上不推荐用 fisher。fisher 会在运行时改写
  `~/.config/fish`，与 Nix 的声明式、可复现理念冲突；home-manager 的
  `programs.fish.plugins` 已能声明式安装同样插件（升级、回滚随系统走）。
  在 Arch 等传统发行版上使用 fisher 则是正常的。

### nvim（AstroNvim）
- 配置在 `home-manager/nvim/config/`（你的原配置，插件由 lazy.nvim 自动安装）
- 首次启动会自动装插件，稍等片刻
- 快捷键多为 `SPACE` 开头（Space + e 文件树、Space + f f 查找等）

### git
- 系统已配好 `programs.git`（user 名/邮箱在 `modules/software/system/main.nix`）
- 直接 `git clone/push` 即可

### tmux
- 配置在 `home-manager/tmux/default.nix`（catppuccin 主题 + cpu/电池模块）
- `tmux` 进入，`Ctrl+b` 前缀，`Ctrl+b d` 脱离，`tmux attach` 回来

---

## 7. 升级系统（更新包）

```bash
# 用 flake.lock 锁定的旧版本升级（不改变 lock）
sudo nixos-rebuild switch --flake /etc/nixos#thinkbook

# 更新 lock（拉取 nixpkgs 最新）再升级
cd /etc/nixos
sudo nix flake update
sudo nixos-rebuild switch --flake /etc/nixos#thinkbook
```

> 本仓库的 `flake.lock` 锁定了精确版本，**经过验证可一起构建**。
> 升级前建议 `sudo nixos-rebuild dry-run` 先看结果；遇错可回滚（见下）。

---

## 8. 出问题了怎么办（回滚 / 修复）

NixOS 每个切换都会留一个可启动的旧系统（生成器列表）：

```bash
# 查看所有历史系统快照
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# 回滚到上一个
sudo nixos-rebuild rollback

# 回滚到指定代
sudo nix-env --switch-generation 42 -p /nix/var/nix/profiles/system
```

**如果系统起不来了**：开机引导菜单里有之前所有系统的条目，选一个旧的就能进。

### 清理垃圾（回收磁盘）

```bash
# 看占了多少
sudo nix-store --gc

# 删除 14 天前的旧系统（每周自动执行，这里手动触发）
sudo nix-collect-garbage -d
```

系统已配置每周自动 GC（见 `modules/software/system/main.nix`）。

---

## 9. 常见问题（FAQ）

**Q: 我想装一个不在仓库里的软件，怎么办？**
用 `nix run nixpkgs#名字` 临时用，或把它加进 `applications.nix` 长期用。
先在 <https://search.nixos.org/packages> 确认包名。

**Q: 配置改错了，`update` 报错，系统坏了吗？**
没有。出错时 `switch` 会拒绝应用，当前系统保持原样。修复配置再 `update`，
或 `sudo nixos-rebuild rollback`。

**Q: 为什么装个软件要下载那么多？**
Nix 会拉取该软件的所有依赖（严格隔离、不共享系统库），所以首次装包可能较大。
之后有缓存就不重复下载。

**Q: 我在仓库里改了配置，但 `update` 说没变化？**
确认保存了文件，且执行的是 `sudo nixos-rebuild switch --flake /etc/nixos#thinkbook`
（或 `update`）。`/etc/nixos` 必须指向本仓库。

**Q: nix 命令提示 `error: experimental Nix feature 'nix-command' is disabled`？**
系统级配置已启用（`nix.settings.experimental-features`），如仍遇到，
检查 `~/.config/nix/nix.conf` 或 `/etc/nix/nix.conf` 是否有
`experimental-features = nix-command flakes`。

**Q: 怎么改默认启动的桌面/登录方式？**
看 `modules/software/desktop/greetd.nix`（登录）和 `niri.nix`（桌面）。
要密码登录还是自动登录，改 `greetd.nix` 的 `default_session`/`initial_session`。

---

## 10. 学习资源

- NixOS 官方手册（推荐慢慢读）：<https://nixos.org/manual/nixos/stable/>
- 包搜索：<https://search.nixos.org/packages>
- 选项搜索（找配置项怎么写）：<https://search.nixos.org/options>
- NixOS 官方手册与包搜索：<https://nixos.org/manual/nixos/stable/>、<https://search.nixos.org/packages>

开始上手：改一个配置 → `update` → 观察效果。错了就 `rollback`，NixOS 最不怕折腾。
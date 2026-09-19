# NixOS Configurations — kingcq / ThinkBook

这是一个基于 Flake 的 NixOS 配置仓库，管理一台 ThinkBook 笔记本
（Intel i7-1160G7 / Iris Xe / NVMe / UEFI+GRUB）。它也是一个可读的示例，
展示如何把个人 NixOS 环境组织成声明式、可复现、可回滚的系统配置。

## 快速开始

克隆仓库，并让 `/etc/nixos` 指向它：

```bash
git clone https://github.com/Kingcxp/nixos.git
sudo rm -rf /etc/nixos
sudo ln -s "$PWD/nixos" /etc/nixos
```

重建当前主机：

```bash
sudo nixos-rebuild switch --flake /etc/nixos#thinkbook
```

配置里定义了一个名为 `update` 的 shell 别名（见 `home-manager/fish.nix`），
它执行：

```bash
sudo nixos-rebuild switch
```

直接使用 flake 时，建议始终用显式的 `--flake /etc/nixos#thinkbook` 形式，
这样始终清楚在重建哪台机器。

**首次安装**请先阅读《[安装教程](#安装教程)》与
《[VirtualBox 试装指南](VM-TEST.md)》。日常使用见
《[使用指南](USAGE.md)》。

## 学习路径

如果你正从这份配置学习 NixOS，按这个顺序阅读：

1. `flake.nix` —— 理解 inputs、outputs 与主机创建。
2. `hosts/thinkbook/default.nix` —— 看一台主机如何由模块组装。
3. `modules/software/system/main.nix` —— 学习基础系统策略。
4. `modules/hardware/main.nix` 及其导入的文件 —— 学习可复用的硬件默认值。
5. `hm-profile/niri-desktop.nix` 与 `home-manager/` —— 了解用户级配置。
6. `home-manager/desktop/niri/` —— 研究一个完整的 Wayland 桌面配置。

核心思想是职责分离：

- `flake.nix` 决定存在哪些主机。
- `hosts/` 决定每台主机导入什么。
- `modules/` 存放可复用的操作系统级构建块。
- `hm-profile/` 组装一个 Home Manager profile（当前是 Niri 桌面）。
- `home-manager/` 存放用户应用与 dotfiles。
- 硬件生成的文件紧挨着需要它的主机。

这样的结构让日常使用方便，也让配置更容易解释、复制和修改。

## 仓库结构

```text
.
|-- flake.nix
|-- flake.lock
|-- hm-profile/
|   `-- niri-desktop.nix            # 共享 Home Manager profile（Niri 桌面）
|-- hosts/
|   `-- thinkbook/                  # ThinkBook 14s（Intel i7-1160G7）
|       |-- default.nix             # 主机入口：导入 + 主机专属模块
|       |-- hardware-configuration.nix
|       `-- hardware/
|           `-- default.nix         # TLP、Intel 调优、thermald、fstrim
|-- modules/
|   |-- hardware/
|   |   |-- default.nix             # 汇总导入
|   |   |-- main.nix                # bootloader、内核、固件、文件系统助手
|   |   |-- network.nix             # NetworkManager、时区、主机名
|   |   |-- input.nix               # locale、字体、fcitx5、键盘
|   |   |-- bluetooth.nix           # 蓝牙与 Blueman
|   |   `-- pipewire.nix            # PipeWire 音频
|   `-- software/
|       |-- system/
|       |   `-- main.nix            # 基础系统策略与常用 CLI 工具
|       |-- desktop/
|       |   |-- greetd.nix          # 登录管理器（tuigreet）
|       |   |-- niri.nix            # niri 合成器与桌面服务
|       |   `-- dolphin-fix.nix     # Dolphin 文件管理器修复
|       `-- develop/
|           `-- ...                 # 开发工具（预留目录）
`-- home-manager/
    |-- core.nix                    # home 状态、keyring、深色主题
    |-- applications.nix            # firefox、dolphin、QQ 等 + mime 默认
    |-- fish.nix                    # fish + oh-my-posh 提示符 + 声明式插件
    |-- vscode/                     # VSCode 声明式扩展 + settings.json
    |-- jetbrains/                  # JetBrains IDEA 声明式安装
    |-- kitty/  micro/  btop/  yazi/
    |-- tmux/  nvim/                # tmux + nvim (AstroNvim) 配置
    |-- powertop/                   # powertop-toggle.sh + waybar 电池接线
    `-- desktop/
        |-- niri/                   # niri 配置（从 Hyprland 迁移）
        |-- waybar/  wofi/  wlogout/  dunst/
        |-- swayidle/               # 永不熄屏
        |-- swaylock/               # catppuccin 锁屏
        |-- kanshi/                 # 显示器 profile（本机面板）
        `-- wallpaper/              # 壁纸
```

整体思路很简单：

```text
flake.nix
  -> hosts/thinkbook/default.nix
    -> 共享的 NixOS 模块（modules/）
    -> 可选的 Home Manager profile（hm-profile/）
      -> 共享的用户模块（home-manager/）
```

### `flake.nix`

`flake.nix` 是顶层入口，它定义：

- inputs：`nixpkgs`、`home-manager`、`nix-alien`、`omp-nix`（oh-my-posh）、
  `x1e-nixos-config`。
- 二进制缓存设置（含 nix-community cachix）。
- 一个 `mkHost` 辅助函数，从 system、hostModule、可选的 Home Manager
  模块、extra special args 与 extra modules 创建每个 `nixosSystem`。
- 各主机共享的用户名 `kingcq`。
- Home Manager 集成：主机导入 `hm-profile/niri-desktop.nix`，拉入
  `home-manager/` 中的共享用户模块。

想理解整个项目如何组装，这是第一份要读的文件。

### `hosts/`

主机文件决定一台机器启用哪些可复用模块。flake 当前暴露这些 NixOS 配置：

| Flake 名 | 主机目录 | 系统 | Home Manager | 说明 |
| --- | --- | --- | --- | --- |
| `thinkbook` | `hosts/thinkbook` | `x86_64-linux` | 是 | ThinkBook 14s，Intel i7-1160G7 / Iris Xe |

`hosts/thinkbook/default.nix` 导入：

- 生成的硬件配置（`hardware-configuration.nix`）。
- 主机专属硬件模块（`hosts/thinkbook/hardware`，TLP 电源管理）。
- 共享硬件默认值（`modules/hardware`）。
- 共享系统默认值（`modules/software/system/main.nix`）。
- `greetd` 登录管理器与 Niri 桌面会话。

> 把 `hardware-configuration.nix` 当作**生成的硬件状态**。新机器上应该用
> `nixos-generate-config` 重新生成，而不是盲目复制另一台主机的文件。

### `modules/`

`modules/` 存放可复用的 NixOS 模块，影响整个操作系统：

```text
modules/hardware/
  default.nix     # 汇总导入
  main.nix        # bootloader、内核、固件、文件系统助手
  network.nix     # NetworkManager、时区、主机名
  input.nix       # locale、字体、fcitx5、键盘
  bluetooth.nix   # 蓝牙与 Blueman
  pipewire.nix    # PipeWire 音频

modules/software/
  system/         # 基础系统策略与常用 CLI 工具
  desktop/        # greetd、niri、dolphin 修复
  develop/        # 开发工具（预留目录）
```

最重要的共享系统模块是 `modules/software/system/main.nix`。它启用 unfree
软件、创建普通用户、配置 Git、启用 flakes、配置垃圾回收、把默认 shell
设为 fish、安装常用工具，并启用 `udisks2`、Polkit 与 GNOME keyring 集成。

### `home-manager/`

`home-manager/` 存放用户级配置，通过共享 profile
`hm-profile/niri-desktop.nix` 引入。重要文件：

- `core.nix` 设置基础 Home Manager 状态、用户服务、dconf 与桌面偏好。
- `applications.nix` 安装日常图形应用并声明 XDG 默认应用。
- `fish.nix` 配置 fish、oh-my-posh 提示符、声明式插件与别名。
- `vscode/` 声明式安装 VSCode 与 50+ 扩展，settings.json 原样部署。
- `jetbrains/` 声明式安装 JetBrains IntelliJ IDEA（统一版）。
- `desktop/niri/` 是当前活动的 Niri 桌面配置。
- `desktop/` 还包含 `kanshi`、`swayidle`、`swaylock`、`wallpaper`、
  `waybar`、`wlogout`、`wofi`、`dunst` 的配置。

Home Manager 不作为独立命令使用，而是通过 `flake.nix` 接入
`nixos-rebuild`。

## 桌面栈

当前桌面栈是 Wayland-first：

```text
greetd / tuigreet
  -> niri-session
    -> Niri 合成器
    -> Waybar
    -> wofi, wlogout, dunst, swayidle, swaylock, kanshi
```

系统级桌面部分位于 `modules/software/desktop/`：

- `greetd.nix` 配置登录管理器（tuigreet，密码登录，无自动登录）。
- `niri.nix` 启用 Niri 与配套桌面服务。
- `dolphin-fix.nix` 修复 KDE Dolphin 文件管理器。

用户级桌面配置位于 `home-manager/desktop/`：

- `desktop/niri/` 安装 Niri 用户工具，`*.kdl` 把配置拆分成输入、输出、
  快捷键、布局、启动、窗口规则、工作区、壁纸等文件。
- `desktop/waybar/` 是顶部状态栏（电池/音量/亮度/网络）。
- 其余目录（`kanshi`、`swayidle`、`swaylock`、`wallpaper`、`wlogout`、
  `wofi`、`dunst`）各自存放对应配置。

## 硬件说明

### ThinkBook 14s / `thinkbook`

这是日常主力机配置。要点：

- `hosts/thinkbook/hardware/default.nix` 包含机器专属调优：TLP（AC/电池
  CPU 与 PCIe 策略）、Intel Iris Xe 内核参数、thermald、fstrim。
- `home-manager/powertop/` + `hosts/thinkbook/default.nix`：powertop
  免密 sudo；waybar 电池模块右键菜单（一键优化/开关）走
  `powertop-toggle.sh`。
- 主机启用 `nix-ld`、`nix-alien`（`environment.systemPackages` 中安装）。
- 亮度：waybar `backlight` 模块原生滚动，1% 细腻步进；模块与 niri 亮度键
  都钳制在 5% 下限，背光不会到 0%。
- 电源：`swayidle` 无闲置超时——屏幕从不自动熄灭，只在休眠/合盖前锁屏。
- 显示器：`kanshi` 定义本机面板 profile；niri `output.kdl` 写死 `eDP-1`。

## 日常维护

常用命令：

```bash
# 重建当前机器（update 是 `sudo nixos-rebuild switch` 的别名）
update

# 更新 flake inputs
nix flake update /etc/nixos

# 查看更新后变化了什么
git diff flake.lock

# 只构建不切换，改动有风险时先用这个
sudo nixos-rebuild build --flake /etc/nixos#thinkbook
```

垃圾回收与 store 优化在 `modules/software/system/main.nix` 配置：

- 自动 GC 每周运行。
- 删除 14 天前的 generation。
- 自动启用 Nix store 优化。

**CI 验证**：本仓库的 GitHub Actions（`.github/workflows/build.yml`）
在每次 push 时执行 `nix flake check`（求值）+ `nix build` 完整构建
`nixosConfigurations.thinkbook.config.system.build.toplevel`——系统闭包
（内核、initrd、sudoers、全部软件）构建失败即红。部分错误只在构建阶段
暴露（例如 sudoers 未转义冒号会在 `visudo` 时报 syntax error），求值检查
查不出来，所以真实构建必不可少。

## 常用操作速查

> `Mod` = **Super 键**（Windows 键）。按 **`Mod+Shift+/`** 随时弹出快捷键面板
> （hotkey overlay），忘了就按它。

### 窗口与工作区（最常用）

| 操作 | 快捷键 |
| --- | --- |
| **在窗口间切换焦点** | `Mod+←/→`（左右列）、`Mod+↑/↓`（列内上下窗口） |
| 同上（Vim 风格） | `Mod+H/J/K/L` |
| **Alt+Tab：切到上一个工作区** | `Alt+Tab` |
| 切换到工作区 1–9 | `Mod+1` … `Mod+9` |
| **把当前窗口移到另一个工作区** | **`Mod+Ctrl+1` … `Mod+Ctrl+9`** |
| 把整列移到另一个工作区 | `Mod+Shift+1` … `Mod+Shift+9` |
| 把窗口移到上/下个工作区 | `Mod+Ctrl+Page_Up` / `Mod+Ctrl+Page_Down` |
| 移动窗口在工作区内的位置 | `Mod+Shift+←/→`（左右移列）、`Mod+Shift+↑/↓`（列内上下） |
| 关闭窗口 | `Mod+C` |
| 窗口全屏 | `Mod+Shift+F` |
| 列最大化（占满宽度） | `Mod+Shift+M` |
| 列宽在 25/50/75/100% 间切换 | `Mod+Shift+R` |
| 窗口浮动/平铺切换 | `Mod+V` |
| 微调列宽 | `Mod+Minus` / `Mod+Equal` |
| 工作区总览（缩略图） | `Mod+Tab` |
| 鼠标滚轮切换工作区 | `Mod+滚轮` |
| 退出 niri | `Ctrl+Alt+Delete` |

> **"怎么把窗口移到另一个桌面"** = `Mod+Ctrl+数字`（单个窗口）或
> `Mod+Shift+数字`（整列）。例如把浏览器丢到第 3 个工作区：`Mod+Ctrl+3`。

### 启动应用

| 操作 | 快捷键 |
| --- | --- |
| 终端 kitty | `Mod+Q` |
| 应用启动器 wofi | `Mod+R` |
| 浏览器 firefox | `Mod+F` |
| 文件管理器 dolphin | `Mod+E` |
| 编辑器 VSCode | `Mod+G` |
| 锁屏 | `Mod+Delete` |
| 注销菜单 wlogout | `Mod+M` |
| 通知历史 | `Mod+I` |
| 截图（选区） | `Mod+P` |
| 截图（当前窗口） | `Mod+Shift+P` |

### 系统

| 操作 | 方式 |
| --- | --- |
| 音量 +/−/静音 | `XF86Audio*` 功能键（笔记本 Fn 组合） |
| 亮度 +/− | `XF86MonBrightness*`（最低钳制在 5%，不会黑屏） |
| 播放/暂停/切歌 | `XF86AudioPlay/Next/Prev` |
| **切换中英文输入法** | `Ctrl+Space` |
| 终端里切换 shell 历史搜索 | `Ctrl+R`（fzf） |
| 终端里模糊找文件 | `Ctrl+T`（fzf） |
| 智能跳转目录 | `z <关键词>`（zoxide） |

### 更新与维护

```bash
nixos update          # 一键检查+更新（系统/Homebrew/omp/固件），会先列出再确认
nixos update -l       # 只看有哪些可更新
nixos update -i       # 用 fzf 勾选要更新的部分
fwupdate              # 只检查/安装固件更新
sudo nixos-rebuild switch --flake /etc/nixos#thinkbook   # 改了配置后重建
```

### 遇到问题

| 情况 | 处理 |
| --- | --- |
| 屏幕被截图模式盖住 | 按 `Esc` |
| 桌面卡死 | `Ctrl+Alt+F2` 切 TTY 登录，`pkill niri` 后重登 |
| 系统起不来 | GRUB 菜单选上一个 generation（回滚） |
| 配置改坏了 | `sudo nixos-rebuild switch --rollback` |

---

## 新增主机

把这个仓库当模板加一台新机器：

1. 创建主机目录：

   ```bash
   mkdir -p hosts/my-machine
   ```

2. 在目标机器上生成硬件配置：

   ```bash
   sudo nixos-generate-config --dir /etc/nixos/hosts/my-machine
   ```

3. 创建 `hosts/my-machine/default.nix` 并导入需要的共享模块：

   ```nix
   { config, pkgs, lib, username, ... }:
   {
     imports = [
       ./hardware-configuration.nix
       ../../modules/hardware
       ../../modules/software/system/main.nix
       ../../modules/software/desktop/greetd.nix
       ../../modules/software/desktop/niri.nix
     ];

     networking.hostName = "my-machine";
   }
   ```

4. 需要主机专属 Home Manager 模块时创建 `hosts/my-machine/home.nix`
   （共享 profile 由 flake 添加）。

5. 在 `flake.nix` 的 `nixosConfigurations` 中添加主机：

   ```nix
   my-machine = mkHost {
     system = "x86_64-linux";
     hostModule = ./hosts/my-machine;
     homeModules = [ ./hm-profile/niri-desktop.nix ./hosts/my-machine/home.nix ];
   };
   ```

   不需要 Home Manager 时省略 `homeModules`（保持空即可）。

6. 构建或切换：

   ```bash
   sudo nixos-rebuild build --flake /etc/nixos#my-machine
   sudo nixos-rebuild switch --flake /etc/nixos#my-machine
   ```

## 安装教程（UEFI + GRUB，从零到可用桌面）

> 本配置使用 **UEFI + GRUB**（默认）；也提供 BIOS(Legacy) 变体。
> 先在虚拟机里练手？见第 14 节，用专用主机 `.#thinkbook-vm`。

### 0. 装之前（5 分钟准备）

- **备份数据**——下面的分区操作会清空整块磁盘
- 下载 NixOS ISO：<https://nixos.org/download>（Graphical ISO）
- 准备一个 ≥ 4 GB 的 U 盘（内容会被清空）
- 确认目标磁盘设备名：`lsblk`（本机为 `/dev/nvme0n1`）

### 1. 制作启动 U 盘（**必须 DD 模式，否则会掉进 GRUB 命令行**）

NixOS 的 ISO 是 **hybrid ISO**（内含 isohybrid 引导结构），**必须原样整盘写入**。
用 Rufus 时如果选了默认的「ISO 模式」（它会解压文件），U 盘会被写成
`ntfs 分区 + RUFUS_BOOT 分区`，启动时 ISO 内部按 label 查找的逻辑全部失效，
结果就是**直接掉到 `grub>` 命令行**，进不了安装器。

#### 推荐：Linux 下用 dd（最可靠）

```bash
lsblk                       # 先确认 U 盘设备名，例如 /dev/sdX（别写成系统盘！）
sudo umount /dev/sdX*       # 卸载已挂载的分区
sudo dd if=~/Downloads/nixos-graphical-*.iso of=/dev/sdX bs=4M conv=fsync status=progress
sync
```

写入约 1–5 分钟（视 U 盘速度）。**验证**（关键）：

```bash
lsblk -o NAME,SIZE,FSTYPE,LABEL /dev/sdX
# 正确结果：出现 iso9660 文件系统，例如
#   sda   28.8G iso9660 nixos-graphical-26.05-x86_64
#     sda1 3.6G iso9660 nixos-graphical-26.05-x86_64
#     sda2   3M vfat    EFIBOOT
# 错误结果（Rufus ISO 模式）：ntfs + RUFUS_BOOT → 必须重写
```

#### Rufus（Windows/Linux GUI）

**务必在弹出「ISOHybrid image detected」对话框时选 `以 DD 镜像模式写入`**
（Write in DD Image mode）——选默认的 ISO 模式就会掉进 `grub>`。
写完后同样用上面的 `lsblk` 验证是否为 `iso9660`。

#### 掉进 `grub>` 了怎么办

不用重下 ISO：按上面重新用 DD 模式写一遍 U 盘即可。
（ISO 本身没坏——能进 GRUB 就说明引导扇区是好的。）

### 2. 引导方式（默认 UEFI，无需改 BIOS）

本仓库提供**两个真机目标**，桌面与软件完全一致，只有引导不同：

| flake 目标 | 引导 | 分区表 | 需要改 BIOS？ | /boot |
| --- | --- | --- | --- | --- |
| **`.#thinkbook`**（默认） | **UEFI + GRUB** | GPT | 不需要 | ESP 分区（建议 ≥1G） |
| `.#thinkbook-legacy-bios` | BIOS(Legacy) + GRUB | MBR | 需要切 Legacy/CSM | 根文件系统上 |

两者都用 GRUB + Catppuccin Macchiato 主题。

**默认走 UEFI**——开机时在 F12 菜单里选 **UEFI** 那一项启动 U 盘即可，
不需要动 BIOS 设置。

<details>
<summary>只有你想用 BIOS(Legacy) 时才需要看这段</summary>

1. 开机连按 **F2** 进 BIOS
2. `Boot` → `Boot Mode` 改为 **Legacy Support**（或 `CSM Support` → Enabled）
   - 若只看到 `Secure Boot`：先设 **Disabled**，Legacy/CSM 选项才会出现
3. 保存退出（F10）
4. 之后 F12 菜单里选 **Legacy** 那一项启动 U 盘

</details>

> 当前系统是哪种模式：`[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS`
> （本机实测：UEFI，BIOS 为 Insyde HLCN26WW）

### 3. 从 U 盘启动

1. 关机 → 开机时连按 **F12**（联想）→ 选 U 盘。同一个 U 盘可能显示两项：
   - 走默认（UEFI）→ 选 **UEFI** 那项
   - 走 BIOS 变体 → 选 **Legacy** 那项（需先在 BIOS 里开 Legacy/CSM）
2. 进入 live 环境（root 自动登录；图形安装器窗口会弹出来，**直接关掉**）
3. 打开终端：`Ctrl+Alt+T`，或按 `Ctrl+Alt+F2` 切到文字终端

### 4. 联网（安装必须联网）

```bash
# 有线：插网线即可（NetworkManager 会自动获取地址）
# 无线：
sudo nmtui            # 选 "Activate a connection" → 选 WiFi → 输密码
# 验证
ping -c2 nixos.org
```

### 5. 分区（UEFI：GPT + ESP + Btrfs）

```bash
lsblk                     # 确认目标盘，例如 /dev/nvme0n1
sudo fdisk /dev/nvme0n1   # 在交互界面依次输入：
```

| 输入 | 含义 |
| --- | --- |
| `g` | 新建 GPT 分区表（**清空磁盘**） |
| `n` → `1` → 回车 → `+1G` | 分区 1 = 1G（EFI 系统分区） |
| `t` → `1` | 把分区 1 类型设为 `EFI System` |
| `n` → `2` → 回车 → 回车 | 分区 2 = 剩余全部空间 |
| `w` | 写入并退出 |

> ESP 给 **1G**：NixOS 的 `/boot` 就放在 ESP 上，每代内核+initrd 约 45M，
> 285M（出厂值）会很快写满。

<details>
<summary>改用 BIOS(Legacy) 时的分区方式</summary>

MBR 分区表 + 单个主分区，不需要 ESP：

```bash
sudo fdisk /dev/nvme0n1
#   o        ← 新建空 DOS(MBR) 分区表
#   n → p → 1 → 回车 → 回车
#   a        ← 标记可启动
#   w        ← 写入
```

</details>

### 6. 格式化 + 创建 Btrfs 子卷

```bash
# ① EFI 系统分区（UEFI 需要；BIOS 布局跳过这步）
sudo mkfs.fat -F 32 /dev/nvme0n1p1

# ② 根分区：Btrfs + 子卷
sudo mkfs.btrfs -L nixos /dev/nvme0n1p2
sudo mount /dev/nvme0n1p2 /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo umount /mnt
```

### 7. 按子卷挂载

```bash
sudo mount -o subvol=@,compress=zstd,noatime /dev/nvme0n1p2 /mnt
sudo mkdir -p /mnt/{boot,home,nix}
sudo mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p2 /mnt/home
sudo mount -o subvol=@nix,compress=zstd,noatime /dev/nvme0n1p2 /mnt/nix
sudo mount /dev/nvme0n1p1 /mnt/boot      # UEFI：ESP 挂到 /boot（BIOS 布局跳过）

df -h /mnt | tail -1                      # 确认已挂载
```

### 8. 生成硬件配置并替换仓库里的模板

```bash
sudo nixos-generate-config --root /mnt

# 取仓库
git clone https://github.com/Kingcxp/nixos.git /tmp/nixos_kingcq
# 关键一步：用本机真实硬件配置替换仓库模板（否则会套用别人机器的 UUID）
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/nixos_kingcq/hosts/thinkbook/hardware-configuration.nix
```

> 若生成的文件里出现 `virtualisation.virtualbox.guest.enable = true;`，说明你在
> **虚拟机**里——那请改用 `.#thinkbook-vm`（见第 14 节）；真机不会有这行。

### 9. 安装

```bash
sudo cp -r /tmp/nixos_kingcq /mnt/nixos_kingcq
cd /mnt/nixos_kingcq

# 先确认 live 环境是哪种模式启动（决定用哪个目标，必须一致！）
[ -d /sys/firmware/efi ] && echo "UEFI 启动" || echo "BIOS/Legacy 启动"

sudo nixos-install --flake .#thinkbook        # UEFI 启动时用（默认）
# 或
sudo nixos-install --flake .#thinkbook-legacy-bios   # BIOS/Legacy 启动时用
```

> ⚠️ **安装目标必须与 live 环境的启动模式一致**：
> UEFI 启动的 live 环境装 `.#thinkbook`（GRUB 写 ESP），
> Legacy 启动的 live 环境装 `.#thinkbook-legacy-bios`（GRUB 写 MBR）。
> 装错会导致重启后无法引导。
>
> 同一个 U 盘在 F12 启动菜单里可能显示两项（UEFI 与 Legacy），
> **你选哪项就决定了 live 环境的启动模式**。

- 成功标志（最后几行）：
  `installing the GRUB 2 boot loader on /dev/nvme0n1...` →
  `Installation finished. No error reported.`
- 中途出现 `No space left on device` → 空间不足，检查 `df -h /mnt`

#### 9.1 关于耗时（重要，先读）

`flake.lock` 锁定的 nixpkgs rev **不是 Hydra 构建过的 channel 版本**，所以约 **300 个
派生在 `cache.nixos.org` 里没有**，会在你机器上现编译——其中包含几个重包
（`aseprite`、`nodejs`、`neovim`、`steam`、`idea`、`vscode` 等）。

| 场景 | 大致耗时（4 核笔记本） |
| --- | --- |
| 直接安装（默认） | **1–2 小时**，且编译期内存占用较高 |
| 复用已有 store（见下） | **20–40 分钟**（几乎全部从缓存取） |

> 实测（VirtualBox 4 vCPU / 6 GB）：直接安装时 `nix` 进程因内存不足被 OOM 杀掉过一次；
> 真机 16 GB 内存不会这么紧张，但编译期建议别同时开重负载程序。

#### 9.2 加速安装：复用已有 `/nix/store`（可选）

如果你**之前在这台机器上装过 nix**（或另一台机器有同一套配置的 store），
可以把已有闭包导出成本地二进制缓存，安装时直接取用：

```bash
# ① 在旧系统上（本仓库目录内）执行：把完整闭包写入 U 盘/移动硬盘
nix copy --to "file:///run/media/kingcq/USB/nixcache" \
  ".#nixosConfigurations.thinkbook.config.system.build.toplevel"
```

```bash
# ② 启动安装 U 盘、分区挂载完成后，在 live 环境里插上该盘并挂载
sudo mkdir -p /mnt/usb && sudo mount /dev/sdX1 /mnt/usb

sudo nixos-install --flake .#thinkbook \
  --substituters "file:///mnt/usb/nixcache https://cache.nixos.org" \
  --option require-sigs false
```

- `--option require-sigs false` **必须加**：本地缓存里的包没有签名。
- 缓存体积与闭包同量级（**约 20 GB**），U 盘/移动硬盘请留足空间。
- 没有旧 store 可复用？跳过本节，直接按上面的命令装，只是慢。

> **不要**为了提速去 `nix flake update`：实测把 nixpkgs 更新到当前 master tip
> 反而需要编译 **774 个**（比锁定的 rev 更差），而且新版 nixpkgs 移除了
> `pkgs.gcr`（需改成 `pkgs.gcr_4`）会直接报错。

### 10. 重启

```bash
sudo reboot
```

**重启前拔掉 U 盘**（或在 BIOS 里把硬盘调到第一启动项），否则又会进安装器。

启动流程：GRUB 菜单（Catppuccin 主题）→ 回车 → tuigreet 登录界面。

### 11. 首次登录

- 用户名 **kingcq**，初始密码 **123456**
- **第一件事就改密码**（初始密码明文保存在 /nix/store，只用于首次登录）：

```bash
passwd
```

### 12. 把仓库接到 /etc/nixos（以后改配置用）

```bash
sudo mv /nixos_kingcq ~/nixos          # 安装时仓库在 /nixos_kingcq
sudo chown -R kingcq:users ~/nixos
sudo rm -rf /etc/nixos
sudo ln -s ~/nixos /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#thinkbook   # 验证一次
```

之后日常更新只需要一条命令（详见 USAGE.md）：

```bash
nixos update        # 列出所有可更新项 → 确认 → 更新（系统/Homebrew/omp/固件）
```

### 13. 装机后自检清单

```bash
aplay -l | head -5          # 声卡（Intel SOF 固件）
vainfo | head -5            # 视频硬解（VA-API）
nmcli device status         # 无线/有线
fcitx5-configtool           # 输入法（Ctrl+Space 切中文智能拼音）
fwupdate                    # 固件更新检查
nixos update -l             # 列出可更新项（不改动系统）
```

对照检查：笔记本屏幕 `eDP-1` 正常、亮度键可用、声音可用、WiFi 可用、
`Ctrl+Space` 能切中文、电池与功耗显示在 waybar 上。

### 14. 先在 VirtualBox 里试装（推荐）

VM 用专用主机 **`thinkbook-vm`**：GRUB 目标盘自动设为 `/dev/sda`、niri 自动
检测输出、内置 VirtualBox Guest Additions（含编译修复）。完整流程见
《[VirtualBox 试装指南](VM-TEST.md)》，要点：

- VM 设置：**BIOS 启动**（不要开 EFI）、6–8 GB 内存、**60 GB 磁盘**、
  显卡 VMSVGA + **勾选 3D 加速**
- 安装命令把 `--flake .#thinkbook` 换成 `--flake .#thinkbook-vm`
- 磁盘是 `/dev/sda`（分区/格式化步骤同样替换设备名）
- 重启前**移除 ISO**
- 如果你把 VM 固件设成 **EFI**（VirtualBox 设置 → 系统 → 启用 EFI），
  则不需要 `-vm` 变体，直接用真机目标 `.#thinkbook` 即可（已实测：GPT + ESP 安装、
  GRUB 装到 ESP、固件启动项写入、重启进 tuigreet 全部正常）

### 15. 装到一半出问题？

| 现象 | 原因与解法 |
| --- | --- |
| U 盘启动直接进 `grub>` 命令行 | U 盘是用 Rufus 的 ISO 模式写的 → 按第 1 步用 **DD 模式**重写 |
| `efiSysMountPoint '/boot' is not a mounted partition` | 走 UEFI 但 `/boot` 没挂 ESP → 检查第 7 步是否 `mount /dev/nvme0n1p1 /mnt/boot` |
| `cannot find a GRUB drive for /dev/nvme0n1` | 目标与启动模式不匹配（如 UEFI 的 live 环境装 `.#thinkbook-legacy-bios`） |
| `cannot find a GRUB drive for /dev/sda` | 在 VM 里用了真机目标 → 改用 `.#thinkbook-vm` |
| 一堆小构建 `exit code 1` + 日志提 `No space left` | 磁盘/分区太小（VM 建议 60 G；真机 ESP 建议 ≥1 G） |
| 重启后又进安装器 | ISO 没拔 / 启动顺序没调 |
| 下载中断报 `truncated or corrupt` | `sudo nix-store --verify --check-contents --repair` 修复 |
| 下载极慢、`substitutes failed` | live 环境 DNS 异常 → 见《VM-TEST.md》同名小节 |

---

- 《使用指南》(USAGE.md)：日常命令、软件管理、故障排查等中文说明。
- 《VirtualBox 试装指南》(VM-TEST.md)：在虚拟机中先行验证本配置的完整流程，
  含虚拟盘分区、UUID 替换与常见问题（如 `/boot` 未挂载导致 bootloader
  安装失败）的排查。

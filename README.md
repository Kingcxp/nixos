# NixOS 系统配置 — kingcq / ThinkBook

本仓库为 ThinkBook 笔记本（Intel i7-1160G7 / Iris Xe / NVMe / UEFI）的
Flake 式 NixOS 系统配置，采用声明式方式管理系统环境、用户环境与桌面，
全部配置可复现、可回滚。

**新手请先阅读《[使用指南](USAGE.md)》**，其中涵盖日常命令、软件管理、
常用软件用法以及故障排查等内容。

**计划在虚拟机中先行试装？** 请参阅《[VirtualBox 试装指南](VM-TEST.md)》，
其中说明了虚拟机与真机在磁盘、显卡、显示器等方面的差异及完整操作流程。

---

## 一、完整安装教程（从零到可用桌面）

以下步骤假设你已经下载了 NixOS 安装 ISO 并制作了启动 U 盘。

### 1. 准备安装介质

```bash
# 在任意 Linux 上把 ISO 写入 U 盘（替换 /dev/sdX 为你的 U 盘设备号）
sudo dd if=/path/to/nixos.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

NixOS 官方 ISO：<https://nixos.org/download>

### 2. 启动到安装环境

U 盘启动 → 选择默认的 "NixOS" 安装项 → 进入 live 环境（自动登录 root 终端）。

### 3. 规划磁盘并分区

本配置的 `hosts/thinkbook/hardware-configuration.nix` 使用下面的布局
（**Btrfs + 子卷 + systemd-boot**，与原 Arch 分区结构一致）：

```text
/dev/nvme0n1p1  ->  /boot       (EFI, FAT32, 约 512M–1G)
/dev/nvme0n1p2  ->  Btrfs 卷     (剩余全部空间)
   ├── 子卷 @          ->  /
   ├── 子卷 @home      ->  /home
   └── 子卷 @nix        ->  /nix   (可选，推荐隔离)
```

分区示例（`sudo fdisk /dev/nvme0n1`）：

```text
nvme0n1p1:  type=EFI System, size=512M
nvme0n1p2:  type=Linux filesystem, 剩余全部
```

> ⚠️ **会清空磁盘**。操作前备份数据。

格式化并创建子卷：

```bash
# EFI 分区
sudo mkfs.fat -F 32 /dev/nvme0n1p1

# Btrfs 主卷 + 子卷
sudo mkfs.btrfs -L nixos /dev/nvme0n1p2
sudo mount /dev/nvme0n1p2 /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo umount /mnt
```

### 4. 挂载

```bash
sudo mount -o subvol=@,compress=zstd,noatime /dev/nvme0n1p2 /mnt
sudo mkdir -p /mnt/{boot,home,nix}
sudo mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p2 /mnt/home
sudo mount -o subvol=@nix,compress=zstd,noatime /dev/nvme0n1p2 /mnt/nix
sudo mount /dev/nvme0n1p1 /mnt/boot
```

### 5. 生成硬件配置

```bash
sudo nixos-generate-config --root /mnt
```

这会生成 `/mnt/etc/nixos/hardware-configuration.nix`（含你磁盘的真实 UUID
和内核模块）。**把这个文件替换进本仓库**（重要——仓库里那份是手写的旧布局）：

```bash
cp /mnt/etc/nixos/hardware-configuration.nix hosts/thinkbook/hardware-configuration.nix
```

### 6. 把仓库放到安装环境并安装

方式 A：直接把仓库拷进 /mnt：

```bash
# 在 live 环境里（先联网：iwctl/nmcli 或插网线）
sudo cp -r /path/to/nixos_kingcq /mnt/nixos_kingcq
cd /mnt/nixos_kingcq
sudo nixos-install --flake .#thinkbook
```

方式 B：先装基础系统再应用 flake（更稳，分两步）：

```bash
# 先按生成的基础配置装上
cd /mnt/etc/nixos
sudo nixos-install

# 重启进新系统后，把仓库链接为 /etc/nixos 再部署
sudo rm -rf /etc/nixos
sudo ln -s /path/to/nixos_kingcq /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#thinkbook
```

`nixos-install --flake .#thinkbook` 会读取仓库里的 `hosts/thinkbook/`、
`modules/`、`home-manager/` 全套配置，构建完整的 niri 桌面系统并安装。

### 7. 设置用户密码并重启

```bash
# 安装时如果没提示，设置 kingcq 密码（配置里的用户是 kingcq）
sudo nixos-install          # 会提示设置 root 密码
# 用户 kingcq 的初始密码在首次登录时由 `passwd kingcq` 设置：
sudo nixos-chroot /mnt passwd kingcq

sudo reboot
```

重启后：**greetd 密码登录（tuigreet）** → 输入 kingcq 密码 → 进入 niri 桌面。

### 8. 装机后首次检查

```bash
# 确认系统生成器正常
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# 确认 flake 可用
nix flake check --flake /etc/nixos#thinkbook
```

---

## 二、仓库结构

```text
flake.nix                          # inputs、mkHost 帮助函数、主机注册表
flake.lock                         # 锁定依赖版本（可复现构建）
.gitignore                         # 忽略 result 等 Nix 构建产物
README.md                          # 本文件（安装 + 说明）
USAGE.md                           # 中文 NixOS 使用指南（新手必读）
hosts/thinkbook/                   # 本机：Intel 调优、TLP、硬件配置
hm-profile/niri-desktop.nix        # 共享的 Home Manager 桌面 profile
modules/hardware/                  # 引导、内核、网络、输入、蓝牙、PipeWire
modules/software/system/main.nix   # 系统基础策略（用户、fish、工具）
modules/software/desktop/          # greetd（密码登录）+ niri
home-manager/                      # 用户应用和 dotfiles
  core.nix                         # home 状态、keyring、深色主题
  applications.nix                 # firefox、dolphin、QQ 等 + mime 默认
  fish.nix                         # fish shell + oh-my-posh 提示符 + 插件
  kitty/  micro/  btop/  yazi/     # 应用配置，原样部署
  tmux/  nvim/                     # tmux + nvim (AstroNvim) 配置
  powertop/                        # powertop-toggle.sh + waybar 电池接线
  desktop/
    niri/                          # niri 配置（从 Hyprland 迁移）
    waybar/  wofi/  wlogout/  dunst/
    swayidle/                      # 永不熄屏
    swaylock/                      # catppuccin 锁屏
    kanshi/                        # 显示器 profile（本机面板）
    wallpaper/                     # 壁纸
```

---

## 三、从 Hyprland 迁移到 niri

桌面从 **Hyprland 迁移至 niri**（niri 配置格式稳定，适合作为长期桌面环境）：

| 原 Hyprland 配置 | 本配置 (niri) |
| --- | --- |
| `hyprland.conf` | `home-manager/desktop/niri/config/*.kdl` |
| `$mainMod = SUPER` | `Mod`（TTY 上即 Super） |
| SUPER+1..9 工作区 | Mod+1..9 `focus-workspace` |
| Alt+Tab `workspace previous` | Alt+Tab `focus-workspace-previous`（最近两个） |
| SUPER+Q kitty / R wofi / E dolphin / F firefox / M wlogout | 相同，`spawn …` |
| SUPER+C killactive | Mod+C `close-window` |
| SUPER+V togglefloating | Mod+V `toggle-window-floating` |
| SUPER+P hyprshot | Mod+P `screenshot` |
| hypridle（永不熄屏） | swayidle —— **只**在休眠前锁屏，无闲置超时 |
| hyprlock（catppuccin） | swaylock —— catppuccin 配色 + 同一壁纸 |
| hyprpaper | swaybg（经 `wallpaper.kdl`） |
| waybar hyprland/workspaces | waybar `niri/workspaces` |
| waybar hyprland/window | waybar `niri/window` |

### 软件选型

本配置在相关软件上作出的选择如下：

- **终端**：kitty
- **Shell**：fish
- **通知**：dunst
- **启动器/注销**：wofi、wlogout
- **编辑器**：nvim（AstroNvim 配置）
- **文件管理器**：dolphin（`kdePackages.dolphin`）
- **光标/主题**：catppuccin-macchiato-lavender-cursors、Catppuccin Macchiato
- **圆角**：约 8px 偏方角，经 `windowrule.kdl` 的 `geometry-corner-radius 8` 应用

### 未纳入的软件

- **zsh / mako / alacritty / vscode / zed / opencode / 外接屏 kanshi**
  —— 未采用（分别由 fish、dunst、kitty 等替代，或暂不需要）
- **Steam / Minecraft / Android Studio / Waydroid** —— 游戏与安卓相关模块
  未纳入本配置
- **v2raya 代理服务** —— 未启用（如需可加回 `modules/software/system/main.nix`）

---

## 四、特性说明

### Shell（fish + oh-my-posh）
- 默认 shell 为 fish；提示符由 **oh-my-posh** 渲染，主题基于 clean-detailed
  定制为 Catppuccin Macchiato 配色。
- 提示符显示：完整路径、Git 分支状态、上一条命令退出码（成功 `✔`，失败显示
  错误码）、执行耗时、以及当前项目所用编程语言（Python/Node/Go/Rust 自动检测）。
- fish 插件通过 home-manager **声明式管理**（`programs.fish.plugins`，来自
  nixpkgs 内置 fishPlugins）：fzf-fish（Ctrl+R 历史搜索）、done（长命令完成
  通知）、forgit（git+fzf 交互）、colored-man-pages。
- 辅助工具：fzf、fd、bat、eza、zoxide（智能 `z`）、ripgrep、tldr。
- 说明：NixOS 下**不推荐 fisher**——它会在运行时改写 `~/.config/fish`，破坏
  声明式与可复现性；改用 home-manager 声明式插件即可达到同样效果。



### 登录
`modules/software/desktop/greetd.nix` 通过 `tuigreet`（终端式登录管理器）
显示**密码登录**，无自动登录（安全考虑）。tuigreet 为纯文本界面，不会出现
刺眼的图形登录背景；原 Hyprland 环境使用的 regreet 图形主题未迁移。

### 永不熄屏
`home-manager/desktop/swayidle/default.nix` **无闲置超时**——屏幕从不自动
熄灭或变暗，即使在电池下。只在休眠/合盖前锁屏。

### 屏幕亮度
- waybar `backlight` 模块用**原生滚动**（`scroll-step: 1.0` +
  `smooth-scrolling-threshold`）替代固定 5% 命令——1% 细腻步进，触控板
  平滑滚动被聚合，不再一跳 5%
- waybar 模块（`min-brightness: 5`）和 niri 亮度键（`brightnessctl -n 4800`）
  都**钳制在 5% 下限**，背光永远不会到 0%（即黑屏）
- 注意：`-n 4800` 硬编码了本机 `intel_backlight` 的最大值（96000 × 5%）。
  若内核/驱动改变该值，用 `brightnessctl --class=backlight max` 重新计算

### 电源与电池
- `hosts/thinkbook/hardware/default.nix`：TLP（AC/电池 CPU 与 PCIe 策略）、
  Intel Iris Xe 内核参数、thermald、fstrim
- `home-manager/powertop/` + `hosts/thinkbook/default.nix`：powertop 免密 sudo；
  waybar 电池模块右键菜单（一键优化/开关）走 `powertop-toggle.sh`

---

## 五、验证

配置已在本机用 `nix eval .#nixosConfigurations.thinkbook.config.system.build.toplevel.drvPath`
**完整求值成功** → `nixos-system-thinkbook-26.11.20260810.2fcb964.drv`（exit 0）。
全部模块、选项、import 路径有效；抽查确认：无 greetd 自动登录、fish 默认
shell、v2raya 关闭、niri 启用、dolphin 在位（nautilus 已移除）。

并已在本机 `nix build` 完整构建整个系统闭包（14G store，含内核、initrd、
全部软件），无真实错误。

进一步（装机前彻底验证依赖链）：

```bash
nix flake check --flake /etc/nixos#thinkbook   # 或
nixos-rebuild build --flake /etc/nixos#thinkbook
```

`flake.lock` 已锁定依赖的精确版本（`nixpkgs` rev `2fcb964de67f`、
home-manager rev `99e84ee7387f`），确保构建可复现；升级 inputs 前请先验证。

---

## 六、版本状态

`system.stateVersion = "25.05"`；home-manager `home.stateVersion = "25.11"`。

---

- 《使用指南》(USAGE.md)：日常命令、软件管理、故障排查等中文说明。
- 《VirtualBox 试装指南》(VM-TEST.md)：在虚拟机中先行验证本配置的完整流程。
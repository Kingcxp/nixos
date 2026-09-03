# NixOS Configurations — kingcq / ThinkBook

这是一个基于 Flake 的 NixOS 配置仓库，管理一台 ThinkBook 笔记本
（Intel i7-1160G7 / Iris Xe / NVMe / UEFI）。它也是一个可读的示例，
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

## 安装教程

以下步骤假设你已下载 NixOS 安装 ISO 并制作了启动 U 盘。

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
（**Btrfs + 子卷 + systemd-boot**）：

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

> 配置里已设置初始密码 `123456`（`initialPassword`），**装完请立即用
> `passwd` 修改**——初始密码明文存在于 `/nix/store` 配置中，仅首次登录用。

重启后：**greetd 密码登录（tuigreet）** → 输入 kingcq 密码 → 进入 niri 桌面。

### 8. 装机后首次检查

```bash
# 确认系统生成器正常
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# 确认 flake 可用
nix flake check --flake /etc/nixos#thinkbook
```

---

- 《使用指南》(USAGE.md)：日常命令、软件管理、故障排查等中文说明。
- 《VirtualBox 试装指南》(VM-TEST.md)：在虚拟机中先行验证本配置的完整流程，
  含虚拟盘分区、UUID 替换与常见问题（如 `/boot` 未挂载导致 bootloader
  安装失败）的排查。

# NixOS Configurations — kingcq / ThinkBook

这是一个基于 Flake 的 NixOS 配置仓库，管理一台 ThinkBook 笔记本
（Intel i7-1160G7 / Iris Xe / NVMe / BIOS+GRUB）。它也是一个可读的示例，
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

## 安装教程（BIOS + GRUB，从零到可用桌面）

> 本配置使用 **BIOS 启动 + GRUB**（不是 UEFI/systemd-boot）。
> 先在虚拟机里练手？见第 14 节，用专用主机 `.#thinkbook-vm`。

### 0. 装之前（5 分钟准备）

- **备份数据**——下面的分区操作会清空整块磁盘
- 下载 NixOS ISO：<https://nixos.org/download>（Graphical ISO）
- 准备一个 ≥ 4 GB 的 U 盘（内容会被清空）
- 确认目标磁盘设备名：`lsblk`（本机为 `/dev/nvme0n1`）

### 1. 制作启动 U 盘

```bash
# 在任意 Linux 上执行（/dev/sdX 换成你的 U 盘，写错会毁掉别的盘！）
sudo dd if=nixos-graphical-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

Windows 上可用 Rufus，写入模式选 **DD 镜像模式**。

### 2. 设置 BIOS（**关键步骤，先做完再启动**）

本配置使用 **BIOS(Legacy) + GRUB**，而笔记本出厂默认是 UEFI 启动——
必须先在 BIOS 里切换，否则装完无法引导。

1. 关机 → 开机时连按 **F2**（联想 ThinkBook 进 BIOS；部分机型是 F1 或 Fn+F2）
2. 找到启动模式设置，通常在这几处之一：
   - `Boot` → `Boot Mode` → 改为 **Legacy Support**（或 `CSM Support` → Enabled）
   - `Startup` → `UEFI/Legacy Boot` → **Legacy Only**
   - 若只看到 `Secure Boot`：先把它设为 **Disabled**，Legacy/CSM 选项才会出现
3. **把 U 盘设为第一启动项**（`Boot` → `Boot Priority` / `EFI/Legacy Boot Priority`）
4. 保存退出（**F10** → Yes）

> ⚠️ 如果 BIOS 里**找不到任何 Legacy/CSM 选项**（纯 UEFI 固件），本配置的
> BIOS+GRUB 方案无法使用——请告诉我，我改成 UEFI+systemd-boot 的版本
> （改动很小，只是引导部分和分区布局不同）。
>
> ThinkBook 20WJ（BIOS HLCN26WW）确认支持 Legacy 启动。

### 3. 从 U 盘启动

1. 关机 → 开机时连按 **F12**（联想）→ 选择 U 盘（若列表里出现两个，选 **Legacy** 那项）
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

### 5. 分区（MBR 分区表 + 一个主分区）

```bash
lsblk                     # 确认目标盘，例如 /dev/nvme0n1
sudo fdisk /dev/nvme0n1   # 在交互界面依次输入：
```

| 输入 | 含义 |
| --- | --- |
| `o` | 新建空 DOS(MBR) 分区表（**清空磁盘**） |
| `n` → `p` → `1` | 新建主分区 1 |
| 回车、回车 | 起始/结束扇区都用默认（= 整块盘） |
| `a` | 标记分区 1 为可启动 |
| `w` | 写入并退出 |

> **想用 GPT 也行**：把 `o` 换成 `g`，然后先建一个 `+1M`、类型为
> `BIOS boot`（fdisk 里输入 `t` 再输 `4`）的小分区，再建主分区。
> GRUB 装在磁盘开头的空隙里——**BIOS 启动不需要 EFI 分区**。

### 6. 格式化 + 创建 Btrfs 子卷

```bash
sudo mkfs.btrfs -L nixos /dev/nvme0n1p1

sudo mount /dev/nvme0n1p1 /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo umount /mnt
```

### 7. 按子卷挂载

```bash
sudo mount -o subvol=@,compress=zstd,noatime /dev/nvme0n1p1 /mnt
sudo mkdir -p /mnt/{home,nix}
sudo mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p1 /mnt/home
sudo mount -o subvol=@nix,compress=zstd,noatime /dev/nvme0n1p1 /mnt/nix
df -h /mnt | tail -1     # 确认已挂载（应显示磁盘总容量）
```

> BIOS + GRUB **不需要单独的 `/boot` 分区**：GRUB 直接读取根文件系统上的
> `/boot` 目录（仓库的 `hardware-configuration.nix` 模板也是这个布局）。

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
sudo nixos-install --flake .#thinkbook
```

- 会下载约 3 GB 并按需构建，**大概 20–40 分钟**（视网络）
- 成功标志（最后几行）：
  `installing the GRUB 2 boot loader on /dev/nvme0n1...` →
  `Installation finished. No error reported.`
- 中途出现 `No space left on device` → 空间不足，检查 `df -h /mnt`

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

### 15. 装到一半出问题？

| 现象 | 原因与解法 |
| --- | --- |
| `Cannot build ... sudoers.drv`（syntax error） | 已修复；确保用的是仓库最新代码 |
| `efiSysMountPoint '/boot' is not a mounted partition` | 说明你按旧的 UEFI 流程装了 / 或仍用 systemd-boot；本配置是 BIOS+GRUB，**不需要 EFI 分区** |
| `cannot find a GRUB drive for /dev/nvme0n1` | 在 VM 里用了真机主机名 → 改用 `.#thinkbook-vm` |
| 一堆小构建 `exit code 1` + 日志提 `No space left` | 磁盘/分区太小（VM 建议 60 G） |
| 重启后又进安装器 | ISO 没拔 |
| 下载中断报 `truncated or corrupt` | 用 `sudo nix-store --verify --check-contents --repair` 修复 |

---

- 《使用指南》(USAGE.md)：日常命令、软件管理、故障排查等中文说明。
- 《VirtualBox 试装指南》(VM-TEST.md)：在虚拟机中先行验证本配置的完整流程，
  含虚拟盘分区、UUID 替换与常见问题（如 `/boot` 未挂载导致 bootloader
  安装失败）的排查。

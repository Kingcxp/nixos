# NixOS 配置 — kingcq（ThinkBook）

面向 ThinkBook 笔记本（11 代 Intel i7-1160G7 / Iris Xe / NVMe / UEFI）的
flake 式 NixOS 配置。参考朋友的仓库（`../nixos`）搭建，双方配置重叠处
**以你自己的配置优先**（见下文"重叠策略"）。

> **新手？** 先读 [`USAGE.md`](./USAGE.md) —— 这是一份中文的 NixOS 使用指南，
> 覆盖日常命令、装软件、常用软件用法、回滚与故障排查。
>
> **想先试装再上真机？** 看 [`VM-TEST.md`](./VM-TEST.md) —— VirtualBox
> 虚拟机试装指南（磁盘/显卡/显示器的虚拟机差异、完整流程）。

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
（**Btrfs + 子卷 + systemd-boot**，与你的原有 Arch 分区结构一致）：

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
flake.lock                         # 锁定版本（与参考仓库同一批 rev，已验证可构建）
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
  fish.nix                         # fish shell（你的偏好，朋友用 zsh）
  kitty/  micro/  btop/  yazi/     # 你的应用配置，原样部署
  tmux/  nvim/                     # 你的 tmux + nvim (AstroNvim)
  powertop/                        # powertop-toggle.sh + waybar 电池接线
  desktop/
    niri/                          # niri 配置（从 Hyprland 迁移）
    waybar/  wofi/  wlogout/  dunst/
    swayidle/                      # 永不熄屏（你的需求）
    swaylock/                      # catppuccin 锁屏
    kanshi/                        # 显示器 profile（本机面板）
    wallpaper/                     # 你的壁纸
```

---

## 三、从 Hyprland 迁移到 niri

桌面从 **Hyprland → niri** 迁移（niri 配置格式稳定，且是参考仓库的桌面）：

| 你的 (Hyprland) | 本配置 (niri) |
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

### 重叠策略 —— 你的配置优先

与朋友配置重叠处，保留你的选择：

- **终端**：kitty（朋友用 alacritty）
- **Shell**：fish（朋友用 zsh）
- **通知**：dunst（朋友用 mako）
- **启动器/注销**：wofi、wlogout（你的样式）
- **编辑器**：你的 nvim 配置（AstroNvim）
- **文件管理器**：dolphin（`kdePackages.dolphin`；朋友用 nautilus）
- **光标/主题**：catppuccin-macchiato-lavender-cursors、Catppuccin Macchiato
- **圆角**：约 8px 偏方角（你的偏好），经 `windowrule.kdl` 的
  `geometry-corner-radius 8` 应用

### 明确未迁移的内容

- **朋友的 zsh / mako / alacritty / vscode / zed / opencode / 外接屏 kanshi**
  —— 换成你的等价物或丢弃
- **Steam / Minecraft / Android Studio / Waydroid** —— 参考仓库的游戏/安卓
  模块丢弃（不在你的配置里）
- **v2raya 代理服务** —— 从基础模块移除（如需可加回
  `modules/software/system/main.nix`）

---

## 四、特性说明

### 登录
`modules/software/desktop/greetd.nix` 通过 `tuigreet` 显示**密码登录**，
无自动登录（安全考虑）。

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

版本锁定严格：`flake.lock` 锁定与参考仓库相同的精确 rev（`nixpkgs`
`2fcb964de67f`、home-manager `99e84ee7387f`），经验证可共同求值/构建。
不要未经测试就升级 inputs。

---

## 六、版本状态

`system.stateVersion = "25.05"`；home-manager `home.stateVersion = "25.11"`。

---

- [`USAGE.md`](./USAGE.md) —— 中文使用指南（日常命令、装软件、故障排查）
- [`VM-TEST.md`](./VM-TEST.md) —— VirtualBox 虚拟机试装指南
- 参考仓库：`../nixos`（朋友的原配置）
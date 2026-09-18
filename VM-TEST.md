# 在 VirtualBox 虚拟机中试装 NixOS

先在虚拟机里练手、确认无误再上真机，是很稳的路径。本配置在 VM 里有一个**专用
主机 `thinkbook-vm`**，它自动处理了所有 VM 差异——你不需要手改任何文件。

| 差异点 | 真机 ThinkBook | VirtualBox 虚拟机 |
| --- | --- | --- |
| flake 目标 | `.#thinkbook` | **`.#thinkbook-vm`** |
| 磁盘设备 | `/dev/nvme0n1` | `/dev/sda` |
| GRUB 目标盘 | `/dev/nvme0n1` | `/dev/sda`（变体内置） |
| niri 输出 | 写死 `eDP-1` 内屏 | 自动检测所有输出 |
| 显卡 | Intel Iris Xe | VMSVGA（需开 3D 加速） |
| Guest Additions | 不需要 | 自动启用（含编译修复） |
| 启动方式 | BIOS + GRUB | 同样是 BIOS + GRUB（**不要开 EFI**） |

> 除上表外，分区、格式化、安装、登录等步骤与 README《安装教程》**完全相同**，
> 只是把设备名换成 `/dev/sda`、flake 名换成 `.#thinkbook-vm`。

---

## 1. 创建虚拟机（关键设置）

VirtualBox 新建虚拟机：

- **类型/版本**：Linux → Linux 2.6 / 3.x / 4.x (64-bit)
- **内存**：**6144–8192 MB**（4 GB 会在构建时 OOM 被 kill）
- **硬盘**：**60 GB**（动态分配）。40 GB 会因闭包 ~28 GB 而构建失败
- **系统 → 主板**：**不要勾"启用 EFI"**（本配置是 BIOS + GRUB）
- **系统 → 处理器**：4 核
- **显示**：
  - 显卡控制器：**VMSVGA**
  - ☑ **启用 3D 加速**（不勾会导致 niri 黑屏）
  - 显存：**128 MB**
- **网络**：NAT（默认）——安装时必须能联网
- 存储：光驱挂载 NixOS ISO

## 2. 启动 live 环境

启动虚拟机 → 进入 live 环境（root 自动登录）。图形安装器窗口会弹出来，
**关掉它**，用终端（`Ctrl+Alt+T`，或 `Ctrl+Alt+F2` 切文字终端）。

联网验证：

```bash
ping -c2 nixos.org
```

NAT 网络通常开箱即用；不通就 `sudo nmtui` 配一下。

## 3. 分区（`/dev/sda`）

与 README 第 4 节相同，只是设备是 `/dev/sda`：

```bash
lsblk                     # 确认是 /dev/sda
sudo fdisk /dev/sda
#   o      ← MBR 分区表（清空磁盘）
#   n → p → 1 → 回车 → 回车
#   a      ← 标记可启动
#   w      ← 写入
```

## 4. 格式化 + Btrfs 子卷

```bash
sudo mkfs.btrfs -L nixos /dev/sda1
sudo mount /dev/sda1 /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo umount /mnt
```

## 5. 挂载

```bash
sudo mount -o subvol=@,compress=zstd,noatime /dev/sda1 /mnt
sudo mkdir -p /mnt/{home,nix}
sudo mount -o subvol=@home,compress=zstd,noatime /dev/sda1 /mnt/home
sudo mount -o subvol=@nix,compress=zstd,noatime /dev/sda1 /mnt/nix
df -h /mnt | tail -1
```

## 6. 生成硬件配置 + 取仓库 + 安装

```bash
sudo nixos-generate-config --root /mnt
git clone https://github.com/Kingcxp/nixos.git /tmp/nixos_kingcq
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/nixos_kingcq/hosts/thinkbook/hardware-configuration.nix

# 生成的文件里若带 virtualisation.virtualbox.guest.enable = true; 是正常的
# （thinkbook-vm 已内置该选项与编译修复，无需手改）
grep virtualbox /tmp/nixos_kingcq/hosts/thinkbook/hardware-configuration.nix

sudo cp -r /tmp/nixos_kingcq /mnt/nixos_kingcq
cd /mnt/nixos_kingcq
sudo nixos-install --flake .#thinkbook-vm      # ← 注意是 -vm 变体
```

成功标志：

```
installing the GRUB 2 boot loader on /dev/sda...
Installation finished. No error reported.
```

## 7. 重启前**移除 ISO**

```bash
sudo reboot
```

在 VirtualBox 里先把光驱里的 ISO 弹出/移除（设备 → 光驱 → 移除磁盘），
**否则重启又会进安装器**。

## 8. 登录

GRUB 菜单（Catppuccin 主题）→ tuigreet → 用户名 `kingcq` / 密码 `123456`
→ 进入 niri 桌面。第一件事改密码：

```bash
passwd
```

把仓库接到 `/etc/nixos`（与真机相同）：

```bash
sudo mv /nixos_kingcq ~/nixos
sudo chown -R kingcq:users ~/nixos
sudo rm -rf /etc/nixos && sudo ln -s ~/nixos /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#thinkbook-vm
```

---

## 9. 实测记录与已知限制（2026-09 在 VirtualBox 7.2 复现验证）

以下问题全部实测复现过，附解法：

### VM 里必须开 3D 加速

不开 3D 时 niri 启动后只有深蓝空屏，日志报：

```
niri::backend::tty: failed to initialize renderer, falling back to primary gpu
niri::backend::tty: error adding primary node device ... no allocator available
```

→ VirtualBox 设置里勾选"启用 3D 加速"（VMSVGA）。

### 内存与磁盘

| 配置 | 结果 |
| --- | --- |
| 4 GB 内存 | `nix build` 被 OOM kill（构建中断） |
| 8 GB + 8 GB swapfile | 稳定通过 |
| 40 GB 磁盘 | 构建后期 `No space left on device`，一堆小包 `exit code 1` |
| **60 GB 磁盘** | 通过 |

### 26.05 ISO 的 hv_* 模块（只影响 live 环境）

live 环境启动时 `systemd-modules-load` 会尝试加载 Hyper-V 驱动失败，进入
emergency mode：**按回车进维护 shell，或用 Ctrl-D 继续引导**，不影响安装。

### live 环境 DNS 解析失败（实测遇到）

如果安装极慢、反复出现：

```
warning: unable to download 'https://cache.nixos.org/nar/....nar.zst':
  Timeout was reached ... Less than 1 bytes/sec transferred
error: some substitutes for the outputs of derivation '...' failed
  (usually happens due to networking issues)
```

先检查 DNS（`ping 8.8.8.8` 通但 `getent hosts cache.nixos.org` 失败即为此问题）：

```bash
cat /etc/resolv.conf                 # 若指向不通的 DNS（如校园网/公司 DNS）
echo 'nameserver 10.0.2.3' | sudo tee /etc/resolv.conf   # VirtualBox NAT 的 DNS
echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolv.conf
getent hosts cache.nixos.org         # 应能解析
```

修好后重跑 `nixos-install`；实测修复后 `cache.nixos.org` 可达 2.4 MB/s。

### 下载被截断导致构建失败

若报 `dpkg-deb: ... is truncated or corrupt`（例如 msedge 的 .deb），
是下载中断导致 store 里的文件损坏，用 Nix 自带修复重下：

```bash
sudo nix-store --verify --check-contents --repair
```

### niri 相关

- 输出：`thinkbook-vm` 变体自动检测所有输出，**无需手改 `output.kdl`**
- 撕裂/渲染毛刺：VMSVGA 的软件/半加速路径所致，真机（Intel 原生驱动）没有
- 鼠标指针、壁纸、waybar 均正常

## 10. 试装完 → 上真机

确认 VM 里能正常进桌面、网络/声音/输入法可用后，按 README《安装教程》在
真机上操作，把 `.#thinkbook-vm` 换回 **`.#thinkbook`**、设备名换回
`/dev/nvme0n1`。

> 记住：`hardware-configuration.nix` 一定要在目标机器上重新生成；
> 仓库里那份只是模板。

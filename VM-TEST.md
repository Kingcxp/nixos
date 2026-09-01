# 在 VirtualBox 虚拟机中试装 NixOS

先拿虚拟机练手、再上真机，是很稳的路径。虚拟机和你的真机有**三处关键差异**，
处理好了整个流程和真机安装几乎一样：

| 差异点 | 真机 (ThinkBook) | VirtualBox 虚拟机 |
| --- | --- | --- |
| 磁盘设备名 | `/dev/nvme0n1` | `/dev/sda`（SATA 虚拟盘） |
| 显卡 | Intel Iris Xe | VirtualBox 虚拟显卡（VMSVGA） |
| 显示器名 | `eDP-1` | VirtualBox 虚拟显示器名 |
| BIOS | UEFI | 需手动开启 EFI（默认可能是 BIOS） |

下面每一步都可以复用 README 里的安装教程，这里只讲**虚拟机特定的部分**。

---

## 1. 创建虚拟机

VirtualBox 新建虚拟机，关键设置：

- **类型/版本**：Linux → Linux 2.6 / 3.x / 4.x (64-bit)
- **内存**：建议 4096 MB 以上（niri + 浏览器够用）
- **硬盘**：40 GB 即可（动态分配），格式 VDI 或 VMDK 都行
- **系统 → 主板**：
  - ☑ 启用 EFI（**必须开**，本配置是 systemd-boot/UEFI 布局）
  - ☑ 启用 IO/APIC
- **系统 → 处理器**：2–4 核
- **显示**：
  - 显卡控制器：**VMSVGA**
  - ☑ 启用 3D 加速，显存 128 MB
- **网络**：默认 NAT（能上网下载包即可）；`nixos-install` 需要联网

## 2. 挂载安装 ISO 并启动

虚拟机设置 → 存储 → 光驱 → 选择下载的 NixOS ISO →
启动虚拟机，选默认 "NixOS" 进入 live 环境。

> live 环境默认是 root，没有图形界面，是一个 TTY。

## 3. 分区（虚拟盘）

与 README 教程相同，只是设备是 `/dev/sda`：

```bash
# 查看虚拟盘
lsblk

# 分区：sda1 = EFI (512M)，sda2 = Btrfs 剩余全部
sudo fdisk /dev/sda   # 交互式：g 建 GPT，n 建两个分区，t 设第一个为 EFI
```

格式化与子卷：

```bash
sudo mkfs.fat -F 32 /dev/sda1
sudo mkfs.btrfs -L nixos /dev/sda2

sudo mount /dev/sda2 /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo umount /mnt
```

挂载：

```bash
sudo mount -o subvol=@,compress=zstd,noatime /dev/sda2 /mnt
sudo mkdir -p /mnt/{boot,home,nix}
sudo mount -o subvol=@home,compress=zstd,noatime /dev/sda2 /mnt/home
sudo mount -o subvol=@nix,compress=zstd,noatime /dev/sda2 /mnt/nix
sudo mount /dev/sda1 /mnt/boot
```

## 4. 生成硬件配置并放仓库

```bash
sudo nixos-generate-config --root /mnt
cat /mnt/etc/nixos/hardware-configuration.nix   # 确认是 /dev/sda 的 UUID
```

把这个生成的文件复制到本仓库：

```bash
cp /mnt/etc/nixos/hardware-configuration.nix hosts/thinkbook/hardware-configuration.nix
```

## 5. 获取本仓库（虚拟机里）

live 环境要拿到本仓库，两种方式：

**方式 A：git clone（需联网 GitHub）**

```bash
git clone https://github.com/Kingcxp/nixos.git /tmp/nixos_kingcq
```

**方式 B：共享文件夹（推荐，网络差时最稳）**

1. VirtualBox 菜单 → 设备 → 共享文件夹 → 添加本机仓库目录，勾选"自动挂载"
2. live 环境里：

```bash
sudo mkdir -p /mnt/host-repo
sudo mount -t vboxsf <共享名> /mnt/host-repo
cp -r /mnt/host-repo /tmp/nixos_kingcq
```

> 若 `vboxsf` 模块不在 live 里，先 `sudo modprobe vboxsf`。

## 6. 复制仓库进 /mnt 并安装

```bash
sudo cp -r /tmp/nixos_kingcq /mnt/nixos_kingcq
cd /mnt/nixos_kingcq
sudo nixos-install --flake .#thinkbook
```

> **主机名仍是 `thinkbook`**，虚拟机里也用它，不影响。装完想区分可
> 改 `hosts/thinkbook/default.nix` 里的 `networking.hostName`，但这是
> 共享文件，真机装时记得改回来。

## 7. 设置密码并重启

```bash
sudo nixos-chroot /mnt passwd kingcq
sudo reboot
```

## 8. 虚拟机里可能遇到的小问题

### niri 桌面黑屏 / 显示器不对

本仓库 `home-manager/desktop/niri/config/output.kdl` 写死了 `eDP-1`，
虚拟机里显示器名不同，可能没有输出。修复：

```bash
# 在 niri 会话里查看实际输出名
niri msg outputs
```

然后临时把 `output.kdl` 里的 `output "eDP-1"` 注释掉或改成实际名字，
重新 `nixos-rebuild switch --flake /etc/nixos#thinkbook`。

> 或者更省事：VM 里先注释掉整个 output 块让 niri 自动检测。
> **真机安装时恢复 eDP-1。**

### 3D 加速 / 动画卡顿

VirtualBox 的 Wayland 合成器性能一般。若动画卡顿，可在
`misc.kdl` 的 `animations` 里加 `off` 临时关掉动画，真机再开。

### 亮度键无效

VM 里没有真实背光，亮度键和 waybar 亮度模块会显示但无效，属正常。
真机上恢复。

### 触摸板/触控板手势

VM 里没有真实触摸板，`input.kdl` 的触摸板设置不影响虚拟机。真机恢复。

---

## 9. 试装完 → 真机安装

确认在 VM 里能正常进入 niri 桌面、waybar 显示、软件可用后，返回真机安装：

1. `git pull` 本仓库最新（VM 里若改过 output.kdl 等，先改回真机版本）
2. 按主 README 的「完整安装教程」在真机执行（磁盘是 `/dev/nvme0n1`，
   显示器是 `eDP-1`，Intel 显卡参数生效）
3. 真机上 `nixos-generate-config` 重新生成 hardware-configuration.nix

---

> 记住核心原则：**hardware-configuration.nix 一定要在目标机（真机）上
> 重新生成**，仓库里那份只是模板。
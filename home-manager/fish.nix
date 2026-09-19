{
  pkgs,
  lib,
  ...
}:
{
  # Shell — fish（默认 shell），用 oh-my-posh 美化，插件用 home-manager 声明式管理。
  # NixOS 上不推荐 fisher：它会在运行时改写 ~/.config/fish，破坏 Nix 的声明式
  # 与可复现性。改用 programs.fish.plugins（nixpkgs 内置 fishPlugins）即可，
  # 升级/回滚都随系统走。
  programs.fish = {
    enable = true;
    shellInit = ''
      # 基础环境变量
      export MICRO_TRUECOLOR=1
      export EDITOR=nvim

      # oh-my-posh 提示符（clean-detailed 主题）
      if type -q oh-my-posh
        oh-my-posh init fish --config ~/.config/oh-my-posh/clean-detailed.omp.json | source
      end

      # Homebrew（若已安装；未装时由 systemd 服务 homebrew-bootstrap 自动安装）
      if test -x /home/linuxbrew/.linuxbrew/bin/brew
        eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
      end

      # zoxide 智能目录跳转（z）
      if type -q zoxide
        zoxide init fish | source
      end

      # ~/.local/bin 优先（容纳自更新工具，如 omp）
      fish_add_path -p ~/.local/bin

      # bun：全局安装的包落在 ~/.bun/bin（对齐 Arch 的 fish config）
      set --export BUN_INSTALL "$HOME/.bun"
      fish_add_path -p ~/.bun/bin

      # 常用别名
      alias update="sudo nixos-rebuild switch"
      alias ll="ls -la"
      alias la="ls -A"
      alias lt="eza --tree --level=2"
      alias cat="bat"
      alias find="fd"
    '';

    # 自动更新脚本（需要自更新的软件：NixOS 系统走 flake update，
    # Homebrew 与 oh-my-pi 二进制由脚本拉取最新版；API 稳定、无破坏性变更）
    # 自动更新脚本（需要自更新的软件：NixOS 系统走 flake update，
    # Homebrew 与 oh-my-pi 二进制由脚本拉取最新版；API 稳定、无破坏性变更）
    # 注意：home-manager 会自动包一层 function 定义，这里只写函数体。
    functions = {
      # 统一更新入口：nixos update（列出 → 确认 → 更新；支持按组件选择）
      nixos = ''
        switch "$argv[1]"
          case update
            set -e argv[1]
            nixos-update $argv
          case help "" 
            echo "用法: nixos update [选项] [组件…]"
            echo "选项: -y 免确认 | -l 只列出 | -i fzf 多选"
            echo "组件: all flake <input名> brew omp firmware"
          case '*'
            echo "未知子命令: $argv[1]（可用: nixos update）" >&2
            return 1
        end
      '';

      # 检查+更新：系统(flake inputs)、Homebrew、oh-my-pi、固件
      nixos-update = ''
        set -l repo ~/nixos
        set -l yes 0; set -l list 0; set -l inter 0; set -l sel
        for a in $argv
          switch $a
            case -y --yes
              set yes 1
            case -l --list
              set list 1
            case -i --interactive
              set inter 1
            case -h --help
              echo "用法: nixos update [选项] [组件…]"
              echo "选项: -y 免确认 | -l 只列出 | -i fzf 多选"
              echo "组件: all flake <flake-input名> brew omp firmware"
              return 0
            case '*'
              set -a sel $a
          end
        end

        # ---------- 1. 检查 flake inputs（在临时副本上算，不动真仓库）----------
        set -l tmp (mktemp -d)
        cp $repo/flake.nix $repo/flake.lock $tmp/ 2>/dev/null
        set -l flake_changes
        if nix flake update --flake $tmp >/dev/null 2>&1
          set flake_changes (python3 -c "
import json
old = json.load(open('$repo/flake.lock'))['nodes']
new = json.load(open('$tmp/flake.lock'))['nodes']
for k in sorted(set(old) | set(new)):
    o = old.get(k, {}).get('locked', {})
    n = new.get(k, {}).get('locked', {})
    if o.get('rev') != n.get('rev'):
        print(k)
")
        end
        rm -rf $tmp

        # ---------- 2. 组装可更新清单 ----------
        set -l items   # 每项: 组件名|描述
        if test (count $flake_changes) -gt 0
          set -a items "flake|系统/全部 flake inputs（"(string join ', ' $flake_changes)"）"
          for i in $flake_changes
            set -a items "$i|flake input: $i"
          end
        end
        if type -q brew
          set -l bo (brew outdated --quiet 2>/dev/null | head -20)
          if test (count $bo) -gt 0
            set -a items "brew|Homebrew 包（"(string join ', ' $bo)"）"
          end
        end
        if type -q omp
          set -l cur (omp --version 2>/dev/null | head -1 | string replace -r '^omp/' "" | string trim)
          set -l latest (curl -sI -m 8 https://github.com/can1357/oh-my-pi/releases/latest 2>/dev/null | string match -ri '^location:.*/tag/(.*)$' | tail -1 | string replace -r '^v' """" | string trim)
          if test -n "$latest"; and test "$latest" != "$cur"
            set -a items "omp|oh-my-pi（当前 $cur → 最新 $latest）"
          end
        end
        if type -q fwupdmgr
          set -l fw (fwupdmgr get-updates 2>/dev/null | string match -r "^\s*\S+.*(→|->)\s*\S+" | head -5)
          if test (count $fw) -gt 0
            set -a items "firmware|固件更新（"(count $fw)" 项）"
          end
        end

        if test (count $items) -eq 0
          echo "✓ 没有可更新的内容"
          return 0
        end

        echo "可更新项："
        for it in $items
          echo "  • "(string replace "|" " — " $it)
        end
        if test $list -eq 1
          return 0
        end

        # ---------- 3. 选择范围 ----------
        set -l chosen
        if test (count $sel) -gt 0
          for w in $sel
            if test "$w" = all
              set chosen (for it in $items; echo (string split -f1 "|" $it); end)
            else
              set -a chosen $w
            end
          end
        else if test $inter -eq 1 -a (type -q fzf)
          set chosen (for it in $items; echo $it; end | fzf --multi --prompt="选择要更新的组件> " | string replace -r "\|.*" "")
        else
          # 默认：用 flake 整体项 + brew/omp/firmware（不单独拆 input）
          for it in $items
            set -l n (string split -f1 "|" $it)
            switch $n
              case brew omp firmware
                set -a chosen $n
              case flake
                if not contains flake $chosen
                  set -a chosen flake
                end
            end
          end
        end

        if test (count $chosen) -eq 0
          echo "已取消"
          return 0
        end

        if test $yes -eq 0
          echo "将更新: "(string join ' ' $chosen)
          read -l -P "继续？[y/N] " ans
          if not string match -qi y -- $ans
            echo "已取消"
            return 0
          end
        end

        # ---------- 4. 执行 ----------
        set -l need_rebuild 0
        set -l flake_inputs
        for c in $chosen
          switch $c
            case flake
              set need_rebuild 1
            case brew
              echo "→ 更新 Homebrew…"
              brew update; and brew upgrade
            case omp
              update-omp
            case firmware
              echo "→ 更新固件（重启后生效的胶囊更新会暂存）…"
              sudo fwupdmgr refresh --force; and sudo fwupdmgr update -y --no-reboot-check
            case '*'
              set -a flake_inputs $c
              set need_rebuild 1
          end
        end

        # ---------- 5. flake 更新 + 重建 ----------
        if test $need_rebuild -eq 1
          echo "→ 拉取仓库最新配置…"
          git -C $repo pull --ff-only
          if test (count $flake_inputs) -gt 0
            echo "→ 更新 flake inputs: "(string join ' ' $flake_inputs)
            nix flake update --flake $repo $flake_inputs
          else
            echo "→ 更新全部 flake inputs…"
            nix flake update --flake $repo
          end

          # 镜像探测：cernet 为主力（大陆快），不通则回退官方源
          set -l subs "https://cache.nixos.org https://nix-community.cachix.org"
          if curl -sf -m 5 -o /dev/null https://mirrors.cernet.edu.cn/nix-channels/store/nix-cache-info
            set subs "https://mirrors.cernet.edu.cn/nix-channels/store $subs"
          else
            echo "（cernet 镜像不可达，本次使用官方源）"
          end

          set -l host thinkbook
          if systemd-detect-virt --vm --quiet
            set host thinkbook-vm
          end
          echo "→ 重建系统（$host）…"
          sudo nixos-rebuild switch --flake /etc/nixos#$host --option substituters "$subs"
        end

        echo "✓ 更新流程完成"
      '';

      # 手动检查/安装固件更新（自动更新见 systemd timer fwupd-auto-update）
      fwupdate = ''
        echo "→ 刷新固件元数据..."
        fwupdmgr refresh --force
        echo "→ 可用更新："
        fwupdmgr get-updates
        echo "→ 安装更新（BIOS 类更新重启后生效）："
        fwupdmgr update
      '';

      # 单独更新 oh-my-pi（上游二进制；Nix 包固定版本故需脚本拉最新）
      update-omp = ''
        mkdir -p ~/.local/bin
        echo "→ 下载 omp 最新版..."
        curl -fL --progress-bar \
          https://github.com/can1357/oh-my-pi/releases/latest/download/omp-linux-x64 \
          -o ~/.local/bin/omp; or return 1
        chmod +x ~/.local/bin/omp
        echo "✓ omp 已更新"
      '';
    };

    # 声明式插件（nixpkgs fishPlugins），全部随系统构建、可回滚
    plugins = [
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish; # Ctrl+R 历史搜索、Ctrl+T 文件搜索
      }
      {
        name = "z";
        src = pkgs.fishPlugins.z; # 目录跳转（zoxide 已提供更优实现，此插件可选）
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done; # 长命令完成时桌面通知
      }
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit; # git + fzf 交互辅助
      }
      {
        name = "colored-man-pages";
        src = pkgs.fishPlugins.colored-man-pages; # man 手册彩色高亮
      }
    ];
  };

  # 常用命令辅助工具
  home.packages = with pkgs; [
    oh-my-posh
    fzf # 模糊查找
    fd # find 的现代替代
    bat # cat 的语法高亮替代
    eza # ls 的现代替代
    zoxide # 智能 cd（z）
    ripgrep # grep 的现代替代
    tldr # 命令速查
  ];

  # oh-my-posh 主题
  xdg.configFile."oh-my-posh/clean-detailed.omp.json".source =
    ./oh-my-posh/clean-detailed.omp.json;
}

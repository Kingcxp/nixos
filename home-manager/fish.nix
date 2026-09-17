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

      # zoxide 智能目录跳转（z）
      if type -q zoxide
        zoxide init fish | source
      end

      # ~/.local/bin 优先（容纳自更新工具，如 omp）
      fish_add_path -p ~/.local/bin

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
      # 一次更新全部：仓库 → flake inputs → 系统 → Homebrew
      update-all = ''
        # 自动识别运行环境：VM 用 thinkbook-vm，真机用 thinkbook
        set -l host thinkbook
        if systemd-detect-virt --vm --quiet
          set host thinkbook-vm
        end

        echo "→ 拉取仓库最新配置..."
        git -C ~/nixos pull --ff-only; or return 1

        echo "→ 更新 flake inputs（nixpkgs 等）..."
        nix flake update --flake ~/nixos

        echo "→ 重建系统（目标：$host）..."
        sudo nixos-rebuild switch --flake /etc/nixos#$host; or return 1

        if type -q brew
          echo "→ 更新 Homebrew..."
          brew update; and brew upgrade
        end

        echo "✓ 全部更新完成"
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

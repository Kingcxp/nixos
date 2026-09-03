{
  pkgs,
  ...
}:
{
  # Visual Studio Code — 声明式安装扩展与配置。
  # 扩展随 nixpkgs 版本锁定，升级系统（nix flake update + rebuild）即自动更新。
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default.extensions = with pkgs.vscode-extensions; [
      # 语言支持
      rust-lang.rust-analyzer
      golang.go
      ms-python.python
      ms-python.vscode-pylance
      ms-python.debugpy
      ms-python.vscode-python-envs
      ms-toolsai.jupyter
      ms-toolsai.jupyter-keymap
      ms-toolsai.jupyter-renderers
      ms-toolsai.vscode-jupyter-cell-tags
      ms-toolsai.vscode-jupyter-slideshow
      vscjava.vscode-java-pack
      vscjava.vscode-java-debug
      vscjava.vscode-gradle
      vscjava.vscode-maven
      redhat.java
      redhat.vscode-yaml
      ms-vscode.cpptools
      ms-vscode.cmake-tools
      ms-vscode.hexeditor
      ms-vscode.makefile-tools
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-containers
      ms-azuretools.vscode-docker
      ms-ceintl.vscode-language-pack-zh-hans
      # 工具
      esbenp.prettier-vscode
      dbaeumer.vscode-eslint
      editorconfig.editorconfig
      pkief.material-icon-theme
      catppuccin.catppuccin-vsc
      yzhang.markdown-all-in-one
      shd101wyy.markdown-preview-enhanced
      marp-team.marp-vscode
      mhutchie.git-graph
      mechatroner.rainbow-csv
      mikestead.dotenv
      christian-kohler.path-intellisense
      aaron-bond.better-comments
      adpyke.codesnap
      alefragnani.project-manager
      github.vscode-github-actions
      codezombiech.gitignore
      ecmel.vscode-html-css
      formulahendry.auto-close-tag
      formulahendry.code-runner
      vadimcn.vscode-lldb
      myriad-dreamin.tinymist
      njpwerner.autodocstring
      tamasfe.even-better-toml
      wakatime.vscode-wakatime
      vue.volar
      tomoki1207.pdf
    ];
  };

  # 用户设置（保留 JSONC 注释，原样部署）
  xdg.configFile."Code/User/settings.json".source = ./settings.json;
}

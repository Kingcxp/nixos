{
  pkgs,
  ...
}:
# 开发环境：覆盖常用语言的工具链（Python / C/C++ / Go / Rust / Java / JS-TS）。
#
# 系统层装"常驻工具链"——全局可用、来自 binary cache；
# 版本敏感/依赖隔离的场景用项目目录的 `nix develop`（见 USAGE.md）。
{
  environment.systemPackages = with pkgs; [
    # ---------- Python ----------
    python3
    uv # 极快的 Python 包/项目管理器（pip/venv 替代）
    virtualenv
    conda # conda 包管理器（需要科学计算发行版时用）
    python3Packages.pip

    # ---------- C / C++ ----------
    gcc
    gnumake
    cmake
    ninja
    pkg-config
    binutils
    gdb
    ccache
    xmake
    clang
    clang-tools # clangd 等 C/C++ 工具链
    llvm
    lld

    # ---------- Go ----------
    go
    gopls
    gotools

    # ---------- Rust ----------
    rustup # rustc/cargo/clippy 由 rustup 管理（默认 stable 工具链）
    rust-analyzer

    # ---------- Java ----------
    openjdk21
    maven
    gradle

    # ---------- JS / TS（Vue/HTML/CSS/JS/TS） ----------
    nodejs_22
    pnpm
    typescript-language-server
  ];

  # rustup 需要显式选择工具链 profile（stable），首次 `rustup default stable`
  # 由用户执行；这里预置环境变量避免每次询问。
  environment.variables.RUSTUP_TOOLCHAIN = "stable";

  # Java：openjdk21 为默认 jre/jdk
  programs.java = {
    enable = true;
    package = pkgs.openjdk21;
  };
}

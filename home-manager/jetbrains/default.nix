{
  pkgs,
  ...
}:
{
  # JetBrains IDEs — 声明式安装，随 nixpkgs 版本锁定，升级系统即自动更新。
  # IDEA 使用统一的 IntelliJ IDEA（Community 版已并入 unified distribution）。
  # PyCharm 未安装：当前 nixpkgs 版本存在已知安全漏洞（NIXPKGS-2026-2269）
  # 被标记 insecure，Python 开发由 VSCode + ms-python 扩展覆盖。
  # 其他 IDE（CLion/GoLand/WebStorm 等）如需可在此追加。
  home.packages = with pkgs; [
    jetbrains.idea
  ];
}

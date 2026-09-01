{ pkgs, ... }:
let
  # User's Neovim config (AstroNvim-based). Plugins install via lazy.nvim at
  # first launch, so we only ship the config + a complete nvim toolchain.
  lspTools = with pkgs; [
    lua-language-server
    nixd
    alejandra
    stylua
    tree-sitter
    bash-language-server
    yaml-language-server
    vscode-json-languageserver
    gopls
  ];
in
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;
    withRuby = false;
    defaultEditor = true;
  };

  home.packages = lspTools;

  # Ship the user's nvim config tree
  xdg.configFile."nvim" = {
    source = ./config;
    recursive = true;
  };
}

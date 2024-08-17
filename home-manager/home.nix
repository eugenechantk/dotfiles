{ config, pkgs, shellConfig, ... }:
let

  zshrc = ''
    export EDITOR="nvim"

    # Oh My Zsh config
    ZSH_THEME="robbyrussell"
    plugins=(git brew kubectl aws bun github npm)

    bindkey -v

  '';
  postzshrc = ''
    eval "$(atuin init zsh)"
  '';

  randomAliases = ''
    #/usr/bin/env zsh

    alias awswho="aws sts get-caller-identity"

    alias configs="code $(dirname $0)"
    function delete-untracked-interactive() {
        git reset
        #fzf loop to delete untracked files
        while true; do
            untracked_files=$(git ls-files --others --exclude-standard)
            if [ -z "$untracked_files" ]; then
                echo "No untracked files to delete."
                return
            fi
            file=$(echo "$untracked_files" | fzf --prompt="Select file to delete (Ctrl+C to exit): ")
            if [ -z "$file" ]; then
                break
            fi
            rm "$file"
        done
    }

    function flakebuild() {
      is_staged=$(git diff --cached --name-only)
      if [[ -n $is_staged ]]; then
        echo "Saving staged state"
        save_staged_state_and_reset
        echo "Adding all files"
      fi
      git add -A
      echo "Building flake"
      nix build $@
      git reset
      if [[ -n $is_staged ]]; then
        echo "Staged state reapply"
        apply_staged_state
      fi
    }

    function flakeupdate() {
      is_staged=$(git diff --cached --name-only)
      if [[ -n $is_staged ]]; then
        echo "There are staged changes. Please commit or stash them before updating the flake."
        return 1
      fi
      nix flake update
      git add flake.lock
      git commit --edit --message="Update flake"
    }

    alias dirrel="direnv reload"

  '';
in {
  home.username = "eugenechan";
  home.homeDirectory = "/Users/eugenechan";
  home.stateVersion = "24.05";

  home.packages = [
    pkgs.htop
    pkgs.nerdfonts
    pkgs.atuin
    pkgs.zsh
    pkgs.btop
    pkgs.neovim
    pkgs.tmux
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.python3Packages.virtualenv
    pkgs.k9s
    pkgs.docker
    pkgs.nodejs
    pkgs.nodePackages_latest.vercel
    pkgs.pnpm
    pkgs.gh
    pkgs.spotify
    pkgs.postman
    pkgs.nixfmt
    pkgs.magic-wormhole-rs
    pkgs.lens
    pkgs.awscli
  ];
  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;

    initExtraFirst = zshrc;
    initExtra = postzshrc + randomAliases;

    shellAliases = {
      "reload-home-manager" =
        "zsh -c 'cd ~/dev/dotfiles/home-manager && nix --extra-experimental-features nix-command --extra-experimental-features flakes run home-manager/release-24.05 -- switch --flake ~/dev/dotfiles/home-manager#home --extra-experimental-features nix-command --extra-experimental-features flakes' && zsh";
    };
    oh-my-zsh = { enable = true; };
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''

      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",*256col*:Tc"
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
      set-environment -g COLORTERM "truecolor"

      # Mouse works as expected
      set-option -g mouse on
      # easy-to-remember split pane commands
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
    '';
  };

  programs.starship = {
    enable = true;
    settings = { kubernetes.disabled = false; };
  };
  programs.git = {
    enable = true;
    userName = "eugenechantk";
    userEmail = "me@eugenechantk.me";
    extraConfig = { push = { autoSetupRemote = true; }; };
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  home.sessionVariables = { REDITOR = "nvim"; };

}

#!/usr/bin/env bash

set -euo pipefail

DOTFILES_REPO="https://github.com/specious/dotfiles"
DOTFILES_REF="master"
BENDER_REPO="https://github.com/specious/bender"
BASH_PROMPT_URL="https://gist.githubusercontent.com/specious/8244801/raw"

# Work in a temp dir
TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

# Clone dotfiles (shallow, pinned branch)
if ! git clone --depth=1 --branch "${DOTFILES_REF}" "${DOTFILES_REPO}" "${TMPDIR}/dotfiles"; then
  echo "Error: failed to clone ${DOTFILES_REPO}" >&2
  exit 1
fi

# Copy vimrc into user home (install sets predictable perms)
if [ -f "${TMPDIR}/dotfiles/vimrc" ]; then
  install -m 0644 "${TMPDIR}/dotfiles/vimrc" "${HOME}/.vimrc" || true
fi

# Symlink Neovim config to use unified vimrc
mkdir -p "${HOME}/.config/nvim"
ln -sf "${HOME}/.vimrc" "${HOME}/.config/nvim/init.vim"

# Copy /etc/sh fragments into place (requires sudo); use install for perms
if [ -f "${TMPDIR}/dotfiles/sh-base.sh" ]; then
  sudo install -m 0644 "${TMPDIR}/dotfiles/sh-base.sh" /etc/sh-base.sh
fi
if [ -f "${TMPDIR}/dotfiles/sh-linux.sh" ]; then
  sudo install -m 0644 "${TMPDIR}/dotfiles/sh-linux.sh" /etc/sh-linux.sh
fi

# Ensure /etc/sh sources them (idempotent)
sudo touch /etc/sh
if ! sudo grep -qxF '. /etc/sh-base.sh' /etc/sh 2>/dev/null; then
  echo '. /etc/sh-base.sh' | sudo tee -a /etc/sh >/dev/null
fi
if [ -f /etc/sh-linux.sh ] && ! sudo grep -qxF '. /etc/sh-linux.sh' /etc/sh 2>/dev/null; then
  echo '. /etc/sh-linux.sh' | sudo tee -a /etc/sh >/dev/null
fi
sudo chmod 644 /etc/sh

# Install or update oh-my-zsh in the user's home (non-interactive)
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${HOME}/.oh-my-zsh"
else
  (cd "${HOME}/.oh-my-zsh" && git pull --ff-only || true)
fi

# Ensure a .zshrc exists and set theme to bender
if [ ! -f "${HOME}/.zshrc" ]; then
  cp "${HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${HOME}/.zshrc"
fi
mkdir -p "${HOME}/.oh-my-zsh/custom/themes"

# Clone or update bender theme and copy into themes
if [ ! -d "${TMPDIR}/bender" ]; then
  git clone --depth=1 "${BENDER_REPO}" "${TMPDIR}/bender"
else
  (cd "${TMPDIR}/bender" && git pull --ff-only || true)
fi
if [ -f "${TMPDIR}/bender/bender.zsh-theme" ]; then
  install -m 0644 "${TMPDIR}/bender/bender.zsh-theme" "${HOME}/.oh-my-zsh/custom/themes/bender.zsh-theme"
fi

# Set ZSH_THEME="bender" in .zshrc (idempotent)
if grep -q '^ZSH_THEME=' "${HOME}/.zshrc"; then
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="bender"/' "${HOME}/.zshrc"
else
  echo 'ZSH_THEME="bender"' >> "${HOME}/.zshrc"
fi

# Append bash prompt (bender bash) into system bashrc so it's available system-wide
if curl -fsSL "${BASH_PROMPT_URL}" -o "${TMPDIR}/bender-bash.sh"; then
  if ! sudo grep -qxF '# bender bash prompt start' /etc/bash.bashrc 2>/dev/null; then
    sudo bash -c 'printf "%s\n" "# bender bash prompt start" >> /etc/bash.bashrc'
    sudo bash -c 'cat >> /etc/bash.bashrc' < "${TMPDIR}/bender-bash.sh"
    sudo bash -c 'printf "%s\n" "# bender bash prompt end" >> /etc/bash.bashrc'
  fi
fi

# Install rupa/z for fast directory jumping (idempotent)
Z_DIR="${HOME}/.local/share/z"
mkdir -p "${Z_DIR}"
if [ ! -d "${Z_DIR}/.git" ]; then
  git clone --depth=1 https://github.com/rupa/z.git "${Z_DIR}"
else
  (cd "${Z_DIR}" && git pull --ff-only || true)
fi
Z_SOURCE_LINE='. "$HOME/.local/share/z/z.sh"'
if ! sudo grep -qxF "$Z_SOURCE_LINE" /etc/sh 2>/dev/null; then
  echo "$Z_SOURCE_LINE" | sudo tee -a /etc/sh >/dev/null
fi

# Ensure ownership of home files (use numeric uid:gid to avoid name resolution issues)
TARGET_UID="${SUDO_UID:-$(id -u)}"
TARGET_GID="${SUDO_GID:-$(id -g)}"
sudo chown -R "${TARGET_UID}:${TARGET_GID}" "${HOME}"

echo "dotfiles and theme installed; oh-my-zsh configured for ${USER}."

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
git clone --depth=1 --branch "${DOTFILES_REF}" "${DOTFILES_REPO}" "${TMPDIR}/dotfiles"

# Copy vimrc into user home
cp "${TMPDIR}/dotfiles/vimrc" "${HOME}/.vimrc" || true

# Copy /etc/sh fragments into place (requires sudo)
if [ -f "${TMPDIR}/dotfiles/sh-base.sh" ]; then
  sudo cp "${TMPDIR}/dotfiles/sh-base.sh" /etc/sh-base.sh
fi
if [ -f "${TMPDIR}/dotfiles/sh-linux.sh" ]; then
  sudo cp "${TMPDIR}/dotfiles/sh-linux.sh" /etc/sh-linux.sh
fi

# Ensure /etc/sh sources them
echo ". /etc/sh-base.sh" | sudo tee /etc/sh >/dev/null
echo ". /etc/sh-linux.sh" | sudo tee -a /etc/sh >/dev/null
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
# Create custom themes dir if missing
mkdir -p "${HOME}/.oh-my-zsh/custom/themes"

# Clone or update bender theme and copy into themes
if [ ! -d "${TMPDIR}/bender" ]; then
  git clone --depth=1 "${BENDER_REPO}" "${TMPDIR}/bender"
fi
if [ -f "${TMPDIR}/bender/bender.zsh-theme" ]; then
  cp "${TMPDIR}/bender/bender.zsh-theme" "${HOME}/.oh-my-zsh/custom/themes/bender.zsh-theme"
fi

# Set ZSH_THEME="bender" in .zshrc (idempotent)
if grep -q '^ZSH_THEME=' "${HOME}/.zshrc"; then
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="bender"/' "${HOME}/.zshrc"
else
  echo 'ZSH_THEME="bender"' >> "${HOME}/.zshrc"
fi

# Append bash prompt (bender bash) into system bashrc so it's available system-wide
# Use the raw gist URL to fetch the prompt snippet
if curl -fsSL "${BASH_PROMPT_URL}" -o "${TMPDIR}/bender-bash.sh"; then
  sudo bash -c 'cat >> /etc/bash.bashrc' < "${TMPDIR}/bender-bash.sh"
fi

# Ensure ownership of home files
sudo chown -R "$(id -u):$(id -g)" "${HOME}"

# Done
echo "dotfiles and theme installed; oh-my-zsh configured for ${USER}."

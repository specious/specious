#!/usr/bin/env bash

set -euo pipefail

# Persist full transcript for debugging
exec > >(tee -a "${HOME}/postcreate.log") 2>&1

DOTFILES_REPO="https://github.com/specious/dotfiles"
DOTFILES_REF="master"
BENDER_REPO="https://github.com/specious/bender"
BASH_PROMPT_URL="https://gist.githubusercontent.com/specious/8244801/raw"
Z_DIR="${HOME}/.local/share/z"

log() { echo "==> $*"; }

#
# Work in a temp dir, cleaned up on exit
#

TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

#
# Dotfiles
#

log "Cloning dotfiles..."
git clone --depth=1 --branch "${DOTFILES_REF}" "${DOTFILES_REPO}" "${TMPDIR}/dotfiles"

log "Installing dotfiles..."
install -m 0644 "${TMPDIR}/dotfiles/vimrc"     "${HOME}/.vimrc"
install -m 0644 "${TMPDIR}/dotfiles/tmux.conf" "${HOME}/.tmux.conf"
install -m 0644 "${TMPDIR}/dotfiles/tigrc"     "${HOME}/.tigrc"

#
# Neovim config
#

log "Configuring neovim..."
mkdir -p "${HOME}/.config/nvim"
ln -sf "${HOME}/.vimrc" "${HOME}/.config/nvim/init.vim"
sudo ln -sf "$(which nvim)" /usr/local/bin/v

#
# Shell config stack (/etc/sh)
#

log "Installing shell config fragments..."
sudo install -m 0644 "${TMPDIR}/dotfiles/sh-base.sh" /etc/sh-base.sh
sudo install -m 0644 "${TMPDIR}/dotfiles/sh-linux.sh" /etc/sh-linux.sh

sudo touch /etc/sh && sudo chmod 644 /etc/sh
printf '. /etc/sh-base.sh\n'  | sudo tee -a /etc/sh >/dev/null
printf '. /etc/sh-linux.sh\n' | sudo tee -a /etc/sh >/dev/null
printf '\n# Local machine configuration\n\n' | sudo tee -a /etc/sh >/dev/null

#
# oh-my-zsh
#

log "Installing oh-my-zsh..."
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${HOME}/.oh-my-zsh"
cp "${HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${HOME}/.zshrc"

#
# Bender zsh theme
#

log "Installing bender zsh theme..."
git clone --depth=1 "${BENDER_REPO}" "${TMPDIR}/bender"
mkdir -p "${HOME}/.oh-my-zsh/custom/themes"
install -m 0644 "${TMPDIR}/bender/bender.zsh-theme" "${HOME}/.oh-my-zsh/custom/themes/bender.zsh-theme"

if grep -q '^ZSH_THEME=' "${HOME}/.zshrc"; then
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="bender"/' "${HOME}/.zshrc"
else
  echo 'ZSH_THEME="bender"' >> "${HOME}/.zshrc"
fi

#
# Bender bash prompt (system-wide)
#

log "Installing bender bash prompt..."
curl -fsSL "${BASH_PROMPT_URL}" -o "${TMPDIR}/bender-bash.sh"
{
  printf '# bender bash prompt start\n'
  cat "${TMPDIR}/bender-bash.sh"
  printf '# bender bash prompt end\n'
} | sudo tee -a /etc/bash.bashrc >/dev/null

#
# Finalize zshrc and bashrc
#

log "Finalizing shell rc files..."
printf '\nunalias md gg\n' >> "${HOME}/.zshrc"
printf '\n. /etc/sh\n'     >> "${HOME}/.zshrc"
printf '\n. /etc/sh\n'     >> "${HOME}/.bashrc"

#
# rupa/z — fast directory jumping
#

log "Installing rupa/z..."
mkdir -p "${Z_DIR}"
git clone --depth=1 https://github.com/rupa/z.git "${Z_DIR}"
printf '. "$HOME/.local/share/z/z.sh"\n' | sudo tee -a /etc/sh >/dev/null

#
# Fix ownership
#

log "Fixing home directory ownership..."
sudo chown -R "$(id -u):$(id -g)" "${HOME}"

log "Done. dotfiles and theme installed; oh-my-zsh configured for ${USER}."

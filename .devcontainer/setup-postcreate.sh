#!/usr/bin/env bash

set -euo pipefail

# Persist full transcript for debugging
exec > >(tee -a "${HOME}/postcreate.log") 2>&1

log() { echo "==> $*"; }

#
# This script runs once after container creation.
#
# The base image already includes all dotfiles, shell config, neovim setup,
# oh-my-zsh with the bender theme, and rupa/z. Nothing needs to be installed
# here by default.
#
# Use this script for setup that cannot be baked into the image:
#   - Secrets or tokens (e.g. gh auth login)
#   - Machine-specific git config (e.g. git config user.email)
#   - Runtime mounts or symlinks to host paths
#   - Anything that depends on the Codespaces environment at instantiation time
#

# Allow docker socket access without sudo
sudo chmod 666 /var/run/docker.sock

log "Post-create setup complete."

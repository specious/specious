FROM debian:bookworm-slim

#
# Shell enhancements, docker-compose, kubernetes, bun as js runtime
#

ARG USERNAME=me
ARG USER_UID=1000
ARG USER_GID=1000
ARG IMAGE_VERSION=devcontainer-base
ARG DOTFILES_REPO=https://github.com/specious/dotfiles
ARG DOTFILES_REF=master
ARG BENDER_REPO=https://github.com/specious/bender
ARG BASH_PROMPT_URL=https://gist.githubusercontent.com/specious/8244801/raw

ENV HOME=/home/${USERNAME} USER=${USERNAME}

LABEL org.opencontainers.image.title="Minimal devcontainer with docker compose & kubernetes"
LABEL org.opencontainers.image.version=${IMAGE_VERSION}
LABEL org.opencontainers.image.authors="Ildar Sagdejev"
LABEL org.opencontainers.image.source="https://github.com/specious/specious/tree/main/.devcontainer"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Base packages and tools
RUN set -eux; \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    curl wget file git gnupg lsb-release ca-certificates \
    zsh bash sudo tmux htop gpg tree tig jq unzip zip less procps \
    iproute2 iputils-ping dnsutils psmisc lsof silversearcher-ag && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN set -eux; \
  groupadd --gid ${USER_GID} ${USERNAME} && \
  useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/zsh ${USERNAME} && \
  echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
  chmod 0440 /etc/sudoers.d/${USERNAME}

# Install the latest neovim
RUN set -eux; \
  curl -fsSLO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz && \
  tar -xzf nvim-linux-x86_64.tar.gz -C /usr/local --strip-components=1 && \
  rm nvim-linux-x86_64.tar.gz && \
  nvim --version

# Install Docker CLI and Compose plugin
RUN set -eux; \
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" \
    > /etc/apt/sources.list.d/docker.list && \
  apt-get update && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (apt repo)
RUN set -eux; \
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list && \
  apt-get update && apt-get install -y --no-install-recommends gh && \
  rm -rf /var/lib/apt/lists/* && \
  gh --version

# Install bun (latest)
RUN set -eux; \
  curl -fsSL "https://bun.sh/install" | BUN_INSTALL="/usr/local" bash && \
  bun --version

# Install yq latest (official release binary)
RUN set -eux; \
  curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" && \
  chmod +x /usr/local/bin/yq && \
  yq --version

# Install dive latest (official release binary)
RUN set -eux; \
  DIVE_TAG="$(curl -fsSL https://api.github.com/repos/wagoodman/dive/releases/latest | jq -r .tag_name)" && \
  curl -fsSL "https://github.com/wagoodman/dive/releases/download/${DIVE_TAG}/dive_${DIVE_TAG#v}_linux_amd64.tar.gz" -o /tmp/dive.tar.gz && \
  tar -xzf /tmp/dive.tar.gz -C /tmp && \
  install -m 0755 /tmp/dive /usr/local/bin/dive && \
  rm -f /tmp/dive /tmp/dive.tar.gz && \
  dive --version

# Install kubectl (official stable release)
RUN set -eux; \
  KUBECTL_URL="https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  curl -fsSLo /usr/local/bin/kubectl "${KUBECTL_URL}" && chmod +x /usr/local/bin/kubectl && \
  kubectl version --client

# Install helm (latest via official installer)
RUN set -eux; \
  curl -fsSLo /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 && \
  chmod +x /tmp/get_helm.sh && /tmp/get_helm.sh && rm /tmp/get_helm.sh && \
  helm version

#
# Bake in shell environment (root-owned files) — runs as root
#
RUN set -eux; \
  TMPDIR="$(mktemp -d)" && \
  trap 'rm -rf "$TMPDIR"' EXIT && \
  \
  git clone --depth=1 --branch "${DOTFILES_REF}" "${DOTFILES_REPO}" "${TMPDIR}/dotfiles" && \
  \
  install -m 0644 "${TMPDIR}/dotfiles/sh-base.sh" /etc/sh-base.sh && \
  install -m 0644 "${TMPDIR}/dotfiles/sh-linux.sh" /etc/sh-linux.sh && \
  touch /etc/sh && chmod 644 /etc/sh && \
  printf '. /etc/sh-base.sh\n' >> /etc/sh && \
  printf '. /etc/sh-linux.sh\n' >> /etc/sh && \
  printf '\n# Local machine configuration\n\n' >> /etc/sh && \
  printf '. "$HOME/.local/share/z/z.sh"\n\n' >> /etc/sh && \
  printf 'export PATH="$HOME/.bun/bin:$PATH"\n' >> /etc/sh && \
  \
  curl -fsSL "${BASH_PROMPT_URL}" -o "${TMPDIR}/bender-bash.sh" && \
  { \
    printf '# bender bash prompt start\n'; \
    cat "${TMPDIR}/bender-bash.sh"; \
    printf '# bender bash prompt end\n'; \
  } >> /etc/bash.bashrc && \
  \
  ln -sf /usr/local/bin/nvim /usr/local/bin/v && \
  ln -sf /usr/local/bin/bun /usr/local/bin/node && \
  \
  mkdir -p /home/${USERNAME}/.local/share && \
  chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}/.local

#
# Bake in dotfiles and user shell environment — runs as user
#
USER ${USERNAME}

RUN set -eux; \
  TMPDIR="$(mktemp -d)" && \
  trap 'rm -rf "$TMPDIR"' EXIT && \
  \
  git clone --depth=1 --branch "${DOTFILES_REF}" "${DOTFILES_REPO}" "${TMPDIR}/dotfiles" && \
  \
  install -m 0644 "${TMPDIR}/dotfiles/vimrc"     "${HOME}/.vimrc" && \
  install -m 0644 "${TMPDIR}/dotfiles/tmux.conf" "${HOME}/.tmux.conf" && \
  install -m 0644 "${TMPDIR}/dotfiles/tigrc"     "${HOME}/.tigrc" && \
  \
  mkdir -p "${HOME}/.config/nvim" && \
  ln -sf "${HOME}/.vimrc" "${HOME}/.config/nvim/init.vim" && \
  \
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${HOME}/.oh-my-zsh" && \
  cp "${HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${HOME}/.zshrc" && \
  \
  git clone --depth=1 "${BENDER_REPO}" "${TMPDIR}/bender" && \
  mkdir -p "${HOME}/.oh-my-zsh/custom/themes" && \
  install -m 0644 "${TMPDIR}/bender/bender.zsh-theme" "${HOME}/.oh-my-zsh/custom/themes/bender.zsh-theme" && \
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="bender"/' "${HOME}/.zshrc" && \
  \
  printf '\nunalias md gg\n' >> "${HOME}/.zshrc" && \
  printf '\n. /etc/sh\n'     >> "${HOME}/.zshrc" && \
  printf '\n. /etc/sh\n'     >> "${HOME}/.bashrc" && \
  \
  git clone --depth=1 https://github.com/rupa/z.git "${HOME}/.local/share/z"

ENV SHELL=/bin/zsh

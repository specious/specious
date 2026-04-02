FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=me
ARG USER_UID=1000
ARG USER_GID=1000
ENV HOME=/home/${USERNAME} USER=${USERNAME}

# Base packages and tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git gnupg lsb-release \
    zsh bash neovim sudo gpg apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --gid ${USER_GID} ${USERNAME} || true && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/zsh ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Ensure zsh is a valid shell
RUN grep -qF '/bin/zsh' /etc/shells || echo '/bin/zsh' >> /etc/shells

# Install docker-ce-cli and docker-compose-plugin from Docker’s repo, as Debian Slim does not provide these packages
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian bookworm stable" \
    > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        docker-ce-cli \
        docker-compose-plugin \
        htop \
        tree \
        tmux \
        wget \
        jq \
        silversearcher-ag \
        python3-pygments && \
    rm -rf /var/lib/apt/lists/*

# Install mikefarah yq (static binary)
RUN mkdir -p /usr/local/bin && \
    YQ_VERSION="$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest \
      | grep -m1 '"tag_name":' | cut -d '"' -f4)" && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
      -o /tmp/yq && \
    install -m 0755 /tmp/yq /usr/local/bin/yq && \
    rm -f /tmp/yq

# Install dive (static binary)
RUN mkdir -p /usr/local/bin && \
    DIVE_VERSION="$(curl -fsSL https://api.github.com/repos/wagoodman/dive/releases/latest \
      | grep -m1 '"tag_name":' | cut -d '"' -f4)" && \
    curl -fsSL "https://github.com/wagoodman/dive/releases/download/${DIVE_VERSION}/dive_${DIVE_VERSION#v}_linux_amd64.tar.gz" \
      -o /tmp/dive.tar.gz && \
    tar -xzf /tmp/dive.tar.gz -C /tmp && \
    install -m 0755 /tmp/dive /usr/local/bin/dive && \
    rm -f /tmp/dive /tmp/dive.tar.gz

# Install kubectl (official binary)
RUN mkdir -p /usr/local/bin && \
    curl -fsSLo /tmp/kubectl \
      "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -m 0755 /tmp/kubectl /usr/local/bin/kubectl && \
    rm -f /tmp/kubectl

# Ensure ownership of home is correct (in case of later COPYs)
RUN chown -R ${USER_UID}:${USER_GID} ${HOME}

USER ${USERNAME}
ENV SHELL=/bin/zsh
SHELL ["/bin/zsh", "-c"]

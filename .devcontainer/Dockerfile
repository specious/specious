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
        docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# Install kubectl (official binary)
RUN curl -fsSLo /usr/local/bin/kubectl \
      https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Ensure ownership of home is correct (in case of later COPYs)
RUN chown -R ${USER_UID}:${USER_GID} ${HOME}

USER ${USERNAME}
ENV SHELL=/bin/zsh
SHELL ["/bin/zsh", "-c"]

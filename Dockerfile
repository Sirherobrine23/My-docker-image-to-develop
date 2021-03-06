# Build dive
FROM golang
WORKDIR /build
RUN git clone https://github.com/wagoodman/dive --depth=1 dive && cd dive && go build -o /dive.bin .

# Build (PHP) compose
FROM php
WORKDIR /build
RUN curl -sS https://getcomposer.org/installer | php

# Final Image
FROM debian:latest
# Install Basic packages
ARG DEBIAN_FRONTEND="noninteractive"
ARG EXTRA_PACKAGE=""
RUN apt update && apt install -y software-properties-common cmake make build-essential git curl wget sudo procps zsh tar screen ca-certificates procps lsb-release gnupg gnupg2 gpg $EXTRA_PACKAGE

# Nodejs
RUN wget -qO- https://raw.githubusercontent.com/Sirherobrine23/DebianNodejsFiles/main/debianInstall.sh | bash

# PHP and compose
COPY --from=1 /build/composer.phar /usr/share/composer/composer.phar
RUN apt update && apt install -y php && echo "php /usr/share/composer/composer.phar \"\$@\"" > /usr/local/bin/composer && chmod +x /usr/local/bin/composer

# Terraform
# RUN wget -qO- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/hashicorp.gpg  >/dev/null && \
#   apt-add-repository "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
#   apt update && sudo apt install -y terraform

# Docker, Docker Compose, minikube, kubectl, act, dive
VOLUME [ "/var/lib/docker" ]
RUN wget -qO- https://get.docker.com | sh && \
  wget -q $(wget -qO- https://api.github.com/repos/docker/compose/releases/latest | grep 'browser_download_url' | grep -v '.sha' | cut -d '"' -f 4 | grep linux | grep $(uname -m) | head -n 1) -O /usr/local/bin/docker-compose && chmod +x -v /usr/local/bin/docker-compose && \
  # Minikube
  curl -Lo minikube "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-$(dpkg --print-architecture)" && \
  chmod +x minikube && mv minikube /usr/bin && \
  # Install Kubectl
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(dpkg --print-architecture)/kubectl" && \
  chmod +x kubectl && mv kubectl /usr/bin && \
  # Install act (https://github.com/nektos/act)
  wget -qO- https://raw.githubusercontent.com/nektos/act/master/install.sh | bash

# Install dive (https://github.com/wagoodman/dive)
COPY --from=0 /dive.bin /usr/local/bin/dive
RUN chmod a+x /usr/local/bin/dive

# Create docker and minikube start script
ENV MINIKUBE_ARGS="--driver=docker" DOCKERD_ARGS="--experimental"
COPY ./start.sh /usr/local/bin/start.sh
RUN chmod a+x /usr/local/bin/start.sh
ENTRYPOINT [ "/usr/local/bin/start.sh" ]

# Install Github CLI (gh)
RUN (wget -q "$(wget -qO- https://api.github.com/repos/cli/cli/releases/latest | grep 'browser_download_url' | grep '.deb' | cut -d \" -f 4 | grep $(dpkg --print-architecture))" -O /tmp/gh.deb && dpkg -i /tmp/gh.deb && rm /tmp/gh.deb) || echo "Fail Install gh"

# Go (golang)
RUN wget -qO- "https://go.dev/dl/go1.18.3.linux-$(dpkg --print-architecture).tar.gz" | tar -C /usr/local -xzf - && ln -s /usr/local/go/bin/go /usr/bin/go && ln -s /usr/local/go/bin/gofmt /usr/bin/gofmt

# Install httpie
RUN curl -SsL https://packages.httpie.io/deb/KEY.gpg | apt-key add - && curl -SsL -o /etc/apt/sources.list.d/httpie.list https://packages.httpie.io/deb/httpie.list && apt update && apt install -y httpie

# Install node apps
RUN npm i -g ts-node typescript autocannon

# Add non root user and Install oh my zsh
# ARG USERNAME="devcontainer" USER_UID="1000" USER_GID=$USER_UID
# RUN groupadd --gid $USER_GID $USERNAME && adduser --disabled-password --gecos "" --shell /usr/bin/zsh --uid $USER_UID --gid $USER_GID $USERNAME && usermod -aG sudo $USERNAME && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && chmod 0440 /etc/sudoers.d/$USERNAME && usermod -aG docker $USERNAME
# USER $USERNAME
# WORKDIR /home/$USERNAME
# RUN yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && \
#   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
#   git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
#   sed -e 's|ZSH_THEME=".*"|ZSH_THEME="strug"|g' -i ~/.zshrc && \
#   sed -e 's|plugins=(.*)|plugins=(git docker kubectl zsh-syntax-highlighting zsh-autosuggestions)|g' -i ~/.zshrc

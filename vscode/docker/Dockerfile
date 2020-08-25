FROM ubuntu:18.04

RUN apt-get update && apt-get install -y \
    openssl \
    net-tools \
    git \
    locales \
    sudo \
    dumb-init \
    vim \
    curl \
    wget \
    bash-completion \
    python3.7 \
    python3-pip

RUN python3.7 -m pip install --upgrade \
    pip \
    jupyter \
    pylint

RUN chsh -s /bin/bash
ENV SHELL=/bin/bash

RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

RUN ARCH=amd64 && \
    curl -sSL "https://github.com/boxboat/fixuid/releases/download/v0.4.1/fixuid-0.4.1-linux-$ARCH.tar.gz" | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: iguazio\ngroup: iguazio\n" > /etc/fixuid/config.yml

RUN CODE_SERVER_VERSION=3.4.1 && \
    curl -sSOL https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_amd64.deb && \
    sudo dpkg -i code-server_${CODE_SERVER_VERSION}_amd64.deb

RUN locale-gen en_US.UTF-8
# We unfortunately cannot use update-locale because docker will not use the env variables
# configured in /etc/default/locale so we need to set it manually.
ENV LC_ALL=en_US.UTF-8

## User account
RUN adduser --disabled-password --gecos '' iguazio && \
    adduser iguazio sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;

RUN chmod g+rw /home && \
    mkdir -p /home/iguazio/workspace && \
    mkdir -p /home/iguazio/project && \
    chown -R iguazio:iguazio /home/iguazio 

RUN mkdir -p /igz/java && \
    chown -R iguazio:iguazio /igz/java

RUN chown -R iguazio:iguazio /home/iguazio/workspace

# Generate an explicit kube config, since vscode extension needs it
COPY kube_config /home/iguazio/.kube/config
RUN chown -R iguazio:iguazio /home/iguazio/.kube

USER iguazio

# Need to use an older version of the extension since 2020.6* versions have a bug making it unusable in our case.
# Will need to revisit once the 2020.7 version is available.
RUN /usr/bin/code-server \
	--install-extension ms-python.python@2020.5.86806 \
	--install-extension coenraads.bracket-pair-colorizer-2 \
	--install-extension oderwat.indent-rainbow \
	--install-extension yzhang.markdown-all-in-one \
	--install-extension njpwerner.autodocstring \
	--install-extension ms-kubernetes-tools.vscode-kubernetes-tools


RUN echo 'export PS1="\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /home/iguazio/.bashrc

WORKDIR /User

EXPOSE 8080

ENTRYPOINT ["dumb-init", "/usr/bin/code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none", "."]

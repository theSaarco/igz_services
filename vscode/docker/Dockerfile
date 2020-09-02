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

## User account
RUN adduser --disabled-password --gecos '' iguazio && \
    adduser iguazio sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;

# Install miniconda
ARG MINICONDA_VERSION="4.8.3"
ARG MINICONDA_BIN="Miniconda3-latest-Linux-x86_64.sh"
ARG DEB_REPO='deb http://artifactory.iguazeng.com:8081/artifactory/ubuntu_deb'

ENV CONDA_HOME "/conda"
ENV PATH=$CONDA_HOME/bin:$PATH
ENV XDG_CACHE_HOME ${HOME}/.cache/

RUN set -ex && \
    wget --quiet https://repo.anaconda.com/miniconda/${MINICONDA_BIN} && \
    /bin/bash ${MINICONDA_BIN} -f -b -p $CONDA_HOME && \
    rm ${MINICONDA_BIN} && \
    $CONDA_HOME/bin/conda config --system --set auto_update_conda false && \
    $CONDA_HOME/bin/conda config --system --set show_channel_urls true && \
    $CONDA_HOME/bin/conda config --system --set allow_conda_downgrades true && \
    $CONDA_HOME/bin/conda config --system --set notify_outdated_conda false && \
    $CONDA_HOME/bin/conda install --quiet --yes conda=="${MINICONDA_VERSION}" python=="3.7" pip=="18.1" && \
    mkdir /etc/ipython && \
    { \
      echo 'c = get_config()'; \
      echo "c.Application.log_datefmt = '%Y-%m-%d %H:%M:%S'" ; \
      echo "c.NotebookApp.terminado_settings={'shell_command': ['bash']}" ; \
    } > /etc/ipython/ipython_config.py && \
    chown -R iguazio:iguazio $CONDA_HOME

RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

RUN ARCH=amd64 && \
    curl -sSL "https://github.com/boxboat/fixuid/releases/download/v0.4.1/fixuid-0.4.1-linux-$ARCH.tar.gz" | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: iguazio\ngroup: iguazio\n" > /etc/fixuid/config.yml

RUN CODE_SERVER_VERSION=3.5.0 && \
    curl -sSOL https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_amd64.deb && \
    sudo dpkg -i code-server_${CODE_SERVER_VERSION}_amd64.deb

RUN locale-gen en_US.UTF-8
# We unfortunately cannot use update-locale because docker will not use the env variables
# configured in /etc/default/locale so we need to set it manually.
ENV LC_ALL=en_US.UTF-8

RUN chmod g+rw /home && \
    mkdir -p /home/iguazio/workspace && \
    mkdir -p /home/iguazio/project && \
    chown -R iguazio:iguazio /home/iguazio 

RUN mkdir -p /igz/java && \
    chown -R iguazio:iguazio /igz/java

COPY bash-it.sh /igz/ 
RUN chown iguazio:iguazio /igz/bash-it.sh

RUN chown -R iguazio:iguazio /home/iguazio/workspace

# Generate an explicit kube config, since vscode extension needs it
COPY kube_config /home/iguazio/.kube/config
RUN chown -R iguazio:iguazio /home/iguazio/.kube

USER iguazio

RUN conda install -c anaconda --quiet --yes \
    'tini==0.18.0' \
    'beautifulsoup4==4.8.2' \
    'bokeh==2.0.2' \
    'cython==0.29.13' \
    'ipywidgets==7.5.1' \
    'dill==0.3.1.1' \
    'seaborn==0.10.0' \
    'nodejs==10.13.0' \
    'nb_conda==2.2.1' \
    'xlrd==1.2.0' \
    'conda-forge::nbgitpuller==0.8.0' && \
    conda list tini | grep tini | tr -s ' ' | cut -d ' ' -f 1,2 >> $CONDA_HOME/conda-meta/pinned && \
    conda remove --quiet --yes --force qt pyqt && \
    conda clean -tipsy

RUN /usr/bin/code-server \
	--install-extension ms-python.python \
	--install-extension coenraads.bracket-pair-colorizer-2 \
	--install-extension oderwat.indent-rainbow \
	--install-extension yzhang.markdown-all-in-one \
	--install-extension njpwerner.autodocstring \
	--install-extension ms-kubernetes-tools.vscode-kubernetes-tools


RUN echo 'export PS1="\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /home/iguazio/.bashrc

WORKDIR /User

EXPOSE 8080

ENTRYPOINT ["dumb-init", "/usr/bin/code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none", "."]

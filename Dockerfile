# ================================================
# DOCKERFILE =====================================
# ================================================
FROM ufoym/deepo:all-jupyter

# ------------------------------------------------
# ENV --------------------------------------------
# ------------------------------------------------

# Reset this at bottom of file.
# https://github.com/phusion/baseimage-docker/issues/319#issuecomment-272568689
ENV DEBIAN_FRONTEND noninteractive

# ------------------------------------------------
# COPY->SCRIPTS ----------------------------------
# ------------------------------------------------
COPY ./docker/scripts/ /root/.scripts

# ------------------------------------------------
# APT --------------------------------------------
# ------------------------------------------------
RUN apt-get update && \
      apt-get install -y --no-install-recommends \
        curl \
        g++

# ------------------------------------------------
# NODE -------------------------------------------
# ------------------------------------------------
RUN curl -sL https://deb.nodesource.com/setup_9.x | bash - && \
      apt-get install -y --no-install-recommends \
        nodejs

# ------------------------------------------------
# PIP --------------------------------------------
# ------------------------------------------------

# Upgrade
# ------------------------------------------------
# FIX: Should we stick to a specific version instead of upgrading blindly?
RUN pip --no-cache-dir install --upgrade pip

# Install packages
# ------------------------------------------------
RUN PIP_INSTALL="pip --no-cache-dir install --upgrade" && \
    $PIP_INSTALL \
      notebook \
      jupyterlab
      #mxnet-cu90 # This needs to be upgraded for graphviz

# ------------------------------------------------
# CONFIG->IMAGE ----------------------------------
# ------------------------------------------------

# Copy Jupyter/JupyterLab settings
COPY ./docker/jupyter /root/.jupyter/

# ------------------------------------------------
# CUDA -------------------------------------------
# ------------------------------------------------
RUN pip install --upgrade tensorflow-gpu

# Downgrade cudnn
# ------------------------------------------------
# FIX: This is a hack for current issue with tensorflow-gpu
# RUN apt-get purge -y libcudnn7 libcudnn7-dev

## Install libcudnn and libcudnn-dev
# RUN curl "http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7_7.0.5.15-1+cuda9.1_amd64.deb" > /tmp/libcudnn7_7.0.5.15-1+cuda9.1_amd64.deb && \
#       dpkg -i /tmp/libcudnn7_7.0.5.15-1+cuda9.1_amd64.deb && \
#       curl "http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7-dev_7.0.5.15-1+cuda9.1_amd64.deb" > /tmp/libcudnn7-dev_7.0.5.15-1+cuda9.1_amd64.deb && \
#       dpkg -i /tmp/libcudnn7-dev_7.0.5.15-1+cuda9.1_amd64.deb && \
#       rm -f /tmp/libcudnn7*.deb

# RUN mkdir /nvidia

# COPY ./docker/nvidia/libcudnn7_7.0.5.15-1+cuda9.1_amd64.deb /nvidia
# COPY ./docker/nvidia/libcudnn7-dev_7.0.5.15-1+cuda9.1_amd64.deb /nvidia

# RUN dpkg -i /nvidia/libcudnn7_7.0.5.15-1+cuda9.1_amd64.deb
# RUN dpkg -i /nvidia/libcudnn7-dev_7.0.5.15-1+cuda9.1_amd64.deb

# ------------------------------------------------
# MINICONDA --------------------------------------
# ------------------------------------------------
# FROM: https://hub.docker.com/r/conda/miniconda3/~/dockerfile/
RUN apt-get -qq update && apt-get -qq -y install curl bzip2 \
      && curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
      && bash /tmp/miniconda.sh -bfp /usr/local \
      && rm -rf /tmp/miniconda.sh \
      && conda install -y python=3 \
      && conda update conda \
      && apt-get -qq -y remove curl bzip2 \
      && apt-get -qq -y autoremove \
      && apt-get autoclean \
      && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
      && conda clean --all --yes

ENV PATH /opt/conda/bin:$PATH

# ------------------------------------------------
# CONFIG->INSTALLS -------------------------------
# ------------------------------------------------
COPY ./config/ /root/.config-image/

# Core (in dldc repo)
# ------------------------------------------------

# Run individually to preserve cache for each
RUN python /root/.scripts/install_from_config.py core apt
RUN python /root/.scripts/install_from_config.py core jupyter
RUN python /root/.scripts/install_from_config.py core jupyterlab
RUN python /root/.scripts/install_from_config.py core lua
RUN python /root/.scripts/install_from_config.py core pip

# User (Ignored in dldc repo - user configured)
# ------------------------------------------------
# NOTE: Except pip. That will be last for caching purposes. JupyterLab extensions are slow.

# Run individually to preserve cache for each
RUN python /root/.scripts/install_from_config.py user apt
RUN python /root/.scripts/install_from_config.py user jupyter
RUN python /root/.scripts/install_from_config.py user jupyterlab
RUN python /root/.scripts/install_from_config.py user lua

# Download models
# ------------------------------------------------
# SEE: https://github.com/pytorch/text#installation
# RUN python -m spacy download en
# RUN python -m nltk.downloader perluniprops nonbreaking_prefixes

# User -> pip
# ------------------------------------------------
RUN python /root/.scripts/install_from_config.py user pip

# ------------------------------------------------
# ENV->RESET -------------------------------------
# ------------------------------------------------
ENV DEBIAN_FRONTEND teletype

# ------------------------------------------------
# WORKDIR ----------------------------------------
# ------------------------------------------------
WORKDIR /root

# docker build -t vini8cs/virsorter2:1.0 .
FROM mambaorg/micromamba:ubuntu22.04

USER root

ENV MAMBA_DOCKERFILE_ACTIVATE=1 \
    MAMBA_ROOT_PREFIX=/opt/conda

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    git \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libmagic-dev \
    libcurl4-openssl-dev \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN micromamba clean --all \
    && micromamba install -c conda-forge -c bioconda -y -n base virsorter=2.2.4 \
    && micromamba install -y -n base pip=25.0 \
    && pip install glob2==0.7  \
    && pip install screed==1.1.3 \
    && micromamba env export --name base > environment.lock \
    && echo ">> CONDA_LOCK_START" \
    && cat environment.lock \
    && echo "<< CONDA_LOCK_END" \
    && micromamba clean -a -y

ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"

RUN ln -s /opt/conda/bin/curl /usr/bin/curl

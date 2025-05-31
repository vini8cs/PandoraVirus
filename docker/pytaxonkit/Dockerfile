# docker build -t vini8cs/pytaxonkit:1.3 .
FROM mambaorg/micromamba:ubuntu22.04

USER root

ENV MAMBA_DOCKERFILE_ACTIVATE=1 \
    DEBIAN_FRONTEND=noninteractive \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
RUN micromamba clean --all \
    && micromamba install -y -n base pip=25.0 \
    && micromamba install -y -n base bioconda::pytaxonkit=0.8 \
    && pip install pandas==2.2.3 pandarallel==1.6.5 \
    && micromamba env export --name base > environment.lock \
    && echo ">> CONDA_LOCK_START" \
    && cat environment.lock \
    && echo "<< CONDA_LOCK_END" \
    && micromamba clean -a -y

ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"

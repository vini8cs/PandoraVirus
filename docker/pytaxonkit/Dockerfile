# docker build -t pandoravirus/pytaxonkit:1.0 .
FROM condaforge/mambaforge:latest

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

RUN mamba clean --all \
    && pip install pandas==2.2.3 \
    && mamba install -y -n base bioconda::pytaxonkit=0.8 \
    && mamba env export --name base > environment.lock \
    && echo ">> CONDA_LOCK_START" \
    && cat environment.lock \
    && echo "<< CONDA_LOCK_END" \
    && mamba clean -a -y

USER root
ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"

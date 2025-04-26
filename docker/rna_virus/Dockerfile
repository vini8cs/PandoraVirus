# docker build -t vini8cs/rna_virus:1.0 .
FROM mambaorg/micromamba:2-alpine3.20

USER root

ENV MAMBA_DOCKERFILE_ACTIVATE=1 \
    MAMBA_ROOT_PREFIX=/opt/conda

RUN apk update && apk add --no-cache \
    build-base \
    wget \
    git \
    zlib-dev \
    bzip2-dev \
    xz-dev \
    file-dev \
    libcurl \
    util-linux

RUN micromamba clean --all \
    && micromamba install -y -n base pip=25.0 \
    && pip install pandas==2.2.3 openpyxl==3.1.5  \
    && micromamba env export --name base > environment.lock \
    && echo ">> CONDA_LOCK_START" \
    && cat environment.lock \
    && echo "<< CONDA_LOCK_END" \
    && micromamba clean -a -y

ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"

RUN ln -s /opt/conda/bin/curl /usr/bin/curl

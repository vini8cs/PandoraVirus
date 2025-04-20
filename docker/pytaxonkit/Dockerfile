# docker build -t vini8cs/pytaxonkit:1.3 .
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
    && micromamba install -y -n base bioconda::pytaxonkit=0.8 \
    && pip install pandas==2.2.3 pandarallel==1.6.5 \
    && micromamba env export --name base > environment.lock \
    && echo ">> CONDA_LOCK_START" \
    && cat environment.lock \
    && echo "<< CONDA_LOCK_END" \
    && micromamba clean -a -y

ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"

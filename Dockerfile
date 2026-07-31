FROM pytorch/pytorch:2.13.0-cuda13.2-cudnn9-runtime AS base

ENV PIP_BREAK_SYSTEM_PACKAGES=1
ARG DEBIAN_FRONTEND=noninteractive

# Install system dependencies & clean apt cache to keep image size small
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    tini \
    wget \
    libsndfile1-dev \
    tesseract-ocr \
    espeak-ng \
    ffmpeg \
    zstd \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m pip install --upgrade --no-cache-dir pip requests

# Production stage
FROM base AS prod
COPY . /workspace
WORKDIR /workspace
RUN python3 -m pip install --no-cache-dir .

# Test stage (caches test dependencies)
FROM base AS test
COPY pyproject.toml setup.cfg* /workspace/
WORKDIR /workspace
RUN mkdir tuned_lens \
    && python3 -m pip install --no-cache-dir -e ".[test]" \
    && python3 -m pip uninstall -y tuned_lens \
    && rmdir tuned_lens && rm -f pyproject.toml setup.cfg

# Dev stage (caches dev dependencies)
FROM base AS dev
COPY pyproject.toml setup.cfg* /workspace/
WORKDIR /workspace
RUN mkdir tuned_lens \
    && python3 -m pip install --no-cache-dir -e ".[dev]" \
    && python3 -m pip uninstall -y tuned_lens \
    && rmdir tuned_lens && rm -f pyproject.toml setup.cfg


# Example usage:

# Using the production image
# docker build -t tuned-lens-prod --target prod .
# docker run -it tuned-lens-prod

# Using the test image
# docker build -t tuned-lens-test --target test .
# docker run tuned-lens-test -v $PWD:/workspace pytest

# Using the development image
# docker build -t tuned-lens-dev --target dev

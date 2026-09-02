FROM ubuntu:22.04

ARG RUNNER_VERSION="2.300.0"

RUN apt-get update && apt-get install -y \
    curl \
    tar \
    sudo \
    jq \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /actions-runner

RUN curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

ENTRYPOINT ["./run.sh"]

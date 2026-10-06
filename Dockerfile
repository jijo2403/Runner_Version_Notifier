# Use official .NET runtime base image
FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-jammy as build

# Set environment variables to non-interactive to avoid prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Ensure you're running as root
USER root

# Update package lists and install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    lsb-release \
    gnupg2 \
    ca-certificates \
    wget \
    unzip \
    bzip2 \
    libunwind8 \
    gnupg \
    jq \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install yq v4.52.2
RUN wget https://github.com/mikefarah/yq/releases/download/v4.52.2/yq_linux_amd64 -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
    && yq --version

# Install GitHub Actions runner and necessary hooks
WORKDIR /actions-runner
RUN curl -O -L https://github.com/actions/runner/releases/download/v2.337.0/actions-runner-linux-x64-2.336.0.tar.gz \
    && tar xzf actions-runner-linux-x64-2.336.0.tar.gz \
    && rm actions-runner-linux-x64-2.336.0.tar.gz

# Install PowerShell Core 7.x
RUN curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/prod.list -o /etc/apt/sources.list.d/microsoft-prod.list \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc \
    && apt-get update \
    && apt-get install -y powershell

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Azure PowerShell Modules
RUN pwsh -Command "Install-Module -Name Az -AllowClobber -Force -SkipPublisherCheck -Scope CurrentUser"

# Install SQLPackage (SQL Server tools)
RUN curl -sSL https://aka.ms/sqlpackage-linux -o sqlpackage.zip \
    && unzip sqlpackage.zip -d /opt/sqlpackage \
    && rm sqlpackage.zip \
    && chmod +x /opt/sqlpackage/sqlpackage \
    && ln -s /opt/sqlpackage/sqlpackage /usr/local/bin/sqlpackage

# Ensure that the runner shuts down after the job finishes by adding a cleanup script
RUN echo '#!/bin/bash' > /actions-runner/cleanup.sh && \
    echo 'echo "Runner finished job, shutting down..."' >> /actions-runner/cleanup.sh && \
    echo 'exit 0' >> /actions-runner/cleanup.sh && \
    chmod +x /actions-runner/cleanup.sh

# Set RUNNER_ALLOW_RUNASROOT to true
ENV RUNNER_ALLOW_RUNASROOT=true

# Define entrypoint for running actions runner and verifying installation
CMD /bin/bash -c "/actions-runner/run.sh && /actions-runner/cleanup.sh"

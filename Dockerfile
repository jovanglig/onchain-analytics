# Use an official Python image as the base
FROM python:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up a non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update && apt-get install -y sudo \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set the working directory
WORKDIR /workspace

# Switch to the non-root user
USER $USERNAME

# Install Python dependencies
COPY requirements.txt /workspace/
RUN pip install --no-cache-dir -r requirements.txt

# Install Marp CLI globally using npm (in user space)
RUN npm install -g @marp-team/marp-cli --prefix /home/vscode/.npm-global \
    && echo 'export PATH=/home/vscode/.npm-global/bin:$PATH' >> /home/vscode/.bashrc

# Switch to root user to install Chromium browser
USER root
RUN apt-get update && apt-get install -y chromium && apt-get clean && rm -rf /var/lib/apt/lists/*

# Switch back to the non-root user
USER $USERNAME

# Set the default shell to bash
SHELL ["/bin/bash", "-c"]
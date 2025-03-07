# Use the latest slim version of Debian
FROM debian:bookworm-slim

# Check if the argument is provided, else throw an error
ARG BRANCH
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN if [ -z "$BRANCH" ]; then echo "ERROR: BRANCH is not set!" >&2; exit 1; fi
ENV BRANCH=$BRANCH

# Copy contents of the project to /a0
COPY fs/ /a0/fs/

# Create /a0 if missing and set permissions
RUN mkdir -p /a0 && \
    groupadd -g ${GROUP_ID} agent && \
    useradd -u ${USER_ID} -g ${GROUP_ID} -d /home/agent -m agent && \
    mkdir -p /home/agent/.ssh && \
    chmod 700 /home/agent/.ssh && \
    chown -R agent:agent /a0 /exe /home/agent/.ssh && \
    find /a0 -type d -exec chmod 2775 {} + && \
    find /a0 -type f -exec chmod 0664 {} + && \
    mkdir -p /exe && \
    find /a0 -type f -exec chmod 0664 {} +

# pre installation steps
RUN bash /a0/fs/ins/pre_install.sh $BRANCH

# install additional software
RUN bash /a0/fs/ins/install_additional.sh $BRANCH

# install A0
RUN bash /a0/fs/ins/install_A0.sh $BRANCH

# cleanup repo and install A0 without caching, this speeds up builds
ARG CACHE_DATE=none
RUN echo "cache buster $CACHE_DATE" && bash /a0/fs/ins/install_A02.sh $BRANCH

# post installation steps
RUN bash /a0/fs/ins/post_install.sh $BRANCH

# Install gosu, sudo and configure temp directories
RUN apt-get update && apt-get install -y gosu sudo && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /tmp/{pip,pycache,npm} && \
    chmod 1777 /tmp/* && \
    echo "agent ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/agent && \
    chmod 0440 /etc/sudoers.d/agent && \
    chown root:root /etc/sudoers.d/agent

# Expose ports
EXPOSE 22 80

# initialize runtime
CMD ["/bin/bash", "/exe/initialize.sh", "$BRANCH"]

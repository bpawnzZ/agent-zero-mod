#!/bin/bash

# branch from parameter
if [ -z "$1" ]; then
    echo "Error: Branch parameter is empty. Please provide a valid branch name."
    exit 1
fi
BRANCH="$1"

# Set up user environment
mkdir -p /home/agent/{.config,.local/share,.cache,.ssh} /tmp/{pip,pycache,npm}
chown -R agent:agent /home/agent /tmp
chmod 700 /home/agent/.ssh
chmod 600 /home/agent/.ssh/*

# Set proper umask for shared files
umask 0002

# Fix python cache permissions
export PYTHONPYCACHEPREFIX=/tmp/pycache
export PIP_CACHE_DIR=/tmp/pip

# Copy all contents from persistent /per to root directory (/) without overwriting
cp -r --no-preserve=ownership,mode /per/* /

# Start root-required services first
/usr/sbin/sshd -D &
su - searxng -c "bash /exe/run_searxng.sh \"$@\"" &

# Drop privileges and run main process
exec gosu agent:agent bash <<'EOS'
    # Inside user context
    export HOME=/home/agent
    cd /a0
    
    # Configure sudo and run main process
    echo "export SUDO_ASKPASS=/bin/true" >> ~/.bashrc
    exec bash /exe/run_A0.sh "$@"
EOS

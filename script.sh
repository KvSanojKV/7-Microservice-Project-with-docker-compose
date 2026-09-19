#!/usr/bin/env bash

set -e

echo "=========================================="
echo " Ubuntu Microservices Environment Setup"
echo "=========================================="

# ------------------------------------------
# 1. Update system
# ------------------------------------------
echo
echo ">>> Updating apt packages..."
sudo apt update

# ------------------------------------------
# 2. Install required packages
# ------------------------------------------
echo
echo ">>> Installing prerequisites..."

sudo apt install -y \
    docker.io \
    docker-compose-v2 \
    openjdk-21-jdk \
    maven \
    golang-go \
    python3 \
    python3-venv \
    python3-pip \
    ruby-full \
    build-essential \
    libpq-dev \
    php-cli \
    php-pgsql \
    php-curl \
    curl \
    git \
    software-properties-common

# ------------------------------------------
# 3. Configure Docker
# ------------------------------------------
echo
echo ">>> Configuring Docker..."

sudo systemctl enable --now docker 2>/dev/null || true

sudo usermod -aG docker "$USER"

echo "Docker version:"
sudo docker --version

echo "Docker Compose version:"
sudo docker compose version

# ------------------------------------------
# 4. Install NVM
# ------------------------------------------
echo
echo ">>> Installing NVM..."

export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash
fi

# Load NVM into current shell
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
fi

# ------------------------------------------
# 5. Install Node.js 24
# ------------------------------------------
echo
echo ">>> Installing Node.js 24..."

nvm install 24
nvm alias default 24
nvm use 24

# ------------------------------------------
# 6. Install .NET 8 SDK
# ------------------------------------------
echo
echo ">>> Installing .NET 8 SDK..."

sudo add-apt-repository ppa:dotnet/backports -y

PPA_FILE=$(grep -rl \
    "ppa.launchpadcontent.net/dotnet/backports" \
    /etc/apt/sources.list.d/ 2>/dev/null | head -1 || true)

if [ -n "$PPA_FILE" ]; then
    sudo sed -i '/^Architectures:/d' "$PPA_FILE"
    sudo sed -i '/^Components:/a Architectures: amd64' "$PPA_FILE"
fi

sudo rm -f /var/lib/apt/lists/ppa.launchpadcontent.net_dotnet_backports_ubuntu_dists_resolute_* 2>/dev/null || true

sudo apt update

if apt-cache show dotnet-sdk-8.0 >/dev/null 2>&1; then
    sudo apt install -y dotnet-sdk-8.0
else
    echo
    echo "WARNING: dotnet-sdk-8.0 is not available from the configured repository."
    echo "Please install .NET 8 SDK from Microsoft's Ubuntu repository."
fi

# ------------------------------------------
# ------------------------------------------

# ------------------------------------------
# 8. Verify installations
# ------------------------------------------
echo
echo "=========================================="
echo " Installation Verification"
echo "=========================================="

echo
echo "--- Docker ---"
sudo docker --version
sudo docker compose version

echo
echo "--- Java ---"
java -version

echo
echo "--- Maven ---"
mvn -version

echo
echo "--- Go ---"
go version

echo
echo "--- Python ---"
python3 --version

echo
echo "--- Node.js ---"
node --version

echo
echo "--- NPM ---"
npm --version

echo
echo "--- .NET ---"
if command -v dotnet >/dev/null 2>&1; then
    dotnet --version
else
    echo "NOT INSTALLED"
fi

echo
echo "--- Ruby ---"
ruby --version

echo
echo "--- PHP ---"
php --version

echo

echo
echo "--- Git ---"
git --version

# ------------------------------------------
# 9. Final message
# ------------------------------------------
echo
echo "=========================================="
echo " Setup Completed"
echo "=========================================="

echo
echo "IMPORTANT:"
echo "Docker group membership was added for user: $USER"
echo
echo "Run this command to activate it in the current shell:"
echo
echo "    newgrp docker"
echo
echo "Then verify Docker without sudo:"
echo
echo "    docker run hello-world"
echo
echo "=========================================="

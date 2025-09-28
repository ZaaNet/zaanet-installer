#!/bin/bash
# ZaaNet Bootstrap Installer
set -e

echo "ZaaNet Quick Installer"
echo "Downloading and running ZaaNet installer..."

# Clean up any existing installation
sudo rm -rf zaanet-installer/

# Clone the repository
git clone https://github.com/zaanet/zaanet-installer.git

# Enter directory and run installer
cd zaanet-installer/
sudo chmod +x install.sh
sudo ./install.sh

#!/usr/bin/env bash
set -euo pipefail

echo "Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y unzip curl

echo "Installing Nextflow..."
curl -s https://get.nextflow.io | bash
chmod +x nextflow
sudo mv nextflow /usr/local/bin/

echo "Installing nf-core..."
pip install --upgrade pip
pip install nf-core

echo "Verifying..."
nextflow -version
nf-core --version
#!/bin/bash

# This is a simple bash script to configure monitoring on server
# This script configure fluent-bit, cadvisor, node_exporter

function lastStep(){

    echo "[+] Renaming services binaries"

    mv *node_exporter* node_exporter
    mv *cadvisor* cadvisor
   
    echo "[+] Placing binary inside : /usr/bin/"
    mv cadvisor /usr/bin/.
    mv node_exporter/*node_exporter* /usr/bin/.

    echo "[+] Placing services inside : /etc/systemd/system/."
    mv services/* /etc/systemd/system/

    echo "[+] Going inside fluent-bit directory"
    cd *fluent-bit*
    chmod +x install.sh
    ./install.sh

    cd ..
    echo "[+] cleaning the space"
    rm -rvf monitoring
    echo "[+] cleaning done"

    echo "[+] Restarting services"
    sudo systemctl restart node_exporter.services
    sudo systemctl restart cadvisor.services
}

function createBinServices(){
cd services

echo "[+]Creating cadvisor.service file"

    cat > cadvisor.service << EOF
[Unit]
Description=cAdvisor Container Monitoring Service
Wants=network-online.target
After=network-online.target docker.service containerd.service

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/bin/cadvisor --port=8080
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "[+]Creating node_exporter.service file"

    cat > node_exporter.service << EOF
[Unit]
Description=Node Exporter Monitoring Service
Wants=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/bin/node_exporter 
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cd ..
lastStep
}

function checkBins(){
echo "[+] Installing necessary binaries"

    for bin in wget curl unzip; do
        which $bin
        if [ $? -eq 0 ];then
                echo "[+] $bin Installed "
        else
                apt-get install -y $bin
        fi
    done
}



function getArch(){
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "Unknown arch $ARCH"
            exit
            ;;
        esac
}

function getOs(){
    osName=$(uname -s)
    echo "${osName,,}"
}


function makeUrl(){
    checkBins

    local exporter="${1#v}"
    local cadvisor="${2#v}"
    local fluentbit="${3#v}"

    echo "[+] Going inside monitoring directory"
    cd monitoring

    EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v$exporter/node_exporter-$exporter.$(getOs)-$(getArch).tar.gz"
    CADVISOR_URL="https://github.com/google/cadvisor/releases/download/v$cadvisor/cadvisor-v$cadvisor-$(getOs)-$(getArch)"
    FLUENT_BIT_URL="https://github.com/fluent/fluent-bit/archive/refs/tags/v$fluentbit.zip"

    for url in $EXPORTER_URL $CADVISOR_URL $FLUENT_BIT_URL; do
        wget $url
    done

    echo "[+] Extracting files"
    tar -xvf *tar*
    unzip *zip*

    echo "[+] Removing tar & zip files"
    rm -f *tar* *zip*

    createBinServices

}

function checkPriv(){
    echo "[+] Creating temp directory with name : monitoring"
    mkdir -p monitoring/services

    if [[ $EUID -eq 0 ]]; then
        echo "Running as root"
        makeUrl "$1" "$2" "$3"
    else
        echo "Not a root"
        exit
    fi

   
}

checkPriv "$1" "$2" "$3"

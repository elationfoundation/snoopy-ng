#!/bin/bash
# Basic installation script for Snoopy NG requirements
# glenn@sensepost.com // @glennzw
# Todo: Make this an egg.
set -e


apt_install(){
    local package="${1}"
    local installed=$(dpkg --get-selections \
                               | grep -v deinstall \
                               | grep -E "^${package}\s+install"\
                               | grep -o "${package}")
    if [[ "${installed}" = ""  ]]; then
        echo "Installing ${package} via apt-get"
        apt-get -y install "${package}"
        echo "Installation of ${package} completed."
    else
        echo "${package} already installed. Skipping...."
    fi
}

pip_install(){
    local package="${1}"
    local installed=$(pip list \
                             | grep -E "^${package}\s\([0-9\.]*\)$" \
                             | grep -o "${package}")
    if [[ "${installed}" = ""  ]]; then
        echo "Installing ${package} via python pip"
        pip install "${package}"
        echo "Installation of ${package} completed."
    else
        echo "${package} already installed. Skipping...."
    fi
}

pip_install_url(){
    local package="${1}"
    local url="${2}"
    local installed=$(pip list \
                             | grep -E "^${package}\s\([0-9\.]*\)$" \
                             | grep -o "${package}")
    if [[ "${installed}" = ""  ]]; then
        echo "Installing ${package} via python pip"
        pip install "${url}"
        echo "Installation of ${package} completed."
    else
        echo "${package} already installed. Skipping...."
    fi
}



# In case this is the seconds time user runs setup, remove prior symlinks:
rm -f /usr/bin/sslstrip_snoopy
rm -f /usr/bin/snoopy
rm -f /usr/bin/snoopy_auth
rm -f /etc/transforms


echo "[+] Updating repository..."
apt-get update
apt-get upgrade -y


apt_install "ntpdate"
#if ps aux | grep ntp | grep -qv grep; then
if [ -f /etc/init.d/ntp ]; then
        /etc/init.d/ntp stop
else
        # Needed for Kali Linux build on Raspberry Pi
        apt_install "ntp"
        /etc/init.d/ntp stop
fi

echo "[+] Setting time with ntp"
ntpdate ntp.ubuntu.com
/etc/init.d/ntp start

echo "[+] Setting timzeone..."
echo "Etc/UTC" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
echo "[+] Installing sakis3g..."
cp ./includes/sakis3g /usr/local/bin

# Packages
echo "[+] Installing required packages..."
apt_install "build-essential"
#apt_install "libpcap-dev"
apt_install "python-libpcap"
apt_install "libssl-dev"
apt_install "libffi-dev"
apt_install "python-setuptools"
apt_install "autossh"
apt_install "python-psutil"
apt_install "python2.7-dev"
apt_install "libpcap0.8-dev"
apt_install "ppp"
apt_install "tcpdump"
apt_install "python-serial"
apt_install "sqlite3"
apt_install "python-requests"
apt_install "iw"
apt_install "build-essential"
apt_install "python-bluez"
apt_install "python-flask"
apt_install "python-gps"
apt_install "python-dateutil"
apt_install "python-dev"
apt_install "libxml2-dev"
apt_install "libxslt-dev"
apt_install "pyrit"
apt_install "mitmproxy"

# Python packages

easy_install pip
easy_install smspdu

pip_install "sqlalchemy==0.7.4"
pip uninstall requests -y
pip install -Iv https://pypi.python.org/packages/source/r/requests/requests-0.14.2.tar.gz   #Wigle API built on old version
pip_install "httplib2"
pip_install "BeautifulSoup"
pip_install "publicsuffix"
#pip install mitmproxy
pip_install "pyinotify"
pip_install "netifaces"
pip_install "dnslib"

#Install SP sslstrip
cp -r ./setup/sslstripSnoopy/ /usr/share/
ln -s /usr/share/sslstripSnoopy/sslstrip.py /usr/bin/sslstrip_snoopy

# Download & Installs
echo "[+] Installing pyserial 2.6"
pip install https://pypi.python.org/packages/source/p/pyserial/pyserial-2.6.tar.gz
pip_install_url "pyserial" "https://pypi.python.org/packages/source/p/pyserial/pyserial-2.6.tar.gz"
echo "[+] Downloading pylibpcap..."
pip_install_url "pylibpcap"  "https://sourceforge.net/projects/pylibpcap/files/latest/download?source=files#egg=pylibpcap"

echo "[+] Downloading dpkt..."
pip_install_url "dpkt" "https://dpkt.googlecode.com/files/dpkt-1.8.tar.gz"

echo "[+] Installing patched version of scapy..."
pip install ./setup/scapy-latest-snoopy_patch.tar.gz

# Only run this on your client, not server:
#read -r -p  "[ ] Do you want to download, compile, and install aircrack? [y/n] " response
#if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
#then
#    echo "[+] Downloading aircrack-ng..."
#    wget http://download.aircrack-ng.org/aircrack-ng-1.2-beta1.tar.gz
#    tar xzf aircrack-ng-1.2-beta1.tar.gz
#    cd aircrack-ng-1.2-beta1
#    make
#    echo "[-] Installing aircrack-ng"
#    make install
#    cd ..
#    rm -rf aircrack-ng-1.2-beta1*
#fi

echo "[+] Creating symlinks to this folder for snoopy.py."

echo "sqlite:///`pwd`/snoopy.db" > ./transforms/db_path.conf

ln -s `pwd`/transforms /etc/transforms
ln -s `pwd`/snoopy.py /usr/bin/snoopy
ln -s `pwd`/includes/auth_handler.py /usr/bin/snoopy_auth
chmod +x /usr/bin/snoopy
chmod +x /usr/bin/snoopy_auth
chmod +x /usr/bin/sslstrip_snoopy

echo "[+] Done. Try run 'snoopy' or 'snoopy_auth'"
echo "[I] Ensure you set your ./transforms/db_path.conf path correctly when using Maltego"

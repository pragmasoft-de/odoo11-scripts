#!/bin/bash

# Script to install odoo 11 on Ubuntu Server 16.04 LTS.
# (c) Josef Kaser 2016 - 2017
# http://www.pragmasoft.de
#
# odoo will be listening on port 8069 on the external IP

# variables

# username and password for the OS user odoo
ODOO_USER_NAME=odoo
ODOO_USER_PWD='odoo'

# username and password the the OS user postgres
PG_USER_NAME=postgres
PG_USER_PWD='postgres'

# username and password for the DB user odoo
PG_ROLE_ODOO_NAME=odoo
PG_ROLE_ODOO_PWD='odoo'

# master password for odoo (for managing the databases)
ODOO_ADMIN_PASSWD='$ecr3t'

# needed later in the script to go back to the script directory
START_DIR=$PWD

# IP address the odoo service listens to
INTERFACE_IP=`hostname -I | awk '{print $1}'`

# here we go ;-)

# script must be run as root
if [ $USER != "root" ]; then
	echo "Script must be run as root"
	exit
fi

# set timezone
echo "Etc/UTC" > /etc/timezone

# upgrade OS
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y

# remove all Python 2.7 packages
apt-get remove python2.7* -y

# install required Ubuntu packages
apt-get install gcc unzip libxslt1.1 libxslt1-dev libldap2-dev libsasl2-dev poppler-utils xfonts-base xfonts-75dpi xfonts-utils libxfont1 xfonts-encodings xzip xz-utils npm nodejs node-less node-clean-css git mcrypt keychain software-properties-common libjpeg-dev libfreetype6-dev zlib1g-dev libpng12-dev -y

# install required Python packages
apt-get install python3.5 python3-dev python-pychart python3-gnupg python3-pil python-zsi python3-ldap3 python3-lxml python3-dateutil python3-pip python3-openpyxl python3-xlrd python3-decorator python3-requests python3-pypdf2 python3-gevent python3-passlib -y

# install PostgreSQL
apt-get install postgresql postgresql-client postgresql-client-common postgresql-contrib postgresql-server-dev-all -y

# create database user "odoo"
/usr/bin/sudo -u $PG_USER_NAME ./create_pg_role.sh $PG_ROLE_ODOO_NAME $PG_ROLE_ODOO_PWD

# install required Python modules
pip3 install --upgrade pip
pip3 install BeautifulSoup BeautifulSoup4 passlib pillow dateutils polib unidecode flanker simplejson enum py4j phonenumbers

# install Node.js
npm install -g npm
npm install -g less-plugin-clean-css
npm install -g less

ln -s /usr/bin/nodejs /usr/bin/node
rm /usr/bin/lessc
ln -s /usr/local/bin/lessc /usr/bin/lessc

# cerate odoo11.conf from template and set some parameters
if [ -f odoo11.conf ]
	then rm odoo11.conf
fi

cp odoo11.conf.template odoo11.conf
sed -i s/{{admin_passwd}}/$ODOO_ADMIN_PASSWD/ odoo11.conf
sed -i s/{{db_password}}/$PG_ROLE_ODOO_PWD/ odoo11.conf
sed -i s/{{db_user}}/$PG_ROLE_ODOO_NAME/ odoo11.conf
sed -i s/{{interface_ip}}/$INTERFACE_IP/ odoo11.conf

# copy odoo11.conf to /etc/odoo
cd /etc
mkdir odoo
cd odoo
cp $START_DIR/odoo11.conf .

# install wkhtmltopdf
cd /tmp
mkdir wkhtmltopdf
cd wkhtmltopdf
wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
unxz wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
tar xvf wkhtmltox-0.12.4_linux-generic-amd64.tar
cd wkhtmltox/bin
cp * /usr/local/bin/
cd /usr/bin
ln -s /usr/local/bin/wkhtmltopdf ./wkhtmltopdf
cd /tmp
rm -rf wkhtmltopdf

# create OS user "odoo" and set password
useradd -m -U $ODOO_USER_NAME
echo "$ODOO_USER_NAME:$ODOO_USER_PWD" | chpasswd

# set password for OS user "postgres"
echo "$PG_USER_NAME:$PG_USER_PWD" | chpasswd

# create folder for odoo logfile and set permissions
cd /var/log
mkdir odoo
chown odoo.odoo odoo

# create folder for odoo
cd /opt
mkdir odoo

# get odoo11 from the official Github repository
cd odoo
git clone https://github.com/odoo/odoo --depth 1 -b 11.0
ln -s odoo ./odoo11

# install the required Python modules
cd odoo11
pip3 install -r requirements.txt

# register odoo11 service
cd /etc/systemd/system
cp $START_DIR/odoo11.service .
chmod 644 odoo11.service
systemctl preset odoo11.service

# set shell for the users "odoo" and "postgres" to /bin/false to prevent login
usermod -s /bin/false $ODOO_USER_NAME
usermod -s /bin/false $PG_USER_NAME

# launch odoo11
service odoo11 start


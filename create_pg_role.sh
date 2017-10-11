#!/bin/bash

# Script to create the database user "odoo" and set his permissions.
# The script is being called from install_odoo10_8069.sh.
# (c) Josef Kaser 2017
# http://www.pragmasoft.de

ROLE_ODOO_PWD=$1

cd /var/lib/postgresql

psql <<EOF
    create role odoo with password '$ROLE_ODOO_PWD';
    alter role odoo CREATEROLE;
    alter role odoo CREATEDB;
    alter role odoo CREATEUSER;
    alter role odoo LOGIN;
    \q
EOF


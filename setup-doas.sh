#!/bin/sh

DEFAULT_USER=`grep 1001 /etc/passwd | awk -F: '{ print $1 }'`

touch /usr/local/etc/doas.conf

cat <<EOT >> /usr/local/etc/doas.conf
# Configuration file for doas
# Please see doas.conf manual page for information on setting
# up a doas.conf file.

# Permit $DEFAULT_USER to run programs as root, maintaining
# envrionment variables. Useful for GUI applications.
permit keepenv $DEFAULT_USER as root
EOT

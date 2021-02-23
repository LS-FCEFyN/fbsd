#!/bin/sh

touch /usr/local/etc/doas.conf 

cat <<EOT >> /usr/local/etc/doas.conf
# Configuration file for doas
# Please see doas.conf manual page for information on setting
# up a doas.conf file.

# Permit user lore to run programs as root, maintaining
# envrionment variables. Useful for GUI applications.
permit keepenv lore as root
EOT

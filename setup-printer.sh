#!/bin/sh

FILE=/etc/devfs.rules
DEFAULT_USER=`grep 1001 /etc/passwd | awk -F: '{ print $1 }'`

pw groupmod cups -m $DEFAULT_USER -G cups

if test -f "$FILE"; then
	cat <<EOT >> $FILE 
	[system=10]
	add path 'unlpt*' mode 0660 group cups
	add path 'ulpt*' mode 0660 group cups
	add path 'lpt*' mode 0660 group cups
	add path 'usb/X.Y.Z' mode 0660 group cups 
EOT
else
	touch $FILE
	cat <<EOT >> $FILE 
	[system=10]
	add path 'unlpt*' mode 0660 group cups
	add path 'ulpt*' mode 0660 group cups
	add path 'lpt*' mode 0660 group cups
	add path 'usb/X.Y.Z' mode 0660 group cups 
EOT
fi

echo "devfs_system_ruleset=\"system\"" >> /etc/rc.conf

/etc/rc.d/devfs restart
/usr/local/etc/rc.d/cupsd restart

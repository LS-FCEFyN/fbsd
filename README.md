# FBSD
Slightly modified version of https://github.com//nicholasbernstein/install-fbsd-desktop
plus some extra scripts to configure doas and, hopefully, any HP printer.

Run the scripts as the root :

fetch https://raw.githubusercontent.com/Loretta-Sirerol/fbsd/main/setup.sh -o - | sh

fetch https://raw.githubusercontent.com/Loretta-Sirerol/fbsd/main/setup-doas.sh -o - | sh

fetch https://raw.githubusercontent.com/Loretta-Sirerol/fbsd/main/setup-printer.sh -o - | sh

...or not; Like Nicholas said « You're a grownup. Make your own decisions about how you want to do things. »

Please do notice that while “setup-printer.sh” does handle some things such as adding the default user to the “cups” group;
some manual configuration is needed, namely changing the line: 

« add path 'usb/X.Y.Z' mode 0660 group cups »

In the file found at « /etc/devfs.rules »

X, Y, and Z should be replaced with the target USB device listed in the /dev/usb directory that corresponds to the printer.
To find the correct device, examine the output of « dmesg », where ugenX.Y lists the printer device,
which is a symbolic link to a USB device in /dev/usb.

# Attention

Plasma on wayland session only gives a black screen... further configuration is needed ?

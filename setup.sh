#!/bin/sh
# This script is written mostly if not entirely by Nick Bernstein
# check their script at https://github.com/nicholasbernstein/install-fbsd-desktop
# most of this comes from the freebsd handbook 5.4.1. Quick Start x-config
# I'm only planing to add additional settings for configuring printers "automagically"

date > setup.log

grep -q "kern.vty" /boot/loader.conf || echo "kern.vty=vt" >> /boot/loader.conf

load_atapi() {
	# Access ATAPI devices through the CAM subsystem
	sysrc kld_list+="atapicam"
}

load_fuse() {
	# Filesystems in Userspace
	fuse_pkgs="fuse fuse-utils"
	extra_pkgs="$extra_pkgs fusefs-lkl e2fsprogs"
	sysrc kld_list+="fuse"
}

load_coretemp(){
	# Intel Core thermal sensors
	sysrc kld_list+="coretemp"
}

load_bluetooth() { 
	# most common bluetooth adapters use this
	sysrc kld_list+="ng_ubt"
	sysrc hcsecd_enable="YES"
	sysrc sdpd_enable="YES"
}

enable_ipfw_firewall() {
	# this enables the ipfw firewall with the workstation profile
	# it allows communication w/ other hosts on the network, outgoing traffic
	# and any specific ports (ssh) we choose to enable
	sysrc firewall_type="WORKSTATION"
	sysrc firewall_myservices="22/tcp"
	sysrc firewall_allowservices="any"
	sysrc firewall_enable="YES"
}

enable_tmpfs() {
	# In-memory filesystems
	sysrc kld_list+="tmpfs"
}

enable_async_io() {
	# Asynchronous I/O
	sysrc kld_list+="aio"
}

enable_workstation_pwr_mgmnt() {
	# powerd: hiadaptive speed while on AC power, adaptive while on battery power
	sysrc powerd_enable="YES"
	sysrc powerd_flags="-a hiadaptive -b adaptive"
}

enable_webcam(){
	#this just enables the ability to use webcams
	extra_pkgs="$extra_pkgs cuse4bsd webcamd"
	sysrc kld_list+="cuse4bsd"
	sysrc webcamd_enable="YES"
}

enable_cups(){
	#this just enables the ability to use printers
	extra_pkgs="$extra_pkgs cups"
	sysrc cupsd_enable="YES"
}


# this is mainly just to make sure pkg has been bootstrapped
export ASSUME_ALWAYS_YES=yes
pkg update | tee -a setup.log

# Your user needs to be in the video group to use video acceleration
default_user=`grep 1001 /etc/passwd | awk -F: '{ print $1 }'`
VUSER=`dialog --title "Video User" --clear \
        --inputbox "What user should be added to the video group?" 0 0  $default_user --stdout`

pw groupmod video -m $VUSER && echo "added $VUSER to group: video"
pw groupmod wheel -m $VUSER && echo "added $VUSER to group: wheel" 

# the following creates a .xinitrc file in the user's home directory that will launch
# the installed windowmanager as well as allow the slim display manager to pass it as
# an argument. 
gen_xinit() {
	if [ ! $1 ] ; then 
		echo "argument needed by gen_xinit" 
		return 0 
	else
		xinittxt="#!/bin/sh\n mywm="$1"\n if [ \$1 ] ; then\n \tcase \$1 in \n \t\tdefault) exec \$mywm ;;\n \t\t*) exec \$1 ;;\n \tesac\n else\n \texec \$mywm\n fi"
		echo -e $xinittxt > /home/$VUSER/.xinitrc && chown $VUSER:$VUSER /home/$VUSER/.xinitrc
		echo -e $xinittxt > /etc/skel/.xinitrc
	fi
}


# lets pick our desktop environment. SDDM is going to be used as the login 
# manager instead of slim since it "works out of the box" w/o .xinitrc stuff

set_login_mgr() { 
	if (uname -r | grep "11" >/dev/null) ; then
		mywm="slim"
		slim_extra_pkgs="slim-freebsd-dark-theme"
		pwd_mkdb -p /etc/master.passwd
	else 
		mywm="sddm"
	fi
}

set_login_mgr

desktop=$(dialog --clear --title "Select Desktop" \
        --menu "Select desktop environment to be installed" 0 0 0 \
        "KDE"  "KDE (FBSD 12+ only)" \
	"KDE Minimal"  "Includes the bare minimum plus Dolphin Konsole Kmix" \
        "lxde"  "The lightweight X Desktop ENvironment" \
        "xfce4" "Lightweight XFCE desktop" \
        "windowmaker" "bringing neXt back" \
        "awesome" " a tiling window manager" --stdout)

# for any additional entries, please add a case statement below

case $desktop in
  KDE)
      gen_xinit "startkde"
      DESKTOP_PGKS="kde5 ${mywm}"
      ####################################
      #		Minimal Install 	 #
      ####################################
      DESKTOP_PGKS="plasma5-plasma dolphin konsole kmix ${mywm}" 
      sysrc ${mywm}_enable="YES"
      ;;
  KDE Minimal)
      gen_xinit "startkde"
      DESKTOP_PGKS="plasma5-plasma dolphin konsole kmix ${mywm}" 
      sysrc ${mywm}_enable="YES"
      ;;
  lxde)
      gen_xinit "startlxde"
      DESKTOP_PGKS="lxde-meta lxde-common ${mywm}" 
      sysrc ${mywm}_enable="YES"
      ;;
  xfce4)
      gen_xinit "startxfce4"
      DESKTOP_PGKS="xfce xfce4-goodies ${mywm}" 
      sysrc ${mywm}_enable="YES"
      ;;
  awesome)
      gen_xinit "awesome"
      DESKTOP_PGKS="awesome ${mywm}" 
      sysrc ${mywm}_enable="YES"
      ;;
  *)
     echo "$desktop isn't a valid option."
     ;;
esac

# The following are generally needed by most modern desktops

sysrc dbus_enable="YES"
sysrc hald_enable="YES"

grep "proc /proc procfs" /etc/fstab || echo "proc /proc procfs rw 0 0" >> /etc/fstab
#!/bin/sh

# Additional packages that I may or may not want

extra_pkgs=$(dialog --checklist "Select additional packages to install" 0 0 0 \
firefox "Firefox Web browser" on \
doas "simpler alternative to sudo" on \
mpv "A free, open source, and cross-platform media player" on \
hplip "HP Linux Imaging and Printing" on \
linux_base-c7 "centos v7 linux binary compatiblity layer" off \
git-lite "lightweight git client" off \
libreoffice "open source & nice suite" off \
vlc "Video Player" off \
virtualbox-ose-additions "virtualbox guest additions" off \
--stdout)

# This is a little ugly, but we need to set some sysrc settings
# and dialog is nice to look at, but is kinda clunky

if ( echo $extra_pkgs | grep "linux_base-c7" >/dev/null )    ; 
	then 
		sysrc kld_list+="linux"
		sysrc kld_list+="linux64"
		sysrc linux_enable="YES"

		mkdir -p /compat/linux/proc /compat/linux/dev/shm /compat/linux/sys
		grep "/compat/linux/proc" /etc/fstab 2>/dev/null || \
			echo "linprocfs   /compat/linux/proc  linprocfs rw 0 0" >> /etc/fstab
		grep "/compat/linux/sys" /etc/fstab 2>/dev/null || \
			echo "linsysfs    /compat/linux/sys   linsysfs  rw 0 0" >> /etc/fstab
		grep "/compat/linux/dev" /etc/fstab 2>/dev/null || \
			echo "tmpfs    /compat/linux/dev/shm  tmpfs rw,mode=1777 0 0" >> /etc/fstab
fi

if ( echo $extra_pkgs | grep "virtualbox-ose-additions" >/dev/null )    ; 
	then 
		sysrc vboxguest_enable="YES"
		sysrc vboxservice_enable="YES"
fi

# Honestly, shouldn't graphic card configuration be done in the base installer? 
# Even if X isn't enabled, the right drivers should be selected and installed.
# Lets handle the 4 major cases, and hope for the best

dialog --title "Graphics Drivers" --yesno "Would you like to try to install the drivers for your video card?\n\nPlease refer to freebsd handbook for more details:\nhttps://www.freebsd.org/doc/handbook/x-config.html" 0 0
install_dv_drivers=$?

if [ $install_dv_drivers -eq 0  ] ; then 

	card=$(dialog --checklist "Select additional packages to install" 0 0 0 \
	i915kms "most Intel graphics cards" off \
	radeonkms "most OLDER Radeon graphics cards" off \
	amdgpu "most NEWER AMD graphics cards" off \
	nvidia "NVidia Graphics Cards" off \
	vesa 	"Generic driver that may work as a fallback" off \
	scfb 	"Another Generic diver for UEFI and ARM" off \
	other "Anything but the above" off \
	--stdout)

	case $card in
		i915kms) 
			vc_pkgs="drm-kmod"
			sysrc kld_list+="/boot/modules/i915kms.ko"
			;;
		radeonkms) 
			vc_pkgs="drm-kmod"
			sysrc kld_list+="/boot/modules/radeonkms.ko"
			;;
		amdgpu) 
			vc_pkgs="drm-kmod"
			sysrc kld_list+="amdgpu"
			;;
		nvidia) 
			vc_pkgs="nvidia-driver nvidia-xconfig nvidia-settings"
			nvidia-xconfig
			sysrc kld_list+="nvidia-modeset nvidia"
			;;
		vesa)
			vc_pkgs="xf86-video-vesa"
			;;
		scfb)
			vc_pkgs="xf86-video-scfb"
			;;
		*)
			pciconf=$(pciconf -vl | grep -B3 display)
			dialog --msgbox "You'll need to check the freebsd handbook or forums. The following output may be helpful in finding a driber: pciconf -vl | grep -B3 display: $pciconf" 0 0
			;;
	esac

fi 

# this is referred to during the package install, but needs to be up here so we can ask the user things.
all_pkgs="xorg hal dbus $DESKTOP_PGKS $extra_pkgs $vc_pkgs $slim_extra_pkgs"

# This opt activities
opt_activities=$(dialog --checklist "Select additional options" 0 0 0 \
	load_atapi "enable atapi to enable external storage devices like cds" on \
	load_fuse "enable userspace fileystems" on \
	load_coretemp "enable cpu temp sensors for intel (and amd)" on \
	enable_tmpfs "enable in-mem tempfs" on \
	enable_cups "printing" on \
	enable_webcam "enables webcams to be used" on \
	enable_async_io "enable async io for better perf" on \
	enable_workstation_pwr_mgmnt "change pwr on batter/plugged in" on \
	load_bluetooth "enable bluetooth kernel modules" on \
	--stdout )

#
# this comment is just to draw attention to
# the fact that this line is doing the package installs
# and making it easy to find by having a big comment block
# above it
#
echo "pkg install -y $all_pkgs" | tee -a setup.log
pkg install -y $all_pkgs | tee -a setup.log

# post install stuff
if [ "slim" = $mywm ] ; then
	sed -i '' -E 's/^current_theme.+$/current_theme		slim-freebsd-dark-theme/' /usr/local/etc/slim.conf
fi

# on 11.x w/ mate re-installing fixed a core-dump
if [ $desktop = "mate" ] ; then 
	if ( echo $(uname -r) | grep -q "11" ) ; then 
		pkg install -f gsettings-desktop-schemas
	fi
fi

echo $opt_activities | grep -q load_atapi && load_atapi
echo $opt_activities | grep -q load_fuse && load_fuse
echo $opt_activities | grep -q load_coretemp && load_coretemp
echo $opt_activities | grep -q load_bluetooth && load_bluetooth
echo $opt_activities | grep -q enable_ipfw_firewall && enable_ipfw_firewall
echo $opt_activities | grep -q enable_tmpfs && enable_tmpfs
echo $opt_activities | grep -q enable_async_io && enable_async_io
echo $opt_activities | grep -q enable_workstation_pwr_mgmnt && enable_workstation_pwr_mgmnt
echo $opt_activities | grep -q load_bluetooth && load_bluetooth
echo $opt_activities | grep -q enable_cups && enable_cups
echo $opt_activities | grep -q enable_webcam && enable_webcam

welcome="Thanks for trying this setup script. If you're new to freebsd, it's worth noting that instead of trying to search google for how to do something, you probably want to check the handbook on freebsd.org or read the built-in man pages. Doing a 'man -k <topic>' will search for any matching documentation, and unlike some, ahem, other *nix operating systems, bsd's built in documentation is really good.\n\n"
dialog --msgbox "$welcome Hopefully that worked. You'll probably want to reboot at this point" 0 0


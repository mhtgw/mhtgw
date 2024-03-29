#!/bin/sh
#
# Copyright 1993,1994,1999  Patrick Volkerding, Moorhead, Minnesota USA
# Copyright 2001, 2003, 2004  Slackware Linux, Inc., Concord, CA
# Copyright 2006, 2007  Patrick Volkerding, Sebeka, Minnesota USA
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is 
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# As always, bug reports, suggestions, etc: volkerdi@slackware.com
#
# Modifications 2016, 2017, 2019, 2020 by Eric Hameleers <alien@slackware.com>
#

# -------------------------------------------- #
#   Slackware Live Edition - check the media   #
# -------------------------------------------- #

# The Slackware setup depends on english language settings because it
# parses program output like that of "fdisk -l". So, we need to override
# the Live user's local language settings here:
export LANG=C
export LC_ALL=C

if [ ! -d /mnt/livemedia/@LIVEMAIN@/system ]; then
 dialog  --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
  --title "LIVE MEDIA NOT ACCESSIBLE" --msgbox "\
\n\
Before you can install software, complete the following tasks:\n\
\n\
1. Mount your Live media partition on /mnt/livemedia." 16 68
  exit 1
fi

# ------------------------------------------------ #
#   Slackware Live Edition - end check the media   #
# ------------------------------------------------ #

TMP=/var/log/setup/tmp
if [ ! -d $TMP ]; then
  mkdir -p $TMP
fi
# Wipe the probe md5sum to force rescanning partitions if setup is restarted:
rm -f $TMP/SeTpartition.md5
rm -f $TMP/SeT*
# If a keymap was set up, restore that data:
if [ -r $TMP/Pkeymap ]; then
  cp $TMP/Pkeymap $TMP/SeTkeymap
fi
echo "on" > $TMP/SeTcolor # turn on color menus
PATH="$PATH:/usr/share/@LIVEMAIN@"
export PATH;
export COLOR=on
dialog --backtitle "@CDISTRO@ Linux Setup (Live Edition)" --infobox "\n
Scanning your system for partition information...\n
\n" 5 55
# In case the machine is full of fast SSDs:
sleep 1
# Before probing, activate any LVM partitions
# that may exist from before the boot:
vgchange -ay 1> /dev/null 2> /dev/null
if probe -l 2> /dev/null | grep -E 'Linux$' 1> /dev/null 2> /dev/null ; then
 RUNPART=no
 probe -l 2> /dev/null | grep -E 'Linux$' | sort 1> $TMP/SeTplist 2> /dev/null
 dialog --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
  --title "LINUX PARTITIONS DETECTED" \
  --yes-label "Continue" --no-label "Skip" --defaultno \
  --yesno "Setup detected partitions on this machine of type Linux.\n\
You probably created these before running '$(basename $0)'. Great!\n\n\
If you would like to re-consider your partitioning scheme, \
you can click 'Continue' now to start 'cfdisk' (MBR disk) \
and/or 'cgdisk' (GPT disk) for all your hard drives.\n\
Otherwise, select 'Skip' to skip disk partitioning and go on with the setup." \
12 64
 if [ $? -eq 0 ]; then
  RUNPART=yes
 fi
else
 RUNPART=yes
 dialog --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
  --title "NO LINUX PARTITIONS DETECTED" \
  --msgbox "There don't seem to be any partitions on this machine of type \
Linux.  You'll need to make at least one of these to install Linux.  \
To do this, you'll get a chance to make these partitions now using \
'cfdisk' (MBR partitions) or 'cgdisk' (GPT partitions)." 10 64
fi
if [ -d /sys/firmware/efi ]; then
  if ! probe -l 2> /dev/null | grep "EFI System Partition" 1> /dev/null 2> /dev/null ; then
    RUNPART=yes
    dialog --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
     --title "NO EFI SYSTEM PARTITION DETECTED" \
     --msgbox "This machine appears to be using EFI/UEFI, but no EFI System \
Partition was found.  You'll need to make an EFI System Partition in order \
to boot from the hard drive. In the next step, using cfdisk/cgdisk, \
make a 100MB partition of type EF00." 10 64
  fi
fi
if [ "$RUNPART" = "yes" ]; then

  # ------------------------------------------------------- #
  #   Slackware Live Edition - find/partition the disk(s)   #
  # ------------------------------------------------------- #

  SeTudiskpart
  if [ ! $? = 0 ]; then
    # No disks found or user canceled, means: abort.
    exit 1
  fi

  # ----------------------------------------------------------- #
  #   Slackware Live Edition - end find/partition the disk(s)   #
  # ----------------------------------------------------------- #

fi # End RUNPART = yes

T_PX="/setup2hd"
mkdir -p ${T_PX}
echo "$T_PX" > $TMP/SeTT_PX
ROOT_DEVICE="`mount | grep "on / " | cut -f 1 -d ' '`"
echo "$ROOT_DEVICE" > $TMP/SeTrootdev
if mount | grep /var/log/mount 1> /dev/null 2> /dev/null ; then # clear source location:
  # In case of bind mounts, try to unmount them first:
  umount /var/log/mount/dev 2> /dev/null
  umount /var/log/mount/proc 2> /dev/null
  umount /var/log/mount/sys 2> /dev/null
  # Unmount target partition:
  umount /var/log/mount
fi
# Anything mounted on /var/log/mount now is a fatal error:
if mount | grep /var/log/mount 1> /dev/null 2> /dev/null ; then
  echo "Can't umount /var/log/mount.  Reboot machine and run setup again."
  exit
fi
# If the mount table is corrupt, the above might not do it, so we will
# try to detect Linux and FAT32 partitions that have slipped by:
if [ -d /var/log/mount/lost+found -o -d /var/log/mount/recycled \
     -o -r /var/log/mount/io.sys ]; then
  echo "Mount table corrupt.  Reboot machine and run setup again."
  exit
fi
rm -f /var/log/mount 2> /dev/null
rmdir /var/log/mount 2> /dev/null
mkdir /var/log/mount 2> /dev/null

while [ 0 ]; do

 dialog --title "@CDISTRO@ Linux Setup (version @SL_VERSION@)" \
  --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
  --menu "Welcome to @CDISTRO@ Linux Setup (Live Edition).\n\
Select an option below using the UP/DOWN keys and SPACE or ENTER.\n\
Alternate keys may also be used: '+', '-', and TAB." 18 72 9 \
"KEYMAP" "Remap your keyboard if you're not using a US one" \
"ADDSWAP" "Set up your swap partition(s)" \
"TARGET" "Set up your target partitions" \
"INSTALL" "Install @CDISTRO@ to disk" \
"CONFIGURE" "Reconfigure your Linux system" \
"EXIT" "Exit @CDISTRO@ Linux Setup" 2> $TMP/hdset
 if [ ! $? = 0 ]; then
  rm -f $TMP/hdset $TMP/SeT*
  exit
 fi
 MAINSELECT="`cat $TMP/hdset`"
 rm $TMP/hdset

 # Start checking what to do. Some modules may reset MAINSELECT to run the
 # next item in line.

 if [ "$MAINSELECT" = "KEYMAP" ]; then
  SeTkeymap
  if [ -r $TMP/SeTkeymap ]; then
   MAINSELECT="ADDSWAP" 
  fi
 fi
 
 if [ "$MAINSELECT" = "MAKE TAGS" ]; then
  SeTmaketag
 fi
 
 if [ "$MAINSELECT" = "ADDSWAP" ]; then
  SeTswap
  if [ -r $TMP/SeTswap ]; then
   MAINSELECT="TARGET"
  elif [ -r $TMP/SeTswapskip ]; then
   # Go ahead to TARGET without swap space:
   MAINSELECT="TARGET"
  fi
 fi

 if [ "$MAINSELECT" = "TARGET" ]; then
  SeTpartitions
  SeTEFI
  SeTDOS
  if [ -r $TMP/SeTnative ]; then
   MAINSELECT="SOURCE"
  fi
 fi

 if [ "$MAINSELECT" = "SOURCE" ]; then
  SeTumedia 
  if [ -r $TMP/SeTsource ]; then
   if [ -r $TMP/SeTlive ]; then
    MAINSELECT="INSTALL"
   else
    MAINSELECT="SELECT"
   fi
  fi
 fi

 if [ "$MAINSELECT" = "SELECT" ]; then
  if [ -r /var/log/mount/isolinux/setpkg ]; then
    sh /var/log/mount/isolinux/setpkg
  else
    SeTPKG
  fi
  if [ -r $TMP/SeTSERIES ]; then
   MAINSELECT="INSTALL"
  fi
 fi

 if [ "$MAINSELECT" = "INSTALL" ]; then
  if [ -r $TMP/SeTlive ]; then
   source setup.liveslak
  else
   source setup.slackware
  fi
 fi

 if [ "$MAINSELECT" = "CONFIGURE" ]; then
  # Patch (e)liloconfig on the target systems to remove hardcoded /mnt:
  if [ -f /sbin/liloconfig -a -f $T_PX/sbin/liloconfig ]; then
    cat /sbin/liloconfig > $T_PX/sbin/liloconfig
  fi
  if [ -f /usr/sbin/eliloconfig -a -f $T_PX/usr/sbin/eliloconfig ]; then
    cat /usr/sbin/eliloconfig > $T_PX/usr/sbin/eliloconfig
  fi
  # Make bind mounts for /dev, /proc, and /sys:
  mount -o bind /dev $T_PX/dev 2> /dev/null
  mount -o bind /proc $T_PX/proc 2> /dev/null
  mount -o bind /sys $T_PX/sys 2> /dev/null
  SeTconfig
  REPLACE_FSTAB=Y
  if [ -r $TMP/SeTnative ]; then
   if [ -r $T_PX/etc/fstab ]; then
    dialog --title "REPLACE /etc/fstab?" --yesno "You already have an \
/etc/fstab on your install partition.  If you were just adding software, \
you should probably keep your old /etc/fstab.  If you've changed your \
partitioning scheme, you should use the new /etc/fstab.  Do you want \
to replace your old /etc/fstab with the new one?" 10 58
    if [ ! $? = 0 ]; then
     REPLACE_FSTAB=N
    fi
   fi
   if [ "$REPLACE_FSTAB" = "Y" ]; then
    cat /dev/null > $T_PX/etc/fstab
    if [ -r $TMP/SeTswap ]; then
     cat $TMP/SeTswap > $T_PX/etc/fstab
    fi
    cat $TMP/SeTnative >> $T_PX/etc/fstab
    if [ -r $TMP/SeTDOS ]; then
     cat $TMP/SeTDOS >> $T_PX/etc/fstab
    fi
    printf "%-16s %-16s %-11s %-16s %-3s %s\n" "#/dev/cdrom" "/mnt/cdrom" "auto" "noauto,owner,ro,comment=x-gvfs-show" "0" "0" >> $T_PX/etc/fstab
    printf "%-16s %-16s %-11s %-16s %-3s %s\n" "/dev/fd0" "/mnt/floppy" "auto" "noauto,owner" "0" "0" >> $T_PX/etc/fstab
    printf "%-16s %-16s %-11s %-16s %-3s %s\n" "devpts" "/dev/pts" "devpts" "gid=5,mode=620" "0" "0" >> $T_PX/etc/fstab
    printf "%-16s %-16s %-11s %-16s %-3s %s\n" "proc" "/proc" "proc" "defaults" "0" "0" >> $T_PX/etc/fstab
    printf "%-16s %-16s %-11s %-16s %-3s %s\n" "tmpfs" "/dev/shm" "tmpfs" "defaults" "0" "0" >> $T_PX/etc/fstab
   fi
   dialog --title "SETUP COMPLETE" --msgbox "System configuration \
and installation is complete. \
\n\nYou may now reboot your system." 7 55
  fi
 fi

 if [ "$MAINSELECT" = "EXIT" ]; then
  break
 fi

done # end of main loop
sync

chmod 755 $T_PX
if [ -d $T_PX/tmp ]; then
 chmod 1777 $T_PX/tmp
fi
if mount | grep /var/log/mntiso 1> /dev/null 2> /dev/null ; then
 umount -f /var/log/mntiso
fi
if mount | grep /var/log/mount 1> /dev/null 2> /dev/null ; then
 umount /var/log/mount
fi
# Anything mounted on /var/log/mount now is a fatal error:
if mount | grep /var/log/mount 1> /dev/null 2> /dev/null ; then
  exit
fi
# If the mount table is corrupt, the above might not do it, so we will
# try to detect Linux and FAT32 partitions that have slipped by:
if [ -d /var/log/mount/lost+found -o -d /var/log/mount/recycled \
     -o -r /var/log/mount/io.sys ]; then
  exit
fi
rm -f /var/log/mount 2> /dev/null
rmdir /var/log/mount 2> /dev/null
mkdir /var/log/mount 2> /dev/null
chmod 755 /var/log/mount

# An fstab file is indicative of an OS installation, rather than
# just loading the "setup" script and selecting "EXIT"
if [ -f ${T_PX}/etc/fstab ]; then
  # umount CD:
  if [ -r $TMP/SeTCDdev ]; then
    if mount | grep iso9660 > /dev/null 2> /dev/null ; then
      umount `mount | grep iso9660 | cut -f 1 -d ' '`
    fi
    eject -s `cat $TMP/SeTCDdev`
    # Tell the user to remove the disc, if one had previously been mounted
    # (it should now be ejected):
    dialog \
     --clear \
     --title "@CDISTRO@ Linux Setup is complete" "$@" \
     --msgbox "\nPlease remove the installation disc.\n" 7 40
  fi
  # Sign off to the user:
  dialog \
     --clear \
     --title "@CDISTRO@ Linux Setup is complete" "$@" \
     --msgbox "\nInstallation is complete.\n\n
You can reboot your system whenever you like,\n
but don't forget to remove this Live medium first.\n" 11 50

fi

# Fix the date:
fixdate

# final cleanup
rm -f $TMP/tagfile $TMP/SeT* $TMP/tar-error $TMP/unsquash_output $TMP/unsquash_error $TMP/PKGTOOL_REMOVED
rm -f /var/log/mount/treecache
rmdir /var/log/mntiso 2>/dev/null
rm -rf $TMP/treecache
rm -rf $TMP/pkgcache
rmdir ${T_PX}/tmp/orbit-root 2> /dev/null

# If the OS had been installed and the user elected to reboot:
if [ -f /reboot ]; then
   clear
   echo "** Starting reboot **"
   sleep 1
   reboot
fi

# end slackware setup script

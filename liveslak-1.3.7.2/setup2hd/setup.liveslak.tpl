 # Liveslak installation routine:
 if [ "$MAINSELECT" = "INSTALL" ]; then
  if [ ! -r $TMP/SeTnative ]; then
   dialog --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
    --title "CANNOT INSTALL SOFTWARE YET" --msgbox "\
\n\
Before you can install software, complete the following tasks:\n\
\n\
1. Set up your target Linux partition(s).\n\
\n\
You may also optionally remap your keyboard and set up your\n\
swap partition(s). \n\
\n\
Press ENTER to return to the main menu." 16 68
   continue
  fi

  # --------------------------------------------- #
  #   Slackware Live Edition - install to disk:   #
  # --------------------------------------------- #

  # Buy us some time while we are calculating disk usage:
  dialog --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
   --title "WELCOME TO @UDISTRO@ LIVE (@LIVEDE@)" --infobox \
   "\nCalculating disk usage, please be patient ..." 5 65

  ACT_MODS=$(ls -rt --indicator-style=none /mnt/live/modules/ |wc -l)
  TOT_MODS=$(find /mnt/livemedia/@LIVEMAIN@/ -type f -name "*.sxz" |wc -l)
  DU_LIVE=$(du -s /mnt/live/modules/ 2>/dev/null |tr -s '\t' ' ' |cut -f1 -d' ')
  PARTFREE=$(df -P -BM $T_PX |tail -1 |tr -s '\t' ' ' |cut -d' ' -f4)
  PARTFREE=${PARTFREE%M}

  # Warn when it looks we have insufficient room:
  if [ $PARTFREE -lt $(($DU_LIVE/1024)) ]; then
    dialog --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
     --title "WELCOME TO @UDISTRO@ LIVE (@LIVEDE@)" --yesno \
     "\nAvailable space: $PARTFREE MB\nRequired space: $(($DU_LIVE/1024))\nIt looks like your hard drive partition is too small.\nDo you want to continue?" 10 65
    retval=$?
    if [ $retval = 1 ]; then
      umount $T_PX
      exit 1
    fi
  else
    dialog --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
     --title "WELCOME TO @UDISTRO@ LIVE (@LIVEDE@)" --msgbox \
     "\nAvailable space: $PARTFREE MB\nRequired space: $(($DU_LIVE/1024)) MB\nIt looks like you're good to go!" 10 65
  fi

  (
    # Install the Live OS by rsyncing the readonly overlay to the harddisk:
    rsync -HAXa --whole-file --checksum-choice=none --inplace \
      --info=progress2 --no-inc-recursive \
      /mnt/liveslakfs/ $T_PX/ ; echo DONE \
  ) | dialog --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
        --title "INSTALLING @UDISTRO@ LIVE (@LIVEDE@) TO DISK" --programbox \
        "\nProcessing ${TOT_MODS} @CDISTRO@ Live modules ($(( $DU_LIVE/1024 )) MB)" 8 80

  #
  # Live OS Post Install routine. If you want, you can override this routine
  # by (re-)defining this function "live_post_install()" in a file called
  # "/usr/share/@LIVEMAIN@/setup2hd.@DISTRO@".
  #

  live_post_install () {
    # ---------------------
    # Set up a user account,
    dialog --title "@UDISTRO@ (@LIVEDE@) USER CREATION" \
     --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
     --msgbox "You will first get the chance to create your user account, \
and set its password.\nYour account will be added to sudoers and suauth.\n\n\
After that, you will be asked to set the root password." 11 55
    # This will set UFULLNAME, UACCOUNT, UACCTNR and USHELL variables:
    SeTuacct 2>&1 1> $TMP/uacctresult
    if [ $? = 0 ]; then
      # User filled out the form, so let's get the results for
      # UFULLNAME, UACCOUNT, UACCTNR and USHELL:
      source $TMP/uacctresult
      rm -f $TMP/uacctresult
      # Set a password for the new account:
      UPASS=$(SeTupass $UACCOUNT)
      # Create the account and set the password:
      chroot ${T_PX} /usr/sbin/useradd -c "$UFULLNAME" -g users -G wheel,audio,cdrom,floppy,plugdev,video,power,netdev,lp,scanner,dialout,games,disk,input -u ${UACCTNR} -d /home/${UACCOUNT} -m -s ${USHELL} ${UACCOUNT}
      echo "${UACCOUNT}:${UPASS}" | chroot ${T_PX} /usr/sbin/chpasswd
      unset UPASS

      # Configure suauth if we are not on a PAM system
      # (where this does not work):
      if [ ! -L ${T_PX}/lib@DIRSUFFIX@/libpam.so.? ]; then
        cat <<EOT >${T_PX}/etc/suauth
root:${UACCOUNT}:OWNPASS
root:ALL EXCEPT GROUP wheel:DENY
EOT
        chmod 600 ${LIVE_ROOTDIR}/etc/suauth
      fi

      # Configure sudoers:
      chmod 640 ${T_PX}/etc/sudoers
      sed -i ${T_PX}/etc/sudoers -e 's/# *\(%wheel\sALL=(ALL)\sALL\)/\1/'
      chmod 440 ${T_PX}/etc/sudoers
    fi # End user creation
    # ---------------------------

    if [ "$(cat $T_PX/etc/shadow | grep 'root:' | cut -f 2 -d :)" = "" ]; then
      # There is no root password yet:
      UPASS=$(SeTupass root)
      echo "root:${UPASS}" | chroot ${T_PX} /usr/sbin/chpasswd
      unset UPASS
    fi

    # Re-use some of the custom configuration from 0099-@DISTRO@_zzzconf-*.sxz
    # (some of these may not be present but the command will not fail):
    dialog --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
     --title "POST-INSTALL @UDISTRO@ LIVE (@LIVEDE@) DATA" --infobox \
     "\nCopying Live modifications to hard disk ..." 5 65
    sleep 1 # It's too fast...
    # Do not overwrite a custom keymap:
    if [ ! -f $T_PX/etc/rc.d/rc.keymap ]; then
      unsquashfs -n -f -dest $T_PX \
        /mnt/livemedia/@LIVEMAIN@/system/0099*zzzconf*.sxz \
        /etc/rc.d/rc.keymap
    fi
    unsquashfs -n -f -dest $T_PX \
      /mnt/livemedia/@LIVEMAIN@/system/0099*zzzconf*.sxz \
      /etc/X11/xinit/xinitrc \
      /etc/X11/xdm/liveslak-xdm \
      /etc/X11/xorg.conf.d/30-keyboard.conf \
      /etc/inittab \
      /etc/skel \
      /etc/profile.d/lang.sh \
      /etc/rc.d/rc.font \
      /etc/rc.d/rc.gpm \
      /etc/slackpkg \
      /etc/vconsole.conf
    # Point xdm to the custom /etc/X11/xdm/liveslak-xdm/xdm-config:
    sed -i ${T_PX}/etc/rc.d/rc.4 -e 's,bin/xdm -nodaemon,& -config /etc/X11/xdm/liveslak-xdm/xdm-config,'
    # Prevent SeTconfig from asking redundant questions later on:
    sed -i ${T_PX}/usr/share/@LIVEMAIN@/SeTconfig \
      -e '/.\/var\/log\/setup\/$SCRIPT $T_PX $ROOT_DEVICE/i # Skip stuff that was taken care of by liveslak\nif echo $SCRIPT |grep -E "(make-bootdisk|mouse|setconsolefont|xwmconfig)"; then continue; fi'

    # If a user account was created, we restore some of the user customization:
    if [ -n "${UACCOUNT}" ] && [ -d "${T_PX}/home/${UACCOUNT}" ]; then
      unsquashfs -n -f -dest $T_PX \
        /mnt/livemedia/@LIVEMAIN@/system/0099*zzzconf*.sxz \
        /home/@LIVEUID@/.face \
        /home/@LIVEUID@/.face.icon
      if [ "@LIVEUID@" != ${UACCOUNT} ]; then
        rsync -a $T_PX/home/@LIVEUID@/ $T_PX/home/${UACCOUNT}/
        rm -rf $T_PX/home/@LIVEUID@
      fi
    fi

    # If the Live OS is real-time capable we need to apply that to the install:
    if [ "@LIVEDE@" = "PLASMA5" -o "@LIVEDE@" = "DAW" -o "@LIVEDE@" = "STUDIOWARE" ];
then
      unsquashfs -n -f -dest $T_PX \
        /mnt/livemedia/@LIVEMAIN@/system/0099*zzzconf*.sxz \
        /etc/security/limits.d/rt_audio.conf \
        /etc/initscript \
        /etc/udev/rules.d/40-timer-permissions.rules \
        /etc/sysctl.d/daw.conf
    fi

    # Copy relevant settings for Live DAW:
    if [ "@LIVEDE@" = "DAW" ];
then
      LCLIVEDE=$(echo @LIVEDE@ |tr 'A-Z' 'a-z')
      unsquashfs -n -f -dest $T_PX \
        /mnt/livemedia/@LIVEMAIN@/system/0099*zzzconf*.sxz \
        /etc/pulse/daemon.conf \
        /etc/xdg/menus/applications-merged/liveslak-daw.menu \
        /usr/share/desktop-directories/liveslak-daw.directory \
        /usr/share/icons/hicolor/256x256/apps/liveslak-daw.png \
        /usr/share/applications \
        /usr/share/wallpapers/${LCLIVEDE} \
        /usr/share/@LIVEMAIN@/${LCLIVEDE}/background.jpg \
        /usr/share/sddm/themes/breeze/${LCLIVEDE}_background.jpg \
        /usr/share/sddm/themes/breeze/theme.conf.user

      # If a user account was created, we restore DAW user customization:
      if [ -n "${UACCOUNT}" ] && [ -d "${T_PX}/home/${UACCOUNT}" ]; then
        unsquashfs -n -f -dest $T_PX \
          /mnt/livemedia/@LIVEMAIN@/system/0099*zzzconf*.sxz \
          /home/@LIVEUID@/.jackdrc \
          /home/@LIVEUID@/.config/autostart/qjackctl.desktop \
          /home/@LIVEUID@/.config/rncbc.org/QjackCtl.conf \
          /home/@LIVEUID@/.config/kscreenlockerrc
        if [ "@LIVEUID@" != ${UACCOUNT} ]; then
          rsync -a $T_PX/home/@LIVEUID@/ $T_PX/home/${UACCOUNT}/
          rm -rf $T_PX/home/@LIVEUID@
        fi
      fi
    fi
    # Let's ensure the proper ownership:
    chroot ${T_PX} /usr/bin/chown -R ${UACCTNR} /home/${UACCOUNT}

    # Remove the marker file from the filesystem root:
    rm -f ${T_PX}/@MARKER@

    cat << EOF > $TMP/tempmsg

 @CDISTRO@ Live Edition (@LIVEDE@) has been installed to your hard drive!
 We installed the ${ACT_MODS} active modules (out of ${TOT_MODS} available).
 The following configuration was copied from the Live OS to your harddisk:
  - console font
  - default runlevel
  - keyboard layout
  - language setting
 After finishing system configuration and before rebooting, you can add any further Live modules from /@LIVEMAIN@/addons/ and /@LIVEMAIN@/optional/ to your hard drive, using a command similar to this:
    # unsquashfs -f -dest $T_PX /mnt/livemedia/@LIVEMAIN@/addons/mymodule.sxz

EOF
    dialog --backtitle "@CDISTRO@ Linux Setup (Live Edition)" \
      --title "POST INSTALL HINTS AND TIPS" --msgbox "`cat $TMP/tempmsg`" \
      20 65
    rm $TMP/tempmsg

    MAINSELECT="CONFIGURE"
  } # END live_post_install() function


  if [ -f /usr/share/@LIVEMAIN@/setup2hd.@DISTRO@ ]; then
    # If the setup2hd post-configuration file exists, source it.
    # The file should re-define the live_post_install() function.
    . /usr/share/@LIVEMAIN@/setup2hd.@DISTRO@
  fi

  # Now, execute the function - either our own built-in version
  # or the re-defined function from the custom setup2hd.@DISTRO@ file.
  live_post_install

  # --------------------------------------------- #
  # Slackware Live Edition - end install to disk: #
  # --------------------------------------------- #

 fi
 # End liveslak installation routine.

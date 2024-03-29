#!/bin/sh
TMP=/var/log/setup/tmp
if [ ! -d $TMP ]; then
  mkdir -p $TMP
fi

UACCOUNT="$1"

    UPASS1=""
    UPASS2=""
    UFORM="Define a new password for user '$UACCOUNT'"
    while [ 0 ]; do
      dialog --stdout --insecure --ok-label "Submit" --no-cancel \
        --title "@UDISTRO@ (@LIVEDE@) USER CREATION" \
        --passwordform "$UFORM" \
        9 64 0 \
          "Password:"        1 1 "$UPASS1" 1 18 40 0 \
          "Repeat password:" 2 1 "$UPASS2" 2 18 40 0 \
        2>&1 1> $TMP/tempupass
      iii=0
      declare -a USERATTR
      while read LINE ; do
        USERATTR[$iii]="$LINE"
        iii=$(expr $iii + 1)
      done < $TMP/tempupass
      rm -f $TMP/tempupass
      UPASS1="${USERATTR[0]}"
      UPASS2="${USERATTR[1]}"
      unset USERATTR
      if [ -z "$UPASS1" ]; then
        UFORM="Password must not be empty, try again for user '$UACCOUNT'"
      elif [ "$UPASS1" == "$UPASS2" ]; then
        break
      else
        UFORM="Passwords do not match, try again for user '$UACCOUNT'"
      fi
    done
    echo "${UPASS1}"
    unset UPASS1
    unset UPASS2
    unset USERATTR


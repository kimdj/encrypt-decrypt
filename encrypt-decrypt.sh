#!/bin/bash
# Copyright (c) 2017 David Kim
# This program is licensed under the "MIT License".

# Encrypt-Decrypt files using OpenSSL.
# Cipher: AES 256 Cipher Blocker Chaining (cbc)
# Usage: source encrypt-decrypt.sh
#        encrypt source_file
#        decrypt source_file.aes-256-cbc

encrypt() {
  IS_DIR=0
  FILENAME="$1"
  if [[ $FILENAME ]] ; then                                 # If command argument exists...
    if [[ -d "$FILENAME" ]] ; then                          # If $FILENAME is a directory, create a tar archive...
      IS_DIR=1
      FILENAME="$(echo "$FILENAME" | sed -e 's|\/||')"      # Remove the trailing '/' in the command argument, if it exists.
      tar -cf "${FILENAME}.tar" "$FILENAME"                 # Create the tarball.
      FILENAME="${FILENAME}.tar"                            # Set $FILENAME to the tar archive.
    elif [[ ! -f "$FILENAME" ]] ; then                      # If $FILENAME is not a regular file...
      echo "$FILENAME is not a valid file or directory."
      return 1                                              # ...exit immediately.
    fi

    PASSWD_HINT=''
    HINT_EXISTS=0
    if [[ -f passwd.hint ]] ; then                          # If passwd.hint file exists...
      printf "passwd.hint file found.\n"
      HINT_EXISTS=1
      NL=$'\n'
      while read line ; do                                  # Prepend password hint to $PASSWD_HINT line-by-line.
        PASSWD_HINT=$(echo -ne "${PASSWD_HINT}\n${line}")
      done < passwd.hint
    else                                                    # Otherwise, have the user input a password hint.
      printf "passwd.hint file not found.\n"
      printf "Enter in a password hint: "
      read PASSWD_HINT
    fi

    openssl aes-256-cbc -a -salt -in "$FILENAME" -out "${FILENAME}.aes-256-cbc"       # Run OpenSSL.

    echo -e "\n$(printf -- '-%.0s' {1..64})\n$(cat "${FILENAME}.aes-256-cbc")" > "${FILENAME}.aes-256-cbc"          # Prepend a separator in the encrypted file.
    if [[ $HINT_EXISTS == 1 ]] ; then
      echo -e "${PASSWD_HINT}$(cat "${FILENAME}.aes-256-cbc")" > "${FILENAME}.aes-256-cbc"                          # Now, prepend $PASSWD_HINT.
      tail -n +2 "${FILENAME}.aes-256-cbc" > tmp                                                                    # Remove the first line which is empty.
      mv tmp "${FILENAME}.aes-256-cbc"
    else
      echo -e "${PASSWD_HINT}$(cat "${FILENAME}.aes-256-cbc")" > "${FILENAME}.aes-256-cbc"                          # Now, prepend $PASSWD_HINT.
    fi

    # NEEDS IMPLEMENTATION: HASH THE FILENAME; ADD THE HASHED FILENAME TO THE TOP OF THE ENCRYPTED FILE
    # MAKE IT SO THAT DECRYPTION IS INDEPENDENT FROM THE FILENAME

    if [[ $IS_DIR == 1 ]] ; then                   # Clean up intermediary files.
      rm "${FILENAME}"
    fi

    echo "Now you can safely remove the original file."
  else
    echo "usage: encrypt source_file"
  fi
}

decrypt() {
  FILENAME="$1"
  if [[ $FILENAME ]] ; then                                                                       # If file exists, delete the preceding lines containing the passwd hint.
    line=$(( $(cat $FILENAME | grep -n -E -- "-{64}" | cut -d : -f 1) + 1 ))                      # Get the line number after password hint block.
    sed '/----------------------------------------------------------------/,$!d' "$FILENAME" |    # Remove the lines containing the password hint.
    sed '1d' > "${FILENAME}.intermediate"

    openssl aes-256-cbc -d -a -in "${FILENAME}.intermediate" -out "${FILENAME}.decrypted" 2> /dev/null                      # Run OpenSSL.
    if [[ $(echo $?) != 0 ]] ; then                                                               # If exit code is not 0, return immediately.
      echo "Wrong Password."
      rm "${FILENAME}.intermediate"
      return
    fi

    if [[ $(file ${FILENAME}.decrypted | grep tar) ]] ; then                    # If $FILENAME is a tar archive, extract to disk.
      if [[ ! "$FILENAME" =~ \.tar$ ]] ; then
        mv ${FILENAME}.decrypted ${FILENAME}.tar
      fi
      tar -xf "${FILENAME}.tar"
      rm "${FILENAME}.tar"
    fi
    rm "${FILENAME}.intermediate"             # Clean up intermediary files.

    echo "Now you can safely remove the encrypted file."
  else
    echo "usage: decrypt source_file.aes-256-cbc"
  fi
}

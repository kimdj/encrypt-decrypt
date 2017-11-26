#!/bin/bash
# Copyright (c) 2017 David Kim
# This program is licensed under the "MIT License".

# Decrypt files using OpenSSL.
# Cipher: AES 256 Cipher Blocker Chaining (cbc)
# Usage: ./decrypt.sh some.file.aes-256-cbc

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

decrypt

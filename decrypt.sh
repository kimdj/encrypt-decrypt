#!/bin/bash
# Copyright (c) 2017 David Kim
# This program is licensed under the "MIT License".

# Decrypt files using OpenSSL.
# Cipher: AES 256 Cipher Blocker Chaining (cbc)
# Usage: ./decrypt.sh some.file.aes-256-cbc

decrypt() {
  FILENAME="$1"
  if [[ $FILENAME ]] ; then
    line=$(( $(cat $FILENAME | grep -n -E -- "-{64}" | cut -d : -f 1) + 1 ))                      # Get the line number after password hint block.
    sed '/----------------------------------------------------------------/,$!d' "$FILENAME" |    # Remove the lines containing the password hint.
    sed '1d' > "${FILENAME}.intermediate"

    FILENAME="${FILENAME}.intermediate"
    FILEOUT="$(echo "${FILENAME}" | sed -e 's|\.aes-256-cbc\.intermediate||')"

    openssl aes-256-cbc -d -a -in "${FILENAME}" -out "$FILEOUT" 2> /dev/null                      # Run OpenSSL.
    if [[ $(echo $?) != 0 ]] ; then                                                               # If exit code is not 0, return immediately.
      echo "Wrong Password."
      rm "${FILENAME}" "${FILEOUT}"
      return
    fi

    if [[ "$FILEOUT" =~ \.tar$ ]] ; then                    # If $FILEOUT is a tar archive, extract to disk.
      tar -xf "$FILEOUT"
      rm "$FILEOUT"
    fi
    rm "${FILENAME}"             # Clean up intermediary files.

    echo "Now you safely remove the encrypted file."
  else
    echo "usage: decrypt source_file.aes-256-cbc"
  fi
}

decrypt

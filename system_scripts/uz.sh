#!/usr/bin/env sh

# Goal is to unzip/untar or extract compressed files

if [ $# -eq 0 ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "File not found: $1"
    exit 1
fi

if [ -d "$1" ]; then
    echo "Directory found: $1"
    exit 1
fi

# Source - https://stackoverflow.com/a/407334
# Posted by user49586, modified by community. See post 'Timeline' for change history
# Retrieved 2026-09-03, License - CC BY-SA 4.0
echo "discerning file type: $1"

#!/usr/bin/env bash

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 ARCHIVE"
    exit 1
fi

archive=$1

if [[ ! -f "$archive" ]]; then
    echo "File not found: $archive"
    exit 1
fi

mime_type=$(file -b --mime-type "$archive")

case "$mime_type" in
    application/zip)
        unzip "$archive"
        ;;

    application/x-tar)
        tar -xvf "$archive"
        ;;

    application/gzip | application/x-gzip)
        tar -xzvf "$archive"
        ;;

    application/x-bzip2 | application/x-bzip)
        tar -xjvf "$archive"
        ;;

    application/x-xz)
        tar -xJvf "$archive"
        ;;

    application/x-7z-compressed)
        7z x "$archive"
        ;;

    application/x-rar | application/vnd.rar)
        unrar x "$archive"
        ;;

    *)
        echo "Unknown compression type for: $archive"
        echo "Detected MIME type: $mime_type"
        exit 1
        ;;
esac


echo "Compression tool: $COMPRESSION"

if [ ! command -v $COMMAND >/dev/null 2>&1; ]; then
    echo "Compression tool not found: $COMPRESSION"

    ./install.sh "$COMPRESSION"
    if [ ! -x "$COMMAND" ]; then
        echo "Failed to install: $COMPRESSION"
        exit 1
    fi
fi

echo "Extracting: $1"
$COMMAND $ARGUMENT "$1"

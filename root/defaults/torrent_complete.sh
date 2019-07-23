#!/bin/bash

MESSAGE="${TR_APP_VERSION}\n${TR_TIME_LOCALTIME}\n${TR_TORRENT_DIR}\n${TR_TORRENT_HASH}\n${TR_TORRENT_ID}\n${TR_TORRENT_NAME}"

echo -e "${MESSAGE}" > /config/output.txt

find "${TR_TORRENT_DIR}/${TR_TORRENT_NAME}" -type f \( -name "*.azw" -or -name "*.azw3" -or -name "*.azw4" -or -name "*.chm" -or -name "*.djv" -or -name "*.djvu" -or -name "*.epub" -or -name "*.lit" -or -name "*.mobi" -or -name "*.pdf" -or -name "*.prc" \) -exec /opt/calibre/calibredb --with-library=http://${CALIBRE_HOST}:${CALIBRE_PORT}/#${CALIBRE_LIB} --username=${CALIBRE_USR} --password=${CALIBRE_PWD} add {} + > /config/output.txt


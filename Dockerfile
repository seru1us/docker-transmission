FROM lsiobase/alpine:3.10

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="sparklyballs"

RUN \
 echo "**** install packages ****" && \
 apk add --no-cache \
	curl \
	findutils \
	jq \
	openssl \
	p7zip \
	python \
	rsync \
	tar \
	transmission-cli \
	transmission-daemon \
	unrar \
	unzip && \
 echo "**** install third party themes ****" && \
 curl -o \
	/tmp/combustion.zip -L \
	"https://github.com/Secretmapper/combustion/archive/release.zip" && \
 unzip \
	/tmp/combustion.zip -d \
	/ && \
 mkdir -p /tmp/twctemp && \
 TWCVERSION=$(curl -sX GET "https://api.github.com/repos/ronggang/transmission-web-control/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]') && \
 curl -o \
	/tmp/twc.tar.gz -L \
	"https://github.com/ronggang/transmission-web-control/archive/${TWCVERSION}.tar.gz" && \
 tar xf \
	/tmp/twc.tar.gz -C \
	/tmp/twctemp --strip-components=1 && \
 mv /tmp/twctemp/src /transmission-web-control && \
 mkdir -p /kettu && \
 curl -o \
	/tmp/kettu.tar.gz -L \
	"https://github.com/endor/kettu/archive/master.tar.gz" && \
 tar xf \
	/tmp/kettu.tar.gz -C \
	/kettu --strip-components=1 && \

 echo "**** cleanup ****" && \
 rm -rf \
	/tmp/*

# Install GNU libc (aka glibc)
# https://github.com/sgerrand/alpine-pkg-glibc
# https://github.com/Technosoft2000/docker-calibre-web/blob/master/Dockerfile
COPY LOCALE.md /tmp/
RUN \

    ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.29-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \

    # create temporary directories
    mkdir -p /tmp && \
    mkdir -p /var/cache/apk && \

    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    apk add --no-cache parallel && \

    wget "https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub" \
         -O "/etc/apk/keys/sgerrand.rsa.pub" && \

    wget "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
         "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
         "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \

    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \

    # iterate through all locale and install it
    # NOTE: locale -a is not available in alpine linux, 
    # use `/usr/glibc-compat/bin/locale -a` instead
    cat /tmp/LOCALE.md | parallel "echo generate locale {}; /usr/glibc-compat/bin/localedef --force --inputfile {} --charmap UTF-8 {}.UTF-8;" && \

    apk del .build-dependencies && \

    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    rm "/root/.wget-hsts" && \
    rm "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
       "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
       "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

# Install calibre binary
# enhancement from jim3ma/docker-calibre-web
# needed for calibre ebook-convert command line tool
# https://github.com/jim3ma/docker-calibre-web
# https://manual.calibre-ebook.com/generated/en/ebook-convert.html
# https://github.com/Technosoft2000/docker-calibre-web/blob/master/Dockerfile
ENV \
    LD_LIBRARY_PATH="/usr/lib:/opt/calibre/lib" \
    PATH="$PATH:/opt/calibre" \
    LC_ALL="C" \
    CALIBRE_INSTALLER_SOURCE_CODE_URL="https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py"

RUN \
    apk update && \
    apk add --no-cache --upgrade \
        bash \
        ca-certificates \
        gcc \
        libxcomposite \
        mesa-gl \
        python \
        qt5-qtbase-x11 \
        xdg-utils \
        xz \
        wget && \

    wget -O- ${CALIBRE_INSTALLER_SOURCE_CODE_URL} | \
      python -c \
      "import sys; \
       main=lambda:sys.stderr.write('Download failed\n'); \
       exec(sys.stdin.read()); \
       main(install_dir='/opt', isolated=True)" && \

    rm -rf /tmp/calibre-installer-cache && \

    # remove not needed packages
    apk del --purge $PKG_DEV \
                    $PKG_IMAGES_DEV && \

    # create Calibre Web folder structure
    mkdir -p $APP_HOME/app && \

    # cleanup temporary files
    rm -rf /tmp && \
    rm -rf /var/cache/apk/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 9091 51413
VOLUME /config /downloads /watch

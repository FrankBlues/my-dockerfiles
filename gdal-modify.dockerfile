##
# modified based on official image(osgeo/gdal:ubuntu-full)
# remove "java" "MDB Driver Jars" "mongo c" "mongo cxx" "tiledb"

ARG BASE_IMAGE=ubuntu:20.04

FROM $BASE_IMAGE as builder

# Derived from osgeo/proj by Howard Butler <howard@hobu.co>
LABEL maintainer=""

# Setup build env for PROJ
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
            software-properties-common build-essential ca-certificates \
            git make cmake wget unzip libtool automake \
            zlib1g-dev libsqlite3-dev pkg-config sqlite3 libcurl4-gnutls-dev \
            libtiff5-dev \
    && rm -rf /var/lib/apt/lists/*

# Setup build env for GDAL
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
       libcharls-dev libopenjp2-7-dev libcairo2-dev \
       python3-dev python3-numpy \
       libpng-dev libjpeg-dev libgif-dev liblzma-dev libgeos-dev \
       curl libxml2-dev libexpat-dev libxerces-c-dev \
       libnetcdf-dev libpoppler-dev libpoppler-private-dev \
       libspatialite-dev swig ant libhdf4-alt-dev libhdf5-serial-dev \
       libfreexl-dev unixodbc-dev libwebp-dev libepsilon-dev \
       liblcms2-2 libpcre3-dev libcrypto++-dev libdap-dev libfyba-dev \
       libkml-dev libmysqlclient-dev libogdi-dev \
       libcfitsio-dev libzstd-dev \
       libpq-dev libssl-dev libboost-dev \
       autoconf automake bash-completion libarmadillo-dev \
       libopenexr-dev libheif-dev \
       libdeflate-dev \
    && rm -rf /var/lib/apt/lists/*

# Build likbkea
ARG KEA_VERSION=1.4.13
RUN wget -q https://github.com/ubarsc/kealib/archive/kealib-${KEA_VERSION}.zip \
    && unzip -q kealib-${KEA_VERSION}.zip \
    && rm -f kealib-${KEA_VERSION}.zip \
    && cd kealib-kealib-${KEA_VERSION} \
    && cmake . -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr -DHDF5_INCLUDE_DIR=/usr/include/hdf5/serial \
        -DHDF5_LIB_PATH=/usr/lib/x86_64-linux-gnu/hdf5/serial -DLIBKEA_WITH_GDAL=OFF \
    && make -j$(nproc) \
    && make install DESTDIR="/build_thirdparty" \
    && make install \
    && cd .. \
    && rm -rf kealib-kealib-${KEA_VERSION} \
    && for i in /build_thirdparty/usr/lib/*; do strip -s $i 2>/dev/null || /bin/true; done \
    && for i in /build_thirdparty/usr/bin/*; do strip -s $i 2>/dev/null || /bin/true; done

# Build openjpeg
ARG OPENJPEG_VERSION=
RUN if test "${OPENJPEG_VERSION}" != ""; then ( \
    wget -q https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}.tar.gz \
    && tar xzf v${OPENJPEG_VERSION}.tar.gz \
    && rm -f v${OPENJPEG_VERSION}.tar.gz \
    && cd openjpeg-${OPENJPEG_VERSION} \
    && cmake . -DBUILD_SHARED_LIBS=ON  -DBUILD_STATIC_LIBS=OFF -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
    && make -j$(nproc) \
    && make install \
    && mkdir -p /build_thirdparty/usr/lib/x86_64-linux-gnu \
    && rm -f /usr/lib/x86_64-linux-gnu/libopenjp2.so* \
    && mv /usr/lib/libopenjp2.so* /usr/lib/x86_64-linux-gnu \
    && cp -P /usr/lib/x86_64-linux-gnu/libopenjp2.so* /build_thirdparty/usr/lib/x86_64-linux-gnu \
    && for i in /build_thirdparty/usr/lib/x86_64-linux-gnu/*; do strip -s $i 2>/dev/null || /bin/true; done \
    && cd .. \
    && rm -rf openjpeg-${OPENJPEG_VERSION} \
    ); fi

#Build File Geodatabase

ARG WITH_FILEGDB=
RUN if echo "$WITH_FILEGDB" | grep -Eiq "^(y(es)?|1|true)$"  ; then ( \
  wget -q https://github.com/Esri/file-geodatabase-api/raw/master/FileGDB_API_1.5.1/FileGDB_API_1_5_1-64gcc51.tar.gz \
  && tar -xzf FileGDB_API_1_5_1-64gcc51.tar.gz \
  && chown -R root:root FileGDB_API-64gcc51 \
  && mv FileGDB_API-64gcc51 /usr/local/FileGDB_API \
  && rm -rf /usr/local/FileGDB_API/lib/libstdc++* \
  && cp /usr/local/FileGDB_API/lib/* /build_thirdparty/usr/lib \
  && cp /usr/local/FileGDB_API/include/* /usr/include \
  && rm -rf FileGDB_API_1_5_1-64gcc51.tar.gz \
  ) ; fi



RUN apt-get update -y \
    && apt-get install -y --fix-missing --no-install-recommends rsync ccache \
    && rm -rf /var/lib/apt/lists/*
ARG RSYNC_REMOTE

ARG WITH_DEBUG_SYMBOLS=no

# Build PROJ
ARG PROJ_VERSION=master
ARG PROJ_INSTALL_PREFIX=/usr/local
COPY ./bh-proj.sh /buildscripts/bh-proj.sh
RUN /buildscripts/bh-proj.sh

ARG GDAL_VERSION=master
ARG GDAL_RELEASE_DATE
ARG GDAL_BUILD_IS_RELEASE

# Build GDAL
COPY ./bh-gdal.sh /buildscripts/bh-gdal.sh
RUN /buildscripts/bh-gdal.sh

# Build final image
FROM $BASE_IMAGE as runner

RUN date
ARG JAVA_VERSION=11

RUN apt-get update \
# PROJ dependencies
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libsqlite3-0 libtiff5 libcurl4 \
        wget curl unzip ca-certificates \
# GDAL dependencies
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libcharls2 libopenjp2-7 libcairo2 python3-numpy \
        libpng16-16 libjpeg-turbo8 libgif7 liblzma5 libgeos-3.8.0 libgeos-c1v5 \
        libxml2 libexpat1 \
        libxerces-c3.2 libnetcdf-c++4 netcdf-bin libpoppler97 libspatialite7 gpsbabel \
        libhdf4-0-alt libhdf5-103 libhdf5-cpp-103 poppler-utils libfreexl1 unixodbc libwebp6 \
        libepsilon1 liblcms2-2 libpcre3 libcrypto++6 libdap25 libdapclient6v5 libfyba0 \
        libkmlbase1 libkmlconvenience1 libkmldom1 libkmlengine1 libkmlregionator1 libkmlxsd1 \
        libmysqlclient21 libogdi4.1 libcfitsio8 openjdk-"$JAVA_VERSION"-jre \
        libzstd1 bash bash-completion libpq5 libssl1.1 \
        libarmadillo9 libpython3.8 libopenexr24 libheif1 \
        libdeflate0 \
        python-is-python3 \
    # Workaround bug in ogdi packaging
    && ln -s /usr/lib/ogdi/libvrf.so /usr/lib \
    && rm -rf /var/lib/apt/lists/*

# Attempt to order layers starting with less frequently varying ones

COPY --from=builder  /build_thirdparty/usr/ /usr/

ARG PROJ_DATUMGRID_LATEST_LAST_MODIFIED
ARG PROJ_INSTALL_PREFIX=/usr/local
COPY --from=builder  /build${PROJ_INSTALL_PREFIX}/share/proj/ ${PROJ_INSTALL_PREFIX}/share/proj/
COPY --from=builder  /build${PROJ_INSTALL_PREFIX}/include/ ${PROJ_INSTALL_PREFIX}/include/
COPY --from=builder  /build${PROJ_INSTALL_PREFIX}/bin/ ${PROJ_INSTALL_PREFIX}/bin/
COPY --from=builder  /build${PROJ_INSTALL_PREFIX}/lib/ ${PROJ_INSTALL_PREFIX}/lib/
RUN ldconfig \
    && projsync --system-directory --all

COPY --from=builder  /build/usr/share/gdal/ /usr/share/gdal/
COPY --from=builder  /build/usr/include/ /usr/include/
COPY --from=builder  /build_gdal_python/usr/ /usr/
COPY --from=builder  /build_gdal_version_changing/usr/ /usr/

RUN ldconfig
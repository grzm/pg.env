#!/bin/bash
set -eux

PG_BASE_DIR=${HOME}/pgsql
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while getopts "v:" OPT ; do
    case "${OPT}" in
        v ) PG_MAJOR_VERSION="${OPTARG}" ;;
        * ) echo Unknown option "${OPTARG}" && exit 1 ;;
    esac
done

case "${PG_MAJOR_VERSION}" in
    12 ) PG_MINOR_VERSION=12.0 ;;
    11 ) PG_MINOR_VERSION=11.5 ;;
    10 ) PG_MINOR_VERSION=10.6 ;;
    9.6 ) PG_MINOR_VERSION=9.6.11 ;;
    9.5 ) PG_MINOR_VERSION=9.5.15 ;;
    9.4 ) PG_MINOR_VERSION=9.4.20 ;;
    9.3 ) PG_MINOR_VERSION=9.3.25 ;;
    9.2 ) PG_MINOR_VERSION=9.2.24 ;;
    9.1 ) PG_MINOR_VERSION=9.1.24 ;;
    9.0 ) PG_MINOR_VERSION=9.0.23 ;;
    8.4 ) PG_MINOR_VERSION=8.4.22 ;;
    8.3 ) PG_MINOR_VERSION=8.3.23 ;;
    8.2 ) PG_MINOR_VERSION=8.2.23 ;;
    * ) echo "Unknown version" && exit 1 ;;
esac

MAJOR_DIR="${PG_BASE_DIR}/${PG_MAJOR_VERSION}"
MINOR_DIR="${MAJOR_DIR}/${PG_MINOR_VERSION}"
PREFIX="${PG_BASE_DIR}/${PG_MAJOR_VERSION}/${PG_MINOR_VERSION}"
MINOR_SRC_DIR="${MINOR_DIR}/src"


BASE_URL=https://ftp.postgresql.org/pub/source/
SRC_DIRNAME="postgresql-${PG_MINOR_VERSION}"
PKG_NAME="${SRC_DIRNAME}.tar.bz2"
PKG_URL="https://ftp.postgresql.org/pub/source/v${PG_MINOR_VERSION}/${PKG_NAME}"

mkdir -p "${MINOR_SRC_DIR}"
cd "${MINOR_SRC_DIR}"
test -e "${PKG_NAME}" || wget "${PKG_URL}"
test -d "${SRC_DIRNAME}" || tar -zxf "${PKG_NAME}"
cd "${SRC_DIRNAME}"

set +e
make clean
set -e

case "${PG_MAJOR_VERSION}" in
    1[012] )
        ./configure --prefix "${PREFIX}" \
                    --with-includes=/opt/local/include \
                    --with-libraries=/opt/local/lib \
                    --enable-debug \
                    --enable-cassert \
                    --enable-dtrace \
                    --enable-nls \
                    --with-bonjour \
                    --with-gssapi \
                    --with-ldap \
                    --with-libxml \
                    --with-libxslt \
                    --with-openssl \
                    --with-uuid=e2fs \
                    --with-pam \
                    --with-perl \
                    --with-python \
                    --with-tcl \
                    CFLAGS="-ggdb"

        # Ideally we'd run make check before make install. However, on macOS with SIP,
        # the dynamic linker falls back on /usr/lib/libpq.dylib if there isn't an
        # existing installation. So, we install and *then* check.
        # For details, see
        # https://www.postgresql.org/message-id/18963.1497367542%40sss.pgh.pa.us

        make
        if [ -e "${PREFIX}/lib/libpq.dylib" ]; then
            make check && make install
        else
            make install && make check
        fi
        make -C contrib && make -C contrib install
        ;;
    9.[456] )
        ./configure --prefix "${PREFIX}" \
                    --with-includes=/opt/local/include \
                    --with-libraries=/opt/local/lib \
                    --enable-dtrace \
                    --enable-nls \
                    --with-bonjour \
                    --with-gssapi \
                    --with-ldap \
                    --with-libxml \
                    --with-libxslt \
                    --with-openssl \
                    --with-uuid=e2fs \
                    --with-pam \
                    --with-perl \
                    --with-python \
                    --with-tcl
        make
        if [ -e "${PREFIX}/lib/libpq.dylib" ]; then
            make check && make install
        else
            make install && make check
        fi
        make -C contrib && make -C contrib install
        ;;
    9.[0123] )
        patch -p1 -i "${SCRIPT_PATH}/uuid-ossp.patch"
        ./configure --prefix "${PREFIX}" \
                    --with-includes=/opt/local/include \
                    --with-libraries=/opt/local/lib \
                    --enable-dtrace \
                    --enable-nls \
                    --with-bonjour \
                    --with-gssapi \
                    --with-krb5 \
                    --with-ldap \
                    --with-libxml \
                    --with-libxslt \
                    --with-openssl \
                    --with-ossp-uuid \
                    --with-pam \
                    --with-perl \
                    --with-python \
                    --with-tcl
        ;;
    8.4 )
#        patch -p1 -i "${SCRIPT_PATH}/uuid-ossp.patch"
        ./configure --prefix "${PREFIX}" \
                    --with-includes=/opt/local/include \
                    --with-libraries=/opt/local/lib \
                    --enable-dtrace \
                    --enable-nls \
                    --with-gssapi \
                    --with-krb5 \
                    --with-ldap \
                    --with-libxml \
                    --with-libxslt \
                    --with-openssl \
                    --with-ossp-uuid \
                    --with-pam \
                    --with-perl \
                    --with-python \
                    --with-tcl
        ;;
    8.3 )
        patch -p1 -i "${SCRIPT_PATH}/uuid-ossp.patch"
        ./configure --prefix "${PREFIX}" \
                    --with-includes=/opt/local/include \
                    --with-libraries=/opt/local/lib \
                    --enable-thread-safety \
                    --with-gssapi \
                    --with-krb5 \
                    --with-ldap \
                    --with-libxml \
                    --with-libxslt \
                    --with-openssl \
                    --with-ossp-uuid \
                    --with-pam \
                    --with-perl \
                    --with-python \
                    --with-tcl
        ;;
    8.2 )
        ./configure --prefix "${PREFIX}" \
                    --with-includes=/opt/local/include \
                    --with-libraries=/opt/local/lib \
                    --enable-thread-safety \
                    --with-krb5 \
                    --with-ldap \
                    --with-openssl \
                    --with-pam \
                    --with-perl \
                    --with-python \
                    --with-tcl
        ;;
    * ) echo "Unknown version" && exit 1 ;;
esac

make && make check && make install

MAJOR_VERSION_LN_DIR="${PG_BASE_DIR}/${PG_MAJOR_VERSION}/current"
MINOR_VERSION_INSTALL_DIR="${PG_BASE_DIR}/${PG_MAJOR_VERSION}/${PG_MINOR_VERSION}"

test -e "${MAJOR_VERSION_LN_DIR}" && rm "${MAJOR_VERSION_LN_DIR}"
ln -s "${MINOR_VERSION_INSTALL_DIR}" "${MAJOR_VERSION_LN_DIR}"

## check for data directory
## if none, initdb
## append to postgresql.conf to add include


# http://pgfoundry.org/frs/download.php/3392/plproxy-2.5.tar.gz
# tar xzf plproxy-2.5.tar.gz
# cd plproxy-2.5
# USE_PGXS=1 make
# USE_PGXS=1 make install
# git clone https://github.com/theory/pgtap.git
# cd pgtap
# make
# make install

# http://pgfoundry.org/frs/download.php/2607/ip4r-1.05.tar.gz
# tar xzf ip4r-1.05.tar.gz
# cd ip4r-1.05
# USE_PGXS=1 make install
### http://pgfoundry.org/frs/download.php/3650/ip4r-2.0.2.tar.gz

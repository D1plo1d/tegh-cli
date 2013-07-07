#!/usr/bin/env bash

# IMPORTANT 
# Protect agaisnt mispelling a var and rm -rf /
set -u
set -e

TEGH_VERSION=0.2.0

SRC=/tmp/tegh-deb-src
DIST=/tmp/tegh-deb-dist
SYSROOT=${SRC}/sysroot
DEBIAN=${SRC}/DEBIAN

rm -rf ${DIST}
mkdir -p ${DIST}/

rm -rf ${SRC}
rsync -a ubuntu-src/ ${SRC}/
mkdir -p ${SYSROOT}/opt/tegh

rsync -a ../src/ ${SYSROOT}/opt/tegh/src --delete
rm -f ${SYSROOT}/opt/tegh/bin/
mkdir -p ${SYSROOT}/opt/tegh/bin/
cp ../bin/tegh ${SYSROOT}/opt/tegh/bin/tegh
cp ../README.md ${SYSROOT}/opt/tegh/README.md
cp ../package.json ${SYSROOT}/opt/tegh/package.json

sed -i '' "s/#!\/usr\/bin\/env node/#!\/usr\/bin\/env nodejs/" ${SYSROOT}/opt/tegh/bin/tegh

find ${SRC}/ -type d -exec chmod 0755 {} \;
find ${SRC}/ -type f -exec chmod go-w {} \;
# chown -R root:users ${SRC}/

let SIZE=`du -s ${SYSROOT} | sed s'/[^0-9]*//g'`+8
pushd ${SYSROOT}/
tar czf ${DIST}/data.tar.gz [a-z]*
popd
sed -i '' "s/<%=SIZE%>/${SIZE}/" ${DEBIAN}/control
sed -i '' "s/<%=VERSION%>/${TEGH_VERSION}/" ${DEBIAN}/control
pushd ${DEBIAN}
tar czf ${DIST}/control.tar.gz *
popd
pushd ${DIST}/
echo "2.0" > ./debian-binary

find ${DIST}/ -type d -exec chmod 0755 {} \;
find ${DIST}/ -type f -exec chmod go-w {} \;
# chown -R root:users ${DIST}/
ar r ${DIST}/tegh-${TEGH_VERSION}.deb debian-binary control.tar.gz data.tar.gz
popd

rm -rf ./tegh-${TEGH_VERSION}.deb
rsync -a ${DIST}/tegh-${TEGH_VERSION}.deb ./

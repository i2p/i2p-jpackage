#!/bin/bash

if [ -z "${JAVA_HOME}" ]; then
    echo "JAVA_HOME needs to point to Java 14+"
    exit 1
fi

echo "cleaning"
rm -f *.jar
rm -rf build
rm -f *.exe
rm -f *.dmg


RES_DIR=../i2p.i2p/installer/resources
I2P_JARS=../i2p.i2p/pkg-temp/lib
HERE=$PWD

echo "preparing resources.csv"
mkdir build
cd $RES_DIR
find certificates -name *.crt -exec echo '{},{}' >> $HERE/build/resources.csv \;
cd $HERE
echo "geoip/GeoLite2-Country.mmdb,geoip/GeoLite2-Country.mmdb" >> build/resources.csv

echo "copying certificates"
cp -R $RES_DIR/certificates build/

echo "copying GeoIP"
mkdir build/geoip
cp $RES_DIR/GeoLite2-Country.mmdb.gz build/geoip
gunzip build/geoip/GeoLite2-Country.mmdb.gz

echo "compiling custom launcher"
cp $I2P_JARS/*.jar build
cd java
$JAVA_HOME/bin/javac -d ../build -classpath ../build/i2p.jar:../build/router.jar net/i2p/router/PackageLauncher.java
cd ..

echo "building launcher.jar"
cd build
$JAVA_HOME/bin/jar -cf launcher.jar net certificates geoip resources.csv
cd ..

echo "preparing to invoke jpackage"
$JAVA_HOME/bin/jpackage --name I2P --input build --main-jar launcher.jar --main-class net.i2p.router.PackageLauncher

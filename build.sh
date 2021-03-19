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



HERE=$PWD
RES_DIR=$HERE/../i2p.i2p/installer/resources
I2P_JARS=$HERE/../i2p.i2p/pkg-temp/lib
I2P_PKG=$HERE/../i2p.i2p/pkg-temp


echo "preparing resources.csv"
mkdir build
cd $RES_DIR
find certificates -name *.crt -exec echo '{},{}' >> $HERE/build/resources.csv \;
cd portable/configs
find . -name '*.config' -exec echo 'config/{},{}' >> $HERE/build/resources.csv \;
echo "config/hosts.txt,hosts.txt" >> $HERE/build/resources.csv
echo "preparing webapps"
cd $I2P_PKG
find webapps -name '*.war' -exec echo '{},{}' >> $HERE/build/resources.csv \;
cd $HERE
echo "geoip/GeoLite2-Country.mmdb,geoip/GeoLite2-Country.mmdb" >> build/resources.csv

sed -i 's|\./||g' build/resources.csv

echo "copying certificates"
cp -R $RES_DIR/certificates build/
echo "copying config"
cp -R $RES_DIR/portable/configs build/config
cp -R $RES_DIR/hosts.txt build/config/hosts.txt
cp -R $I2P_PKG/webapps build/

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
$JAVA_HOME/bin/jar -cf launcher.jar net certificates geoip config webapps resources.csv
cd ..

echo "preparing to invoke jpackage"
cp $I2P_JARS/*.jar build

if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	$JAVA_HOME/bin/jpackage --type app-image --name I2P --input build --main-jar launcher.jar --main-class net.i2p.router.PackageLauncher
else
	$JAVA_HOME/bin/jpackage --name I2P --input build --main-jar launcher.jar --main-class net.i2p.router.PackageLauncher
fi

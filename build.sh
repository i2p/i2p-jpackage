#!/bin/bash
set -e 

JAVA=$(java --version | tr -d 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\n' | cut -d ' ' -f 2 | cut -d '.' -f 1 | tr -d '\n\t ')

if [ "$JAVA" -lt "14" ]; then
	echo "Java 14+ must be used to compile with jpackage, java is $JAVA"
	exit 1
fi


if [ -z "${JAVA_HOME}" ]; then
	JAVA_HOME=`type -p java|xargs readlink -f|xargs dirname|xargs dirname`
	echo "Building with: $JAVA, $JAVA_HOME"
fi

echo "cleaning"
./clean.sh

HERE=$PWD
RES_DIR=$HERE/../i2p.i2p/installer/resources
I2P_JARS=$HERE/../i2p.i2p/pkg-temp/lib
I2P_PKG=$HERE/../i2p.i2p/pkg-temp


echo "preparing resources.csv"
mkdir build
cd $RES_DIR
find certificates -name *.crt -exec echo '{},{},true' >> $HERE/build/resources.csv \;
cd portable/configs
find . -name '*.config' -exec echo 'config/{},{},false' >> $HERE/build/resources.csv \;
echo "config/hosts.txt,hosts.txt,false" >> $HERE/build/resources.csv
echo "preparing webapps"
cd $I2P_PKG
find webapps -name '*.war' -exec echo '{},{},true' >> $HERE/build/resources.csv \;
# TODO add others
cd $HERE
echo "geoip/GeoLite2-Country.mmdb,geoip/GeoLite2-Country.mmdb,true" >> build/resources.csv
# TODO: decide on blocklist.txt

sed -i.bak 's|\./||g' build/resources.csv

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

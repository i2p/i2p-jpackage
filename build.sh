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

HERE="$PWD"
RES_DIR="$HERE/../i2p.i2p/installer/resources"
I2P_JARS="$HERE/../i2p.i2p/pkg-temp/lib"
I2P_PKG="$HERE/../i2p.i2p/pkg-temp"


echo "preparing resources.csv"
mkdir -p build build/config build/geoip

cp -rv "$RES_DIR/certificates" build/certificates
cp -rv "$I2P_PKG/webapps" build/webapps
cp -v "$I2P_PKG/"*.config build/config
cp -v "$I2P_PKG/"hosts.txt build/config


cp "$RES_DIR"/GeoLite2-Country.mmdb.gz build/geoip
gunzip build/geoip/GeoLite2-Country.mmdb.gz

#cd "$RES_DIR"
cd build
find certificates -name *.crt -exec echo '{},{},true' >> "$HERE"/build/resources.csv \;
cd config
find . -name '*.config' -exec echo 'config/{},{},false' >> "$HERE"/build/resources.csv \;
cd  ..
echo "config/hosts.txt,hosts.txt,false" >> "$HERE"/build/resources.csv
echo "preparing webapps"
#cd "$I2P_PKG"


find webapps -name '*.war' -exec echo '{},{},true' >> "$HERE"/build/resources.csv \;
# TODO add others
cd "$HERE"
echo "geoip/GeoLite2-Country.mmdb,geoip/GeoLite2-Country.mmdb,true" >> build/resources.csv
# TODO: decide on blocklist.txt

sed -i.bak 's|\./||g' build/resources.csv

echo "compiling custom launcher"
cp "$I2P_JARS"/*.jar build
cd java
"$JAVA_HOME"/bin/javac -d ../build -classpath "$HERE"/build/i2p.jar:"$HERE"/build/router.jar net/i2p/router/PackageLauncher.java
cd ..

echo "building launcher.jar"
cd build
"$JAVA_HOME"/bin/jar -cf launcher.jar net certificates geoip config webapps resources.csv
cd ..

if [ -z $I2P_VERSION ]; then 
    I2P_VERSION=$("$JAVA_HOME"/bin/java -cp build/router.jar net.i2p.router.RouterVersion | sed "s/.*: //" | head -n 1)
fi
echo "preparing to invoke jpackage for I2P version $I2P_VERSION"

#cp "$I2P_JARS"/*.jar build
#cp "$I2P_PKG/Start I2P Router.app/Contents/Resources/i2p.icns" build/I2P.icns
#cp "$I2P_PKG/Start I2P Router.app/Contents/Resources/i2p.icns" build/I2P-volume.icns
#cp "$I2P_PKG"/LICENSE.txt build

if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	"$JAVA_HOME"/bin/jpackage --type app-image --name I2P --app-version "$I2P_VERSION" \
        --verbose \
        $JPACKAGE_OPTS \
        --resource-dir build \
        --input build --main-jar launcher.jar --main-class net.i2p.router.PackageLauncher
elif uname | grep -i mingw; then
	"$JAVA_HOME"/bin/jpackage --type app-image --name I2P --app-version "$I2P_VERSION" \
        --verbose \
        $JPACKAGE_OPTS \
        --resource-dir build \
        --input build --main-jar launcher.jar --main-class net.i2p.router.PackageLauncher
else
	"$JAVA_HOME"/bin/jpackage --name I2P --app-version "$I2P_VERSION" \
        --verbose \
        $JPACKAGE_OPTS \
        --resource-dir build \
        --license-file build/LICENSE.txt \
        --input build --main-jar launcher.jar --main-class net.i2p.router.PackageLauncher
fi

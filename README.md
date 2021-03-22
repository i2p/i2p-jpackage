# I2P JPackage 

** This is work in progress.  Even this readme may change rapidly. **

This project aims to contain scripts and code necessary to build all-in-one installers for Windows and Mac using the [JPackage] tool.

### Requirements

You need JDK 14 or newer installed on your system.  On Windows you also need the [Wix] tool and a bash-like environment like [Cygwin] or [GitBash].

### Building

1. Set the `JAVA_HOME` variable to point to the installation of the JDK
1. Clone the i2p.i2p module as a sibling to this module.
1. Build it using `ant clean pkg`
1. Run `build.sh`


### How does it work

The I2P router expects to find some resources in specific places.  The legacy I2P installer deployes those resources where they are exxpected to be.  However with installers built with JPackage, and more specifically with Mac AppBundles it is not possible to execute arbitrary code during installation.  The way to get around this is:


1. Create a .jar file containing the following resources
   * All router certificates
   * GeoIP database
   * Custom Launcher
1. Enumerate these resources and generate a file called `resources.csv`.  The format is CSV file where the first entry is the path that the classloader will use to locate the file, the second entry is the path under the preferences directory where the resource should be copied, and the third entry indicates whether to overwrite any existing files (true|false).  Add this file in the .jar built in step 1.
1. Use a custom main class `net.i2p.router.PackageLauncher` which reads the above list and copies each resource to the appropriate path under the current user's preferences directory, which is OS-dependent.
1. The custom main class will also set any system properties necessary for I2P to work, then invoke the "real" main class `net.i2p.router.RouterLaunch`.
1. The compiled custom main class gets added to the .jar as well.

JPackage gets invoked and pointed to the custom main class.  It's operation can be customized by setting the following environment variables:

|Variable|Purpose|Example|
|---|---|---|
|JPACKAGE_OPTS|Options to pass to jpackage, usualy OS-dependent|`--mac-sign`|
|I2P_VERSION|Overrides the version from the `router.jar` file| `1.2.3`|



[JPackage]: https://openjdk.java.net/jeps/392
[Wix]: https://wixtoolset.org/
[Cygwin]: https://cygwin.com
[GitBash]: https://gitforwindows.org

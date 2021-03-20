# TODO List

Items left to do before this can be used for production installers:

* Parse router version from `i2p.i2p` and pass to jpackage
* Pass icon to jpackage - this is tricky as formats are different on Mac and Win
* Pass additional OS-specific switches to jpackage (i.e. `--mac-sign`)
* Should blocklist.txt be overwritten on router upgrades?
* Decide on jvm switches (i.e. -Xmx) and pass them through jpackage
* Pass license file to jpackage (maybe only windows needs this?)

To get some of these done OS detection may need to happen inside `build.sh`.

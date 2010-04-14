DESCRIPTION = "PoiGuides - Guide and be guided"
HOMEPAGE = "http://github.com/Ebbe/PoiGuides"
LICENSE = "GPLv3"
AUTHOR = "Esben Damgaard <ebbe@hvemder.dk>"
DEPENDS = "dbus-glib elementary"

#PV = "0.1+gitr${SRCPV}"
PR = "r0"

SRC_URI = "file:///home/ebbe/Projects/valide/iliwi/iliwi-0.0.1.tar.gz"
S = "${WORKDIR}/iliwi-0.0.1"

FILES_${PN} += "${datadir}/poiguides ${datadir}/applications ${datadir}/pixmaps"

inherit autotools vala

# needed because there is do_stage_append in vala.bbclass and do_stage() was removed..
do_stage() {

}

do_configure() {
    oe_runconf
}

do_compile() {
    oe_runmake
}

do_install() { 
    oe_runmake install DESTDIR=${D}
}

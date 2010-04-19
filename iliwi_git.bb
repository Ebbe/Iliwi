DESCRIPTION = "Iliwi connects you."
HOMEPAGE = "http://github.com/Ebbe/Iliwi"
LICENSE = "GPLv3"
AUTHOR = "Esben Damgaard <ebbe@hvemder.dk>"
DEPENDS = "dbus-glib libeflvala elementary"

SRCREV_pn-${PN} = "${AUTOREV}"
PV = "0.0.1+gitr${SRCPV}"

SRC_URI = "git://github.com/Ebbe/Iliwi.git;protocol=http;branch=master"
S = "${WORKDIR}/git"

inherit autotools vala

# needed because there is do_stage_append in vala.bbclass and do_stage() was removed..
do_stage() {
}

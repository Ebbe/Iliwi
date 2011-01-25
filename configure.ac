AC_INIT([iliwi],0.0.1)
AM_INIT_AUTOMAKE
AC_CONFIG_SRCDIR([src/main.vala])


AC_PROG_CC
m4_pattern_allow
AM_PROG_VALAC([0.11.4])

PKG_CHECK_MODULES([DEPS], [glib-2.0 gio-2.0 elementary gee-1.0])

AC_CHECK_LIB(gthread-2.0, g_thread_init)
AC_CHECK_LIB(libeflvala)

AC_OUTPUT([Makefile
	 src/Makefile data/Makefile])

AM_VALAFLAGS =  \
	--pkg "gio-2.0"  --pkg "glib-2.0" --pkg "dbus-glib-1" --pkg "elm" --pkg "gee-1.0" \
	--thread

AM_CFLAGS = $(DEPS_CFLAGS)
AM_LIBS = $(DEPS_LIBS) $(DEPS_LIBS)

bin_PROGRAMS = iliwi

iliwi_SOURCES = main.vala view_main.vala wifi.vala dbus_interfaces.vala

iliwi_LDFLAGS = $(AM_LIBS)

clean:
	rm -f *.c *.o *.stamp

MAINTAINERCLEANFILES = Makefile.in

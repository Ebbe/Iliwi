AM_VALAFLAGS = \
	--pkg "gio-2.0" --pkg "glib-2.0" --pkg "elm" --pkg "gee-1.0" \
	--pkg "sqlite3" \
	--thread

AM_CFLAGS = $(DEPS_CFLAGS)
AM_LIBS = $(DEPS_LIBS) $(DEPS_LIBS)

bin_PROGRAMS = iliwi

iliwi_SOURCES = main.vala \
                view_main.vala view_select_networks.vala view_network.vala \
                wifi.vala wifi_scan_iwlist.vala wifi_connect_wpa_supplicant.vala \
                wifi_scan_interface.vala wifi_connect_interface.vala \
                wifi_networks.vala wifi_network.vala \
                database.vala \
                dbus_interfaces.vala

iliwi_LDFLAGS = $(AM_LIBS)

clean:
	rm -f *.c *.o *.stamp

MAINTAINERCLEANFILES = Makefile.in

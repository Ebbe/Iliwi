/*
    This file is part of iliwi.

    iliwi is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License Version 3
    as published by the Free Software Foundation.

    iliwi is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with iliwi.  If not, see <http://www.gnu.org/licenses/>.
*/

namespace WifiConnect {
  class WpaSupplicant : Interface, GLib.Object {
    private ConnectionDone connection_done;
    Network? network;
    
    public void set_connection_done_callback(ConnectionDone _cd) {
      connection_done = _cd;
    }

    public void connect_to(Network _network) {
      disconnect_from_network();
      network = _network;
      
      DirUtils.create_with_parents(Environment.get_user_config_dir() + "/iliwi",0755);
      string filename = Environment.get_user_config_dir() + "/iliwi/wpa_supplicant.conf";
      string password = network.password;
      //if(network.password_in_ascii)
        password = "\""+network.password+"\"";
      var stream = FileStream.open(filename, "w");
      stream.puts( "ctrl_interface=/var/run/wpa_supplicant\n" );
      stream.puts( "network={\n" );
      stream.puts( "  ssid=\"%s\"\n".printf(network.essid) );
      if( network.encryption )
        if ( network.wpa_encryption && (!network.authentication) ) // WPA-Personal
          stream.puts("  psk=%s\n".printf(password));
        else if ( network.wpa_encryption && network.authentication ) { // WPA-Enterprise
          stream.puts("  password=%s\n".printf(password));
          stream.puts("  key_mgmt=WPA-EAP\n");
          stream.puts("  pairwise=CCMP TKIP\n");
          stream.puts("  group=CCMP TKIP\n");
          stream.puts("  eap=PEAP\n");
          if ( network.cert != "" )
            stream.puts("  ca_cert=\"%s%s\"\n".printf(network.cert_dir, network.cert));
          stream.puts("  identity=\"%s\"\n".printf(network.username));
          stream.puts("  phase1=\"peaplabel=0\"\n");
          stream.puts("  phase2=\"auth=MSCHAPV2\"\n");
        }
        else { // WEP encryption                                                                                                                           
          stream.puts("  key_mgmt=NONE\n");
          stream.puts("  wep_key0=%s\n".printf(password));
        }
      else
        stream.puts( "  key_mgmt=NONE\n" ); // No encryption
      stream.puts( "}\n" );
      stream.flush();
      stream = null;
      
      try {
        string[] supplicant_args = {Environment.find_program_in_path("wpa_supplicant"),"-i", "wlan0", "-c", filename,"-B"};
        Process.spawn_sync(null, supplicant_args, null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null);
      } catch(GLib.SpawnError e) {
        critical("Couldn't start spawn!");
      }
    }
    
    public void disconnect_from_network() {
      try {
        Process.spawn_sync(null, {Environment.find_program_in_path("killall"),"wpa_supplicant"}, null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null);
        FileUtils.remove("/var/run/wpa_supplicant/eth0");
      } catch(GLib.SpawnError e) {}
      if( network!=null ) {
        network.status = NetworkStatus.UNCONNECTED;
        network = null;
      }
    }
  }
}

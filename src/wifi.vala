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

using Gee;
using Elm;

namespace iliwi {
  
  public class Wifi : GLib.Object {
    public string status { get; private set; default="initializing"; }
    
    public signal void status_change();
    public signal void network_list_change();
    
    unowned Thread thread;
    
    public Wifi() {
      try {
        thread = Thread.create(WifiThread.run_thread, true);
      } catch(Error e) {
        critical("Couldn't start wifi-thread!");
      }
    }
    ~Wifi() {
      WifiThread.stop_thread();
      thread.join(); // Wait for it to finish
    }
    
    public Network[] get_visible_networks() {
      return WifiThread.get_visible_networks();
    }
    
    public void connect_to(Network network) {
      WifiThread.connect_to_network(network);
    }
    public void set_preferred_state(Network network,bool new_state) {
      network.preferred_network = new_state;
      WifiThread.preferred_state_change(network);
    }
    public void set_ascii_state(Network network,bool new_state) {
      network.password_in_ascii = new_state;
      WifiThread.preferred_ascii_password_state_change(network);
    }
    
    public void preferred_network_password_change(Network network) {
      WifiThread.preferred_network_password_change(network);
    }

    public void preferred_network_username_change(Network network) {
      WifiThread.preferred_network_username_change(network);
    }

    public void preferred_network_certificate_change(Network network) {
      WifiThread.preferred_network_certificate_change(network);
    }

    // Callback from thread
    public void set_new_status(string new_status) {
      //debug(new_status);
      status = new_status;
      status_change();
    }
    public void visible_network_change() {
      network_list_change();
    }
  }
  
  public enum NetworkStatus {
    UNCONNECTED,
    CONNECT, // About to connect
    CONNECTING,
    CONNECTED
  }
  
  struct PreferredNetwork {
    string password;
    bool password_in_ascii;
    string username;
    string cert;
    string cert_dir;
  }
  
  public class Network {
    public string address;
    public string essid = "";
    public bool encryption = false;
    public bool authentication = false;
    public bool server_cert_is_set = false;
    public bool wpa_encryption {get; private set; default=false;}
    public string password = "";
    public string username = "";
    public string cert = "";
    public string cert_dir = "";
    public bool password_in_ascii = true;
    public int strength = 0;
    public bool unsaved = true;
    public bool visible = false;
    public bool preferred_network = false;
    public unowned GenlistItem listitem = null;
    public NetworkStatus status {get; private set; default=NetworkStatus.UNCONNECTED;}
    
    public bool valid_network() {
      return (address!=null);
    }
    public string pretty_string() {
      string enc_str = "";
      if(encryption && (!authentication))
        enc_str = "(enc)";
      else if (encryption && authentication)
        enc_str = "(enc+auth)";
      string status_str = "";
      if (status == NetworkStatus.CONNECTING)
        status_str = "CONNECTING ";
      else if (status == NetworkStatus.CONNECTED)
        status_str = "CONNECTED ";
      return "%s%i%% %s %s".printf(
        status_str, strength, enc_str, essid
      );
      /*return "Address:%s Essid:%s Encryption:%s Strength:%i".printf(
        address, essid, enc_str, strength
      );*/
    }

    public string get_title() {
      return essid;
    }
    
    public void set_new_status(NetworkStatus _status) {
      status = _status;
      update_view();
    }
    public void set_strength(int i, bool update_list=true) {
      strength = i;
      if( update_list )
        update_view();
    }
    public void set_encyption_to_wpa() {
      wpa_encryption = true;
    }
    
    private void update_view() {
      if( listitem!=null )
        listitem.update();
    }
  }
  
  
  const int TIMEOUT_SECONDS = 2;
  const int ZERO_NETWORKS_SCAN_SECONDS = 4;
  const int NONZERO_NETWORKS_SCAN_SECONDS = 20;
  const int CONNECTED_SCAN_SECONDS = 300;
  
  private class WifiThread : GLib.Object {
    static MainLoop loop;
    static DBus.Connection conn;
    //static Manager manager;
    static Usage fso_usage;
    
    static HashMap<string,PreferredNetwork?> preferred_networks;
    static HashMap<string,Network> networks;
    static ArrayList<Network> visible_networks;
    static NetworkStatus status;
    
    static string wireless_interface;
    
    static unowned Network? connection_suggestion;
    static unowned Network? connect_network;
    
    static Regex line_regex_start_address;
    static Regex line_regex_essid;
    static Regex line_regex_encryption;
    static Regex line_regex_strength;
    static Regex line_regex_interface;
    static Regex line_regex_wpa_enc;
    static Regex line_regex_wpa_enc_auth;
    
    static int seconds_since_last_scan;
    
    public static void* run_thread() {
      loop = new MainLoop(null, false);
      
      WifiThread.initialize();
      
      var time = new TimeoutSource.seconds(TIMEOUT_SECONDS);
      time.set_callback(() => {
        if( status == NetworkStatus.UNCONNECTED ) {
          if( networks.size==0 && seconds_since_last_scan>=ZERO_NETWORKS_SCAN_SECONDS ) {
            scan();
          } else if( networks.size>0 && seconds_since_last_scan>=NONZERO_NETWORKS_SCAN_SECONDS ) {
            scan();
          }
          unowned Network? suggestion = suggest_network();
          if( suggestion!=null )
            connect_to_network(suggestion);
        } else if( seconds_since_last_scan>=CONNECTED_SCAN_SECONDS ) {
          scan();
        }
        if( status == NetworkStatus.CONNECT ) {
          run_dhcp();
        }
        seconds_since_last_scan += TIMEOUT_SECONDS;
        return true;
      });
      time.attach(loop.get_context());

      
      loop.run();
      time = null;
      try {
        fso_usage.ReleaseResource("WiFi"); // Turn off wifi
        fso_usage.ReleaseResource("CPU");
      } catch(Error e) {}
      save_preferred_networks();
      return null;
    }
    public static void stop_thread() {
      loop.quit();
    }
    public static Network[] get_visible_networks() {
      Network[] n = new Network[visible_networks.size];
      lock (visible_networks) {
        for(int i = 0; i<visible_networks.size; i++) {
          n[i] = visible_networks.get(i);
        }
      }
      return n;
    }
    public static void preferred_state_change(Network network) {
      if(network.preferred_network) {
        preferred_networks.set(network.address, PreferredNetwork() {
          password = network.password,
          password_in_ascii = network.password_in_ascii, 
          username = network.username,
          cert = network.cert,
          cert_dir = network.cert_dir
        });
      } else {
        if( preferred_networks.has_key(network.address) )
          preferred_networks.unset(network.address);
      }
    }
    public static void preferred_ascii_password_state_change(Network network) {
      if(network.preferred_network)
        preferred_networks.get(network.address).password_in_ascii = network.password_in_ascii;
    }
    public static void preferred_network_password_change(Network network) {
      if(network.preferred_network)
        preferred_networks.get(network.address).password = network.password;
    }
    public static void preferred_network_username_change(Network network) {
      if(network.preferred_network)
        preferred_networks.get(network.address).username = network.username;
    }
    public static void preferred_network_certificate_change(Network network) {
      if(network.preferred_network) {
        preferred_networks.get(network.address).cert = network.cert;
        preferred_networks.get(network.address).cert_dir = network.cert_dir;
      }
    }
    public static void connect_to_network(Network network) {
      disconnect();
      wifi.set_new_status("connecting..");
      connect_network = network;
      network.set_new_status(NetworkStatus.CONNECTING);
      
      DirUtils.create_with_parents(Environment.get_user_config_dir() + "/iliwi",0755);
      string filename = Environment.get_user_config_dir() + "/iliwi/wpa_supplicant.conf";
      string password = network.password;
      if(network.password_in_ascii)
        password = "\""+network.password+"\"";
      var stream = FileStream.open(filename, "w");
      stream.puts( "ctrl_interface=/var/run/wpa_supplicant\n" );
      stream.puts( "network={\n" );
      stream.puts( "  ssid=\"%s\"\n".printf(network.essid) );
    if( network.encryption )
      if ( network.wpa_encryption && (!network.authentication) ) // WPA-Personal
        stream.puts("  psk=%s\n".printf(network.password));
      else if ( network.wpa_encryption && network.authentication ) { // WPA-Enterprise
        stream.puts("  password=\"%s\"\n".printf(network.password));
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
        stream.puts("  wep_key0=%s\n".printf(network.password));
      }
    else
      stream.puts( "  key_mgmt=NONE\n" ); // No encryption
      stream.puts( "}\n" );
      stream.flush();
      stream = null;
      
      try {
        string[] supplicant_args = {Environment.find_program_in_path("wpa_supplicant"),"-i", wireless_interface, "-c", filename,"-B"};
        Process.spawn_sync(null, supplicant_args, null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null);
      } catch(GLib.SpawnError e) {
        debug("Couldn't start spawn!");
      }
      status = NetworkStatus.CONNECT;
    }
    private static void disconnect() {
      status = NetworkStatus.UNCONNECTED;
      try {
        Process.spawn_sync(null, {Environment.find_program_in_path("killall"),"wpa_supplicant"}, null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null);
        FileUtils.remove("/var/run/wpa_supplicant/eth0");
      } catch(GLib.SpawnError e) {
      }
      if( connect_network!=null ) {
        connect_network.set_new_status(NetworkStatus.UNCONNECTED);
        connect_network = null;
      }
    }
    
    private static void run_dhcp() {
      try {
        string udhcpc_result = "";
        Process.spawn_sync(null, {Environment.find_program_in_path("udhcpc"),"-i",wireless_interface,"-n","-R"}, null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null, out udhcpc_result);
        Regex regex_ip = new Regex("""\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}""");
        MatchInfo result;
        if( regex_ip.match(udhcpc_result,0,out result) ) { // We got an ip
          connect_network.set_new_status( NetworkStatus.CONNECTED );
          status = NetworkStatus.CONNECTED;
          wifi.set_new_status("idle");
        }
      } catch(Error e) {
        debug("Couldn't start spawn or regex failed!");
      }
    }
    
    private static void initialize() {
      try {
        conn = DBus.Bus.get (DBus.BusType.SYSTEM);
        fso_usage = (Usage) conn.get_object("org.freesmartphone.ousaged",
                                      "/org/freesmartphone/Usage");
        fso_usage.RequestResource("WiFi"); // Turn on wifi
        fso_usage.RequestResource("CPU");
      } catch(Error e) {
        debug("DBus error!");
      }
      
      try {
        line_regex_start_address = new Regex(""" Address: ([0-9A-Z:]{17})$""");
        line_regex_essid = new Regex("""^\s+ESSID:\"(.*)\"$""");
        line_regex_encryption = new Regex("""^\s+Encryption key:on$""");
        line_regex_strength = new Regex("""^\s+Quality=(\d+)/(\d+) """);
        line_regex_interface = new Regex("""^(\w+\d+)\s*Scan completed :$""");
        line_regex_wpa_enc = new Regex("""^\s+Extra:(rsn|wpa)_ie=""");
        line_regex_wpa_enc_auth = new Regex("""^\s+Extra:wpa_ie=dd160050f20101000050f20201000050f20201000050f201$""");
      } catch(Error e) {
        debug("Regex error!");
      }
      
      networks = new HashMap<string,Network>(str_hash,str_equal);
      visible_networks = new ArrayList<Network>();
      status = NetworkStatus.UNCONNECTED;
      disconnect();
      load_preferred_networks();
      scan();
    }
    
    private static void load_preferred_networks() {
      string filename = Environment.get_user_config_dir() + "/iliwi/preferred_networks";
      var in_stream = FileStream.open(filename, "r");
      string line;
      preferred_networks = new HashMap<string,PreferredNetwork?>(str_hash,str_equal);
      
      try {
        Regex regex_line = new Regex("""^([0-9A-Z:]{17}) \"(.*)\"(h)? \"(.*)\" \"(.*)\" \"(.*)\"$""");
        MatchInfo result;
        
        while( (line=in_stream.read_line())!=null ) {
          if( regex_line.match(line,0,out result) ) { // Parse option
            
            preferred_networks.set(result.fetch(1), PreferredNetwork() {
              password = result.fetch(2),
              password_in_ascii = (result.fetch(3)==null), 
              username = result.fetch(4),
              cert = result.fetch(5),
              cert_dir = result.fetch(6)
            });
          }
        }
      } catch (Error e) {
        // Couldn't parse file
        debug("Couldn't parse the file %s",filename);
      }
    }
    private static void save_preferred_networks() {
      DirUtils.create_with_parents(Environment.get_user_config_dir() + "/iliwi",0755);
      string filename = Environment.get_user_config_dir() + "/iliwi/preferred_networks";
      var stream = FileStream.open(filename, "w");
      foreach(string address in preferred_networks.keys) {
        PreferredNetwork network = preferred_networks.get(address);
        string password_type = network.password_in_ascii ? "" : "h";
        stream.puts( "%s \"%s\"%s \"%s\" \"%s\" \"%s\"\n".printf(address,network.password,password_type,network.username,network.cert,network.cert_dir) );
      }
    }

    private static void scan() {
      wifi.set_new_status("scanning..");
      seconds_since_last_scan = 0;
      string result = "";
      try {
        Process.spawn_sync(null, {Environment.find_program_in_path("iwlist"),"scan"}, null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null, out result);
        parse_iwlist_networks(result);
      } catch(GLib.SpawnError e) {
        debug("Couldn't start spawn!");
      }
      wifi.set_new_status("idle");
      seconds_since_last_scan = 0;
    }
    private static void parse_iwlist_networks(string iwlist_result) {
      string[] lines = iwlist_result.split("\n");
      MatchInfo result;
      Network current_network = null;
      
      lock (visible_networks) {
        foreach(Network n in visible_networks)
          n.set_strength(0,false); 
        visible_networks.clear();
        foreach(string line in lines) {
          if( line_regex_essid.match(line,0,out result) )
            current_network.essid = result.fetch(1);
          else if( line_regex_encryption.match(line,0,out result) )
            current_network.encryption = true;
          else if (line_regex_wpa_enc_auth.match(line,0,out result)) {
            current_network.authentication = true;
            current_network.set_encyption_to_wpa();
          }
          else if( line_regex_wpa_enc.match(line,0,out result) )
            current_network.set_encyption_to_wpa();
          else if( line_regex_strength.match(line,0,out result) ) {
            current_network.set_strength( (int)(result.fetch(1).to_double()/result.fetch(2).to_double()*100) );
          } else if( line_regex_start_address.match(line,0,out result) ) {
            // We start a new. Check an see if the last one was something worth saving
            if( current_network!=null && current_network.valid_network() )
              found_network(current_network);
            //unowned Network lookup = null;// = networks.lookup(result.fetch(1));
            if( networks.has_key(result.fetch(1)) ) {
              current_network = networks.get(result.fetch(1));
            } else {
              current_network = new Network();
              current_network.address = result.fetch(1);
            }
            current_network.visible = true;
          } else if( line_regex_interface.match(line,0,out result) )
            wireless_interface = result.fetch(1);
        }
        if( current_network!=null && current_network.valid_network() )
          found_network(current_network);
      } // End lock
      wifi.visible_network_change(); //TODO check if something actually changed
    }
    private static void found_network(Network network) {
      if( network.unsaved ) {
        network.unsaved = false;
        if( preferred_networks.has_key(network.address) ) {
          network.preferred_network = true;
          connect_to_suggestion(network);
        }
        networks.set( network.address, network );
      }
      visible_networks.add( network ); //TODO sort list (or is this for the view?)
    }
    
    //TODO: Is this obsolete?
    private static void connect_to_suggestion(Network network) {
      // Get password
      if( preferred_networks.has_key(network.address) ) {
        network.password = preferred_networks.get(network.address).password;
        network.password_in_ascii = preferred_networks.get(network.address).password_in_ascii;
        network.username = preferred_networks.get(network.address).username;
        network.cert = preferred_networks.get(network.address).cert;
        network.cert_dir = preferred_networks.get(network.address).cert_dir;
      }
      if( connection_suggestion==null )
        connection_suggestion = network;
      else if( connection_suggestion.strength < network.strength )
        connection_suggestion = network;
     
    }
    
    private static unowned Network? suggest_network() {
      unowned Network? suggestion = null;
      foreach(Network network in networks.values) {
        if( preferred_networks.has_key(network.address) ) {
          if( suggestion == null )
            suggestion = network;
          else {
            if( network.strength > suggestion.strength )
              suggestion = network;
          }
        }
      }
      return suggestion;
    }
  }
}

/*
WEP
                    Extra:bcn_int=100
                    Extra:wmm_ie=dd180050f2020101800003a4000027a4000042435e0062322f00
WPA-PSK
                    Extra:bcn_int=100
                    Extra:wpa_ie=dd180050f20101000050f20201000050f20201000050f2020c00
                    Extra:wmm_ie=dd180050f2020101800003a4000027a4000042435e0062322f00

WPA2-PSK
                    Extra:bcn_int=100
                    Extra:rsn_ie=30140100000fac040100000fac040100000fac020c00
                    Extra:wmm_ie=dd180050f2020101800003a4000027a4000042435e0062322f00
WPA/WPA2-mixed
                    Extra:bcn_int=100
                    Extra:wpa_ie=dd1c0050f20101000050f20202000050f2040050f20201000050f2020c00
                    Extra:rsn_ie=30180100000fac020200000fac04000fac020100000fac020c00
                    Extra:wmm_ie=dd180050f2020101800003a4000027a4000042435e0062322f00
*/

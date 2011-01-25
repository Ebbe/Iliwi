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

namespace WifiScan {
  
  class Iwlist : GLib.Object, Interface {
    private ScanningDone done_callback;
    Regex line_regex_start_address;
    Regex line_regex_essid;
    Regex line_regex_encryption;
    Regex line_regex_strength;
    Regex line_regex_interface;
    Regex line_regex_wpa_enc;
    Regex line_regex_wpa_enc_auth;
    
    public Iwlist() {
      try {
        line_regex_start_address = new Regex(""" Address: ([0-9A-Z:]{17})$""");
        line_regex_essid = new Regex("""^\s+ESSID:\"(.*)\"$""");
        line_regex_encryption = new Regex("""^\s+Encryption key:on$""");
        line_regex_strength = new Regex("""^\s+Quality=(\d+)/(\d+) """);
        line_regex_interface = new Regex("""^(\w+\d+)\s*Scan completed :$""");
        line_regex_wpa_enc = new Regex("""^\s+Extra:(rsn|wpa)_ie=""");
        //line_regex_wpa_enc_auth = new Regex("""^\s+Extra:wpa_ie=dd160050f20101000050f20201000050f20201000050f201$""");
        line_regex_wpa_enc_auth = new Regex("""^\s+Extra:wpa_ie=dd[.]{46}[0]*$""");
      } catch(Error e) {
        critical("Regex error!");
      }
    }

    public void set_done_callback(ScanningDone _done_callback) {
      done_callback = _done_callback;
    }
    
    public void* run() {
      string result = "";
      Network[] networks = {};
      try {
        Process.spawn_sync(null, {Environment.find_program_in_path("iwlist"),"scan"}, null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null, out result);
        //Thread.usleep(2000000); // For debugging on pc with no wifi
        networks = parse_iwlist_networks(result);
      } catch(GLib.SpawnError e) {
        critical("Couldn't start spawn!");
      } finally {
        done_callback(networks);
      }
      return null;
    }
    
    private Network[] parse_iwlist_networks(string iwlist_result) {
      string[] lines = iwlist_result.split("\n");
      MatchInfo result;
      Network current_network = null;
      Network[] networks = {};
      
      foreach(string line in lines) {
        if( line_regex_essid.match(line,0,out result) )
          current_network.essid = result.fetch(1);
        else if( line_regex_encryption.match(line,0,out result) )
          current_network.encryption = true;
        else if (line_regex_wpa_enc_auth.match(line,0,out result)) {
          current_network.authentication = true;
          current_network.wpa_encryption = true;
        }
        else if( line_regex_wpa_enc.match(line,0,out result) )
          current_network.wpa_encryption = true;
        else if( line_regex_strength.match(line,0,out result) ) {
          current_network.strength = (int)(result.fetch(1).to_double()/result.fetch(2).to_double()*100);
        } else if( line_regex_start_address.match(line,0,out result) ) {
          // We start a new. Check an see if the last one was something worth saving
          if( current_network!=null && current_network.valid_network() )
            networks += current_network;
          current_network = new Network();
          current_network.address = result.fetch(1);
        }
      }
      return networks;
    }
  }
}

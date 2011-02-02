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

public delegate void ScanningDone(Network[] networks);
public delegate void SimpleCallback();


class Wifi : GLib.Object {
  public string status {get; private set; default = "loading...";}
  public bool scanning {get; set; default = false;}
  
  static Wifi? instance;
  
  WifiScan.Interface scan_instance;
  WifiConnect.Interface connect_instance;
  Usage fso_usage;
  Networks networks;
  
  public Wifi() {
    notify["scanning"].connect( ()=> { 
      if( scanning )
        status = "scanning...";
      else
        status = "scanning complete";
    });
    
    try {
      fso_usage = Bus.get_proxy_sync (BusType.SYSTEM, "org.freesmartphone.ousaged",
                                    "/org/freesmartphone/Usage");
      fso_usage.RequestResource("WiFi"); // Turn on wifi
      fso_usage.RequestResource("CPU");
    } catch(IOError e) {
      debug("DBus error! I hope you already have wifi turned on then!");
    }
    
    networks = new Networks();
    
    scan_instance = new WifiScan.Iwlist();
    scan_instance.set_done_callback(scan_done);
    connect_instance = new WifiConnect.WpaSupplicant();
    scan();
  }
  
  public static Wifi g() {
    if( instance==null )
      instance = new Wifi();
    return instance;
  }
  
  public void scan() {
    scanning = true;
    try {
      Thread.create<void*>(scan_instance.run, false);
    } catch( GLib.ThreadError e ) {
      critical("Couldn't start thread!");
    }
  }
  
  public void connect_to(Network network) {
    status = "Connecting to %s".printf(network.essid);
    network.status = NetworkStatus.CONNECTING;
    connect_instance.connect_to(network);
  }
  
  public Networks get_networks() {
    return networks;
  }
  
  private void scan_done(Network[] _networks) {
    scanning = false;
    networks.scan_results(_networks);
  }
  
  private void connected_callback() {
    
  }
}

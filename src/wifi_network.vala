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

public enum NetworkStatus {
  UNCONNECTED,
  CONNECTING,
  CONNECTED,
  FAILED
}

public class Network : GLib.Object {
  public string address;
  public string essid = "";
  public bool encryption = false;
  public bool authentication = false;
  public bool wpa_encryption {get; set; default=false;}
  public string cert = "";
  public string cert_dir = "";
  public int strength = 0;
  public bool unsaved = true;
  private string _password = "";
  private int database_id = 0;
  public string password {
    get {return _password;}
    set {_password=value; i_changed();}
  }
  private string _username = "";
  public string username {
    get {return _username;}
    set {_username=value; i_changed();}
  }
  private bool _preferred_network = false;
  public bool preferred_network {
    get {return _preferred_network;}
    set {_preferred_network=value; i_changed();}
  }
  private NetworkStatus _status = NetworkStatus.UNCONNECTED;
  public NetworkStatus status {
    get {return _status;}
    set {_status=value;}
  }
  
  public string human_name() {
    if( essid!="" )
      return essid;
    return "<hidden>";
  }
  
  public bool valid_network() {
    return (address!=null);
  }
  
  public int sortable_num() {
    int result = strength;
    if( preferred_network )
      result += 1000;
    return result;
  }
  
  public void take_attributes_from(Network other_network) {
    essid = other_network.essid;
    strength = other_network.strength;
    encryption = other_network.encryption;
    wpa_encryption = other_network.wpa_encryption;
  }
  
  /* This checks database if we already know it */
  public void check_if_preferred() {
    string[,]? result = Database.get_network_id_password(address);
    if( result==null || result[0,0]==null )
      return;
    database_id = result[0,0].to_int();
    _password = result[0,1];
  }
  
  private void i_changed() {
    debug("esfsef");
  }
}

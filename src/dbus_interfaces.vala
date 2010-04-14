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


[DBus (name = "org.freesmartphone.Usage")]
interface Usage : GLib.Object {
  public abstract void RequestResource(string resource) throws DBus.Error;
  public abstract void ReleaseResource(string resource) throws DBus.Error;
}

/*
[DBus (name = "org.moblin.connman.Manager")]
interface Manager : GLib.Object {
  public abstract HashTable<string,Value?> GetProperties() throws DBus.Error;
  public abstract void RequestScan(string type) throws DBus.Error;
  public abstract DBus.ObjectPath ConnectService(HashTable<string,Value?> network) throws DBus.Error;
}
[DBus (name = "org.moblin.connman.Device")]
interface Device : GLib.Object {
  public abstract HashTable<string,Value?> GetProperties() throws DBus.Error;
}
[DBus (name = "org.moblin.connman.Service")]
interface Service : GLib.Object {
  public abstract HashTable<string,Value?> GetProperties() throws DBus.Error;
}
*/

/*
{
  ‘Type’:’wifi’,
  ‘Mode’:’managed’,
  ‘SSID’:’ssid’,
  ‘Security’:’WEP’,
  ‘Passphrase’:’secret’
}
{   'AutoConnect': True,
    'Favorite': True,
    'IPv4.Method': 'dhcp',
    'Mode': 'managed',
    'Name': 'hvemder.dk',
    'Passphrase': 'ijotnmlb5',
    'PassphraseRequired': False,
    'Security': 'rsn',
    'State': 'failure',
    'Strength': 47,
    'Type': 'wifi'}

*/
/*
HashTable<string,Value?> properties = manager.GetProperties();
      foreach( string key in properties.get_keys()) {
        debug(key);
        if(key=="Devices") {
          Device[] devices = (Device[]) properties.lookup(key);
          debug("Antal s: %i",devices.length);
          foreach(Device device in devices) {
            HashTable<string,Value?> device_properties = device.GetProperties();
            foreach( string key in device_properties.get_keys())
              debug(key);
          }
        }
      }
*/
/*
$ mdbus -s org.moblin.connman / org.moblin.connman.Manager.GetProperties
{   'ActiveProfile': op'/profile/default',
    'AvailableTechnologies': ['wifi'],
    'ConnectedTechnologies': [],
    'Connections': [],
    'DefaultTechnology': '',
    'Devices': [op'/device/0012cf8f1b2d'],
    'EnabledTechnologies': ['wifi'],
    'OfflineMode': False,
    'Profiles': [op'/profile/default'],
    'Services': [   op'/profile/default/wifi_0012cf8f1b2d_6876656d6465722e646b_managed_rsn',
                    op'/profile/default/wifi_0012cf8f1b2d_474c61444f53_managed_wep'],
    'State': 'offline'}
*/
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

class Networks : GLib.Object {
  /* Signal that mostly views should be subscribers to */
  public signal void networks_changed();
  
  HashMap<string,Network> networks;
  
  public Networks() {
    networks = new HashMap<string,Network>(str_hash,str_equal);
  }
  
  public void scan_results(Network[] _networks) {
    foreach( var network in _networks ) {
      if( networks.has_key(network.address) )
        networks.get( network.address ).take_attributes_from(network);
      else {
        network.check_if_preferred();
        networks.set( network.address, network );
      }
    }
    
    networks_changed();
  }
  
  public ArrayList<Network> get_networks() {
    var sorted_list = new ArrayList<Network>();
    foreach( var network in networks.values ) {
      sorted_list.add(network);
    }
    sorted_list.sort_with_data( (a, b)=>{
      return ((Network) b).sortable_num() - ((Network) a).sortable_num();
    });
    return sorted_list;
  }
}

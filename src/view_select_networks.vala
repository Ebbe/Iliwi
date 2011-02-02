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

using Elm;

namespace View {
  public class SelectNetworks : GLib.Object, ViewObject {
    GenlistItemClass itc;
    Box container;
    Genlist genlist;
    Button scanbutton;
    
    Networks networks;
  
    public SelectNetworks(Elm.Object parent) {
      container = new Box(win);
      container.size_hint_weight_set(1, 1);
      container.size_hint_align_set(-1, -1);
      container.homogenous_set(false);
      
      genlist = new Genlist(parent);
      genlist.size_hint_weight_set(1, 1);
      genlist.size_hint_align_set(-1, -1);
      genlist.show();
      container.pack_end(genlist);
      
      scanbutton = new Button(parent);
      scanbutton.label_set("Scan");
      scanbutton.size_hint_weight_set(-1, -1);
      scanbutton.size_hint_align_set(-1, -1);
      scanbutton.show();
      scanbutton.smart_callback_add("clicked", Wifi.g().scan );
      container.pack_end(scanbutton);
      
      Wifi.g().notify["scanning"].connect( ()=> { 
        scanbutton.disabled_set( Wifi.g().scanning );
        refresh_gui();
      });
      scanbutton.disabled_set( Wifi.g().scanning );
      
      itc.item_style = "double_label";
      itc.func.label_get = (GenlistItemLabelGetFunc) get_item_label;
      itc.func.icon_get = null;
      itc.func.state_get = null;
      itc.func.del = null;
      
      Networks networks = Wifi.g().get_networks();
      show_networks(networks);
      networks.networks_changed.connect(show_networks);
    }
    
    public unowned Elm.Object get_object() {
      return container;
    }
    
    void show_networks(Networks networks_instance) {
      networks = networks_instance;
      (void) new Ecore.Idler(show_networks_in_ecore_thread);
    }
    
    bool show_networks_in_ecore_thread() {
      genlist.clear();
      var networks_array = networks.get_networks();
      foreach( var network in networks_array )
        genlist.item_append(itc, (void*)network, null, GenlistItemFlags.NONE, network_select);
      return false;
    }
    
    static string? get_item_label(void *data, Elm.Object? obj, string part) {
      Network network = (Network) data;
      if (part == "elm.text") {
        return "%d%% %s".printf(network.strength, network.human_name());
      } else if (part == "elm.text.sub") {
        string enc_str = "";
        if(network.encryption && (!network.authentication))
          enc_str = "(enc)";
        else if (network.encryption && network.authentication)
          enc_str = "(enc+auth)";
        string status_str = "";
        if (network.status == NetworkStatus.CONNECTING)
          status_str = "CONNECTING ";
        else if (network.status == NetworkStatus.CONNECTED)
          status_str = "CONNECTED ";
        return "%s %s".printf(
          status_str, enc_str
        );
      } else {
        return null;
      }
    }
    
    void network_select( Evas.Object obj, void* event_info) {
      unowned GenlistItem item = (GenlistItem)event_info;
      Network clicked = (Network) item.data_get();
      show_network(clicked);
      item.selected_set(false);
    }
  }
}

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
  public class ViewNetwork : GLib.Object, ViewObject {
    Network network;
    unowned Elm.Object parent;
    
    Box outer_box;
    Entry username;
    Entry password;
    Label cert_status;
    Toggle preferred;
    Button connect_button;
    
    Elm.Object[] gui_container;
  
    public ViewNetwork(Elm.Object _parent) {
      parent = _parent;
    }
    
    public void set_network(Network _network) {
      network = _network;
      generate_view();
    }
    
    void generate_view()
        requires (network!=null) {
      outer_box = new Box(parent);
      outer_box.homogenous_set(false);
      outer_box.size_hint_weight_set(1, 1);
      outer_box.size_hint_align_set(-1, -1);
      outer_box.show();
      
      Scroller sc = new Scroller(parent);
      sc.bounce_set(false, false);
      sc.policy_set(Elm.ScrollerPolicy.OFF, Elm.ScrollerPolicy.AUTO);
      sc.size_hint_weight_set(1, 1);
      sc.size_hint_align_set(-1, -1);
      outer_box.pack_end(sc);
      sc.show();

      Box network_page = new Box(parent);
      network_page.homogenous_set(false);
      network_page.size_hint_weight_set(1, 1);
      network_page.size_hint_align_set(-1, -1);
      sc.content_set(network_page);
      network_page.show();

      Frame title_padding = new Frame(parent);
      title_padding.style_set("pad_small");
      title_padding.size_hint_weight_set(1, 1);
      title_padding.size_hint_align_set(0.5, 0.5);
      title_padding.show();

      Label title = new Label(parent);
      title.size_hint_weight_set(1, 1);
      title.size_hint_align_set(0.5, 0.5);
      title.scale_set(1.7);
      title.label_set(network.human_name());
      title.show();
      title_padding.content_set(title);
      gui_container += (owned) title;

      network_page.pack_end(title_padding);
      gui_container += (owned) title_padding;

      if(network.authentication) {
        Frame username_container = new Frame(parent);
        username_container.label_set("Username");
        username_container.size_hint_weight_set(1, -1);
        username_container.size_hint_align_set(-1, -1);
        username = new Entry(parent);
        username.single_line_set(true);
        username.entry_insert(network.username);
        username.show();
        username_container.content_set(username);
        username.smart_callback_add("changed", ()=>{network.username=username.entry_get();});
        username_container.show();
        network_page.pack_end(username_container);
        gui_container += (owned) username_container;
      }

      if(network.encryption) {
        Frame password_container = new Frame(parent);
        password_container.label_set("Password");
        password_container.size_hint_weight_set(1, -1);
        password_container.size_hint_align_set(-1, -1);
        password = new Entry(parent);
        password.single_line_set( true );
        password.entry_insert(network.password);
        password.show();
        password.smart_callback_add("unfocused", password_changed);
        password_container.content_set(password);
        password_container.show();
        network_page.pack_end(password_container);
        gui_container += (owned) password_container;
        
        /*if(!network.authentication) {
          Toggle ascii_hex = new Toggle(parent);
          ascii_hex.label_set("Password format");
          ascii_hex.states_labels_set("ASCII","Hex");
          ascii_hex.smart_callback_add("changed", change_network_ascii_hex );
          ascii_hex.state_set(network.password_in_ascii);
          ascii_hex.show();
          network_page.pack_end(ascii_hex);
          gui_container += (owned) ascii_hex;
        }*/
      }

      if(network.authentication) {
        Frame certificate_container = new Frame(parent);
        certificate_container.label_set("Server Certificate");
        certificate_container.size_hint_weight_set(1, -1);
        certificate_container.size_hint_align_set(-1, -1);
        certificate_container.show();
   
        Box cert_box = new Box(parent);
        cert_box.homogenous_set(false);
        cert_box.size_hint_weight_set(1,-1);
        cert_box.size_hint_align_set(-1, -1);
        cert_box.show();
        certificate_container.content_set(cert_box);

        cert_status = new Label(parent);
        cert_status.size_hint_weight_set(1, 1);
        cert_status.size_hint_align_set(-1, -1);
        //certlist_label_set();
        cert_status.show();
        cert_box.pack_end(cert_status);

        Box cert_button_box = new Box(parent);
        cert_button_box.horizontal_set(true);
        cert_button_box.homogenous_set(false);
        cert_button_box.size_hint_weight_set(1, -1);
        cert_button_box.size_hint_align_set(-1, -1);
        cert_button_box.show();

        Button cert_add_button = new Button(parent);
        cert_add_button.size_hint_weight_set(1, 1);
        cert_add_button.size_hint_align_set(-1, -1);
        cert_add_button.label_set("Select");
        cert_add_button.show();
        cert_button_box.pack_end(cert_add_button);
        //cert_add_button.smart_callback_add("clicked", show_cert_chooser);
        gui_container += (owned) cert_add_button;

        Button cert_del_button = new Button(parent);
        cert_del_button.size_hint_weight_set(1, 1);
        cert_del_button.size_hint_align_set(-1, -1);
        cert_del_button.label_set("Clear");
        cert_del_button.show();
        cert_button_box.pack_end(cert_del_button);
        //cert_del_button.smart_callback_add("clicked", clear_cert);
        gui_container += (owned) cert_del_button;

        cert_box.pack_end(cert_button_box);
        gui_container += (owned) cert_button_box;

        network_page.pack_end(certificate_container);
        gui_container += (owned) cert_box;
        gui_container += (owned) certificate_container;
      }

      preferred = new Toggle(parent);
      preferred.smart_callback_add("changed", ()=>{
        network.preferred_network = preferred.state_get();
      });
      preferred.label_set( "Prefered network");
      preferred.states_labels_set("Yes","No");
      preferred.state_set(network.preferred_network);
      preferred.show();
      network_page.pack_end(preferred);
      
      connect_button = new Button(parent);
      connect_button.size_hint_weight_set(1,-1);
      connect_button.size_hint_align_set(-1,-1);
      connect_button.label_set("Connect");
      refresh_connect_button();
      network.notify["status"].connect( ()=> { 
        refresh_connect_button();
      });
      connect_button.show();
      connect_button.smart_callback_add("clicked", connect_to );
      network_page.pack_end(connect_button);
      
      Button back_button = new Button(parent);
      back_button.size_hint_weight_set(1,-1);
      back_button.size_hint_align_set(-1,-1);
      back_button.label_set("Back");
      back_button.show();
      back_button.smart_callback_add("clicked", close_show_network );
      outer_box.pack_end(back_button);
      gui_container += (owned) back_button;

      gui_container += (owned) sc;
      gui_container += (owned) network_page;
    }
    
    public unowned Elm.Object get_object()
        requires (outer_box!=null) {
      return outer_box;
    }
    
    private void password_changed() {
      network.password = password.entry_get();
    }
    
    private void refresh_connect_button() {
      connect_button.disabled_set(network.status!=NetworkStatus.UNCONNECTED);
      refresh_gui();
    }
    
    private void connect_to() {
      Wifi.g().connect_to(network);
    }
  }
}
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

namespace iliwi.View {
  Win win;
  Elm.Object[] gui_container;
  Pager pager;
  Box frontpage;
  Label status;
  Button button;
  
  Genlist wifilist;
  GenlistItemClass itc;
  bool items_in_list;
  
  void show_main_window(string[] args) {
    Elm.init(args);
    
    gui_container = {};
    items_in_list = false;
    
    //itc.item_style = "double_label";
    itc.item_style = "default";
    itc.func.label_get = genlist_get_label;
    itc.func.icon_get = null;
    itc.func.state_get = null;
    itc.func.del = null;
    
    generate_window();
    
    wifi.status_change.connect((t) => {
      status.label_set(wifi.status);
    });
    wifi.network_list_change.connect((t) => {
      button.disabled_set(false);
      if( items_in_list==false ) {
        refresh_list_elements();
      }
    });
    
    
    //Ecore.MainLoop.begin();
    Elm.run();
    Elm.shutdown();
    //Ecore.MainLoop.quit();
  }
  
  private void generate_window() {
    win = new Win(null, "main", WinType.BASIC);
    win.title_set("iliwi");
    win.smart_callback_add("delete-request", close_window_event );
    
    Bg bg = new Bg(win);
    bg.size_hint_weight_set(1, 1);
    bg.show();
    win.resize_object_add(bg);
    gui_container += (owned) bg;
    
    pager = new Pager(win);
    pager.size_hint_weight_set(1, 1);
    pager.size_hint_align_set(-1, -1);
    pager.show();
    
    frontpage = new Box(win);
    frontpage.size_hint_weight_set(1, 1);
    frontpage.size_hint_align_set(-1, -1);
    frontpage.homogenous_set(false);
    frontpage.show();
    
    wifilist = new Genlist(win);
    wifilist.size_hint_weight_set(1, 1);
    wifilist.size_hint_align_set(-1, -1);
    refresh_list_elements();
    wifilist.show();
    frontpage.pack_end(wifilist);
    
    Box box = new Box(win);
    box.horizontal_set(true);
    box.homogenous_set(false);
    box.size_hint_weight_set(1,-1);
    box.size_hint_align_set(-1, -1);
    box.show();

    status = new Label(win);
    status.size_hint_weight_set(0, 0);
    status.size_hint_align_set(0.5, 0.5);
    status.label_set(wifi.status);
    status.show();
    box.pack_end(status);
    
    button = new Button(win);
    button.label_set("Refresh list");
    button.disabled_set(true);
    button.show();
    button.smart_callback_add("clicked", refresh_list_elements );
    box.pack_end(button);
    
    frontpage.pack_end(box);
    gui_container += (owned) box;
    
    pager.content_push(frontpage);
    
    win.resize_object_add(pager);
    win.show();
  }
  
  private void close_window_event() {
    Elm.exit();
  }
  
  private void refresh_list_elements() {
    wifilist.clear();
    items_in_list = false;
    unowned GenlistItem listitem_tmp;
    GenlistItem listitem_tmp2;
    foreach(Network network in wifi.get_visible_networks()) {
      // Find place (sorted by preferred > strength
      if( items_in_list == false )
        network.listitem = wifilist.item_append( itc, (void*)network, null, Elm.GenlistItemFlags.NONE, item_select );
      else {
        listitem_tmp = wifilist.first_item_get();
        Network list_network = (Network) listitem_tmp.data_get();
        bool found_place = false;
        while(found_place == false) {
          if( network.preferred_network && list_network.preferred_network==false ) {
            found_place = true;
            network.listitem = wifilist.item_insert_before( itc, (void*)network, listitem_tmp, Elm.GenlistItemFlags.NONE, item_select );
          } else if( list_network.preferred_network==network.preferred_network && list_network.strength<=network.strength ) {
            found_place = true;
            network.listitem = wifilist.item_insert_before( itc, (void*)network, listitem_tmp, Elm.GenlistItemFlags.NONE, item_select );
          } else { // Couldn't find a place to put it
            listitem_tmp2 = listitem_tmp.next_get();
            listitem_tmp = listitem_tmp2;
            if( listitem_tmp==null ) {
              found_place = true;
              network.listitem = wifilist.item_append( itc, (void*)network, null, Elm.GenlistItemFlags.NONE, item_select );
            } else
              list_network = (Network) listitem_tmp.data_get();
          }
        }
      }
      items_in_list = true;
      button.disabled_set(true);
    }
  }
  
  
  Elm.Object[] gui_container2;
  Entry password;
  Entry username;
  unowned Network network;
  //Box network_page;
  private void show_network(Network _network) {
    gui_container2 = {};
    network = _network; 
    
    Box network_page = new Box(win);
    network_page.homogenous_set(false);
    network_page.size_hint_weight_set(1, 1);
    network_page.size_hint_align_set(-1, -1);
    network_page.show();

    Label title = new Label(win);
    title.size_hint_weight_set(1,1);
    title.scale_set(2);
    title.label_set(network.get_title());
    title.show();
    network_page.pack_end(title);
    gui_container2 += (owned) title;
    
    if(network.authentication) {
      Frame username_container = new Frame(win);
      username_container.label_set("Username");
      username_container.size_hint_weight_set(1, -1);
      username_container.size_hint_align_set(-1, -1);
      username = new Entry(win);
      username.single_line_set(true);
      username.entry_insert(network.username);
      username.show();
      username_container.content_set(username);
      username_container.show();
      network_page.pack_end(username_container);
      gui_container2 += (owned) username_container;
    }

    if(network.encryption) {
      Frame password_container = new Frame(win);
      password_container.label_set("Password");
      password_container.size_hint_weight_set(1, -1);
      password_container.size_hint_align_set(-1, -1);
      password = new Entry(win);
      password.single_line_set( true );
      password.entry_insert(network.password);
      password.show();
      password_container.content_set(password);
      password_container.show();
      network_page.pack_end(password_container);
      gui_container2 += (owned) password_container;
      
      if(!network.authentication) {
        Toggle ascii_hex = new Toggle(win);
        ascii_hex.label_set( "Password written in");
        ascii_hex.states_labels_set("Ascii","Hex");
        ascii_hex.smart_callback_add("changed", change_network_ascii_hex );
        ascii_hex.state_set(network.password_in_ascii);
        ascii_hex.show();
        network_page.pack_end(ascii_hex);
        gui_container2 += (owned) ascii_hex;
      }
    }
    
    Toggle preferred = new Toggle(win);
    preferred.smart_callback_add("changed", change_network_preferred );
    preferred.label_set( "Preferred network");
    preferred.states_labels_set("Yes","No");
    preferred.state_set(network.preferred_network);
    preferred.show();
    network_page.pack_end(preferred);
    gui_container2 += (owned) preferred;
    
    Button button = new Button(win);
    button.size_hint_weight_set(1,-1);
    button.size_hint_align_set(-1,-1);
    button.label_set("Connect");
    button.disabled_set(network.status!=NetworkStatus.UNCONNECTED);
    button.show();
    button.smart_callback_add("clicked", connect_to );
    network_page.pack_end(button);
    gui_container2 += (owned) button;
    
    button = new Button(win);
    button.size_hint_weight_set(1,-1);
    button.size_hint_align_set(-1,-1);
    button.label_set("Back");
    button.show();
    button.smart_callback_add("clicked", back_to_list );
    network_page.pack_end(button);
    gui_container2 += (owned) button;
    
    pager.content_push(network_page);
    gui_container2 += (owned) network_page;
  }
  private void save_password() {
    if (network.encryption) {
      network.password = password.entry_get();
      if (network.authentication)
        network.username = username.entry_get();
      if (network.preferred_network) {
        wifi.preferred_network_password_change(network);
        wifi.preferred_network_username_change(network);
        wifi.preferred_network_certificate_change(network);
      }
    }
  }
  private void change_network_ascii_hex(Evas.Object obj, void* event_info) {
    bool current_state = ((Toggle)obj).state_get();
    if( current_state!=network.password_in_ascii )
      wifi.set_ascii_state(network,current_state);
  }
  private void change_network_preferred(Evas.Object obj, void* event_info) {
    save_password();
    bool current_state = ((Toggle)obj).state_get();
    if( current_state!=network.preferred_network )
      wifi.set_preferred_state(network,current_state);
  }
  private void connect_to() {
    save_password();
    wifi.connect_to(network);
    back_to_list();
  }
  private void back_to_list() {
    save_password();
    refresh_list_elements();
    pager.content_pop();
    gui_container2 = {};
    password = null;
    username = null;
  }
  
  
  // Genlist stuff
  private static string genlist_get_label( Elm.Object obj, string part ) {
    /*if( strcmp(part,"elm.text")==0 )
      return "elm.text";
    if( strcmp(part,"elm.text.sub")==0 )
      return "elm.text.sub";*/
    return ((Network)obj).pretty_string();
  }
  public void item_select( Evas.Object obj, void* event_info) {
    Network clicked = (Network) ((GenlistItem)event_info).data_get();
    show_network(clicked);
    //debug( "clicked %s", clicked.pretty_string() );
  }

}

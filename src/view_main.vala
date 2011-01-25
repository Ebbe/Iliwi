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
  public interface ViewObject : GLib.Object {
    public abstract unowned Elm.Object get_object();
  }

  Bg bg;
  Win win;
  Box frontpage_container;
  Pager pager;
  Label status;
  
  ViewObject select_networks;
  ViewObject view_network;
  
  void show_main_window(string[] args) {
    Elm.init(args);
    Ecore.MainLoop.glib_integrate();
    
    generate_window();
    connect_to_signals();
    
    select_networks = new SelectNetworks(win);
    pager.content_push(select_networks.get_object());
    
    Ecore.MainLoop.begin();
    //Elm.run();
    Elm.shutdown();
  }
  
  private void generate_window() {
    win = new Win(null, "main", WinType.BASIC);
    win.title_set("iliwi");
    win.smart_callback_add("delete-request", Elm.exit );
    
    bg = new Bg(win);
    bg.size_hint_weight_set(1, 1);
    bg.show();
    win.resize_object_add(bg);
    
    frontpage_container = new Box(win);
    frontpage_container.size_hint_weight_set(1, 1);
    frontpage_container.size_hint_align_set(-1, -1);
    frontpage_container.homogenous_set(false);
    frontpage_container.show();
    
    pager = new Pager(win);
    pager.size_hint_weight_set(1, 1);
    pager.size_hint_align_set(-1, -1);
    pager.show();
    frontpage_container.pack_end(pager);
    
    status = new Label(win);
    status.size_hint_weight_set(0, 0);
    status.size_hint_align_set(0.5, 0.5);
    status.label_set(Wifi.g().status);
    status.show();
    frontpage_container.pack_end(status);
    
    win.resize_object_add(frontpage_container);
    win.show();
  }
  
  private void connect_to_signals() {
    Wifi.g().notify["status"].connect( ()=> { 
      status.label_set(Wifi.g().status);
      refresh_gui();
    });
  }
  
  private void close_show_network() {
    pager.content_pop();
    view_network = null;
  }
  
  private void show_network(Network network) {
    view_network = new ViewNetwork(win);
    ((ViewNetwork)view_network).set_network(network);
    pager.content_push(view_network.get_object());
  }
  
  /* Make sure the gui is refreshed when updated
   * from a background thread.
   */
  private async void refresh_gui() {
    MainContext m = MainContext.default();
    m.wakeup();
  }
  
}

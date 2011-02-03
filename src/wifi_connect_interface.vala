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

namespace WifiConnect {
  public delegate void ConnectionDone(bool successful, string? ip);
  
  public interface Interface : GLib.Object {
    public abstract void set_connection_done_callback(ConnectionDone _cd);
    public abstract void connect_to(Network _network);
    public abstract void disconnect_from_network();
  }
}

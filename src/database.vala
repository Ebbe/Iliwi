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


static class Database {
  static bool initialized = false;
  static Sqlite.Database database;
  const string DB_VERSION = "1";
  
  private static void initialize() {
  	if( initialized )
  	  return;
  	initialized = true;
  	string database_file = Environment.get_user_config_dir() + "/iliwi/database.sqlite";
  	Sqlite.Database.open(database_file, out database);
  	string[,] version = query("SELECT value FROM version");
    if( version==null || version[0,0]==null )
      create_db(database_file);
    /*else if( version[0,0]!=DB_VERSION )
      migrate_db(version[0,0]);*/
  }
  
  public static string[,]? get_network_id_password(string address) {
    return query("SELECT id,password FROM networks WHERE address=\"%s\";".printf(address));
  }
  
  public static void save_network(int id, string essid, string address, string password) {
  	critical("NOT IMPLEMENTED");
  }
  
  private static void create_db(string db_file) {
    stdout.printf("Couldn't find database file, so we are creating it.\n");
  	FileUtils.remove(db_file); // Just to be sure
    Sqlite.Database.open(db_file,out database);
    database.exec ("""
                      CREATE TABLE networks (id INTEGER PRIMARY KEY, essid, address, password);
                      CREATE INDEX addresses ON networks (address ASC);
                      
                      CREATE TABLE version (value TEXT);
                      
                      INSERT INTO version (value) VALUES ("%s");
                   """.printf(DB_VERSION) ,
                   null, null);
  }
  
  /* This queries the database and returns result as 2d array or null */
  public static string[,]? query(string sql) {
    initialize();
    Sqlite.Statement stmt;
    if( database.prepare_v2 (sql, -1, out stmt, null) != Sqlite.OK ) {
      debug("SQL sentence \"%s\" failed.",sql);
      return null;
    }
    int cols = stmt.column_count();
    int rc=0, current_row=0, rows=0;
    while(stmt.step()==Sqlite.ROW)
      rows++;
    string[,] result = new string[rows,cols];
    
    stmt.reset();
    do {
      rc = stmt.step();
      switch (rc) {
      case Sqlite.DONE:
          break;
      case Sqlite.ROW:
        for (int col = 0; col < cols; col++) {
          result[current_row,col] = stmt.column_text(col);
        }
        current_row++;
        break;
      default:
        printerr ("Error: %d, %s\n", rc, database.errmsg ());
        break;
      }
    } while (rc == Sqlite.ROW);
    return result;
  }
}

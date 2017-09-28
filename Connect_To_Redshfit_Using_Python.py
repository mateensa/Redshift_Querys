import psycopg2

class DEV_Connect:

    _db_connection = None
    _db_cur = None

    def __init__(self):
        try:
            self._db_connection = psycopg2.connect("dbname=xxx user=xxxxxxx host=xxxxxxx password=xxxxxx port=xxxx")
            print("Connected to DB Instance");
            self._db_cur = self._db_connection.cursor();
        except:
            print("Unable to connect to the database");

    def query(self, query):
        return self._db_cur.execute(query)

    def fetchall(self):
        return self._db_cur.fetchall()

    def __del__(self):
        self._db_connection.close()


cursor = DEV_Connect();
cursor.query("SELECT * FROM stv_recents WHERE status = 'Running' order by starttime desc ");
print(cursor.fetchall());

from hdbcli import dbapi
import logging


class CustomSap:
    def __init__(self):
        self._conn = None
        self.logger = logging.getLogger(__name__)

    def custom_connector(self, credentials):
        self._conn = dbapi.connect(
            address=credentials["address"],
            port="443",
            user=credentials["user"],
            password=credentials["password"],
        )
        self.logger.info("Connected")

    def custom_query(self, query):
        cursor = self._conn.cursor()
        # cursor.execute("SELECT * FROM tables")
        cursor.execute(query)
        rows = cursor.fetchall()
        cursor.close()
        return rows

    def custom_close_connection(self):
        self._conn.close()

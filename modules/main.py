import pymysql
import pymysql.cursors

from flask import Flask, session as Session, request

app = Flask(__name__)

class XcloutDbConn:
    databaseConnection = None

    def __init__(self) -> None:
        try:
            self.databaseConnection = pymysql.connect(
                host="localhost",
                password="",
                port=3306,
                user="root",
                db="xclout",
                cursorclass=pymysql.cursors.DictCursor
            )
            self.tcursor = self.databaseConnection.cursor()
        except pymysql.MySQLError as e:
            print(f"Error connecting to MySQL Platform: {e}")
            self.databaseConnection = None

   # Check if connection is alive
    def is_connected(self) -> bool:
        if self.databaseConnection is None:
            # No connection
            return False
        else:
            try:
                # Ping the server
                self.databaseConnection.ping(reconnect=True)
                return True
            except pymysql.MySQLError as e:
                # Connection lost
                print(f"Lost connection to MySQL Platform: {e}")
                return False   
            
    # Our Fake Cursour reffer back to object
    def cursor(self):
        if self.is_connected():
            # Connection is alive
            return self;
        else:
            return None
        
    # Execute a query     
    def execute(self, sql, params=None) -> int:
        if self.is_connected():
            # Connection is alive
            try:
                return self.tcursor.execute(sql, params)
            except pymysql.MySQLError as e:
                print(f"Error executing query: {e}")
                return None
        else:
            return None
        
    # Execute a query and return one row
    def fetchone(self, sql, params=None) -> dict:
        self.execute(sql, params)
        if self.tcursor is not None:
            return self.tcursor.fetchone()
        else:
            return None
        
    # Execute a query and return all rows
    def fetchall(self, sql, params=None) -> list:
        self.execute(sql, params)
        if self.tcursor is not None:
            return self.tcursor.fetchall()
        else:
            return None
    
    # commit changes to the database
    def commit(self) -> None:
        if self.is_connected():
            try:
                self.databaseConnection.commit()
            except Exception as e:
                print(f"Error committing transaction: {e}")
        else:
            print("No connection to MySQL Platform")

    # Close the connection
    def close(self) -> None:
        if self.is_connected():
            try:
                self.databaseConnection.close()
            except Exception as e:
                print(f"Error closing connection: {e}")
        else:
            print("No connection to MySQL Platform")

    
databaseConnection = XcloutDbConn()

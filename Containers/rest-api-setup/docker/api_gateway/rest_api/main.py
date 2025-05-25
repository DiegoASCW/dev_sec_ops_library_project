import pymysql
pymysql.install_as_MySQLdb()

from flask import Flask, request, redirect, url_for, session, send_from_directory, render_template
from authlib.integrations.flask_client import OAuth
import MySQLdb

app = Flask(__name__)

mydb = MySQLdb.connect(
    host="10.0.74.11",
    database="openshelf",
    user="root",
    password="passwd"
)

@app.route('/')
def index():
    mycursor = mydb.cursor()
    mycursor.execute("SELECT * FROM tblstudents")
    myresult = mycursor.fetchall()
    
    return f"<h1>Clientes</h1><pre>{myresult}</pre>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

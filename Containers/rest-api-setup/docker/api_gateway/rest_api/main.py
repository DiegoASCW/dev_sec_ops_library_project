import pymysql
pymysql.install_as_MySQLdb()

from flask import Flask, request, redirect, url_for, session, send_from_directory, render_template
from authlib.integrations.flask_client import OAuth
import MySQLdb

app = Flask(__name__)

mydb: MySQLdb

@app.route('/')
def index():
    mycursor = mydb.cursor()
    mycursor.execute("SELECT * FROM tblstudents")
    myresult = mycursor.fetchall()
    
    return f"<h1>Clientes</h1><pre>{myresult}</pre>"


# realiza tentativas de conexão com o banco
# Gambiarra necessária, dado que script cria container de API Gateway
#   sem necessariamente validar se MySQL está OK.
#   Mantido assim por causa de ganho de performance no setup
def main() -> None:
    global mydb
    
    while True:
        try:
            mydb = MySQLdb.connect(
            host="10.0.74.11",
            database="openshelf",
            user="root",
            password="passwd"
            )
            break
        except:
            pass


if __name__ == '__main__':
    main()
    app.run(host='0.0.0.0', port=5000, debug=True)

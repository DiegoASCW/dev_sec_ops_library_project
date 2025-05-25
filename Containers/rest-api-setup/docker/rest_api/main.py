import pymysql
pymysql.install_as_MySQLdb()

from flask import Flask, request, redirect, url_for, session, send_from_directory, render_template
from authlib.integrations.flask_client import OAuth
import MySQLdb  # agora funcionando graças ao pymysql

app = Flask(__name__)

# Conexão com o MySQL
mydb = MySQLdb.connect(
    host="10.0.74.11",
    database="openshelf",
    user="root",
    password="passwd"
)

# Página inicial servida de /
@app.route('/')
def index():
    mycursor = mydb.cursor()
    mycursor.execute("SELECT * FROM customers")
    myresult = mycursor.fetchall()
    
    # Simples retorno de dados (ou substitua por render_template)
    return f"<h1>Clientes</h1><pre>{myresult}</pre>"

# Roda o servidor Flask
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

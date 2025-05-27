import pymysql
pymysql.install_as_MySQLdb()

from flask import Flask, request, redirect, url_for, session, send_from_directory, render_template, jsonify
from authlib.integrations.flask_client import OAuth
import MySQLdb

app = Flask(__name__)

mydb: MySQLdb


@app.route('/auth/admin', methods=['POST'])
def auth():
    data = request.get_json()
    return jsonify(data)

    mycursor = mydb.cursor()
    mycursor.execute("SELECT * FROM tblstudents")
    myresult = mycursor.fetchall()

    result: bool = (True if myresult != () else False)

    return {"result": result}


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

import pymysql
pymysql.install_as_MySQLdb()

from flask import Flask, request, redirect, url_for, session, send_from_directory, render_template, jsonify
from authlib.integrations.flask_client import OAuth
import MySQLdb

app = Flask(__name__)

mydb: MySQLdb


@app.route('/auth/admin', methods=['POST'])
def auth_admin():
    data = request.get_json()
    
    auth_result: bool

    mycursor = mydb.cursor()
    
    sql = "SELECT * FROM admin WHERE FullName = %s AND Password = %s"
    values = (data["FullName"], data["Passwd"])
    
    mycursor.execute(sql, values)
    myresult = mycursor.fetchall()

    auth_result: bool = (True if myresult != () else False)

    return jsonify({"Result": f"{auth_result}"})


@app.route('/auth/user', methods=['POST'])
def auth_user():
    data = request.get_json()
    
    auth_result: bool

    mycursor = mydb.cursor()
    
    sql = "SELECT * FROM tblstudents WHERE EmailId = %s AND Password = %s AND Status = 1"
    values = (data["Email"], data["Passwd"])
    
    mycursor.execute(sql, values)
    myresult = mycursor.fetchall()

    auth_result: bool = (True if myresult != () else False)

    return jsonify({"Result": f"{auth_result}"})


# realiza tentativas de conexão com o banco
# Gambiarra necessária, dado que script cria container de API Gateway
#   sem necessariamente validar se MySQL está OK.
#   Mantido assim por causa de ganho de performance no setup
def main() -> None:
    global mydb
    
    while True:
        try:
            mydb = MySQLdb.connect(
            host="10.100.4.10",
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

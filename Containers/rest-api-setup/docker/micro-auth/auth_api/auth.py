import pymysql
pymysql.install_as_MySQLdb()

from flask import Flask, request, jsonify
from authlib.integrations.flask_client import OAuth

app = Flask(__name__)

mydb: pymysql.connections.Connection  


@app.route('/auth/admin', methods=['POST'])
def auth_admin():
    data = request.get_json()
    
    auth_result: bool

    mycursor = mydb.cursor()
    sql = "SELECT CAST(AES_DECRYPT(UNHEX(UserName), 'devsecops') AS CHAR) AS UserName  FROM admin WHERE UserName = HEX(AES_ENCRYPT(%s, 'devsecops')) and Password = %s;"

    values = (data["Username"], data["Passwd"])
    
    mycursor.execute(sql, values)
    myresult = mycursor.fetchall()

    # commit para forçar o fim da transação, mesmo que SELECT
    mydb.commit()  

    auth_result: bool = (True if myresult != () else False)

    return jsonify({"Result": f"{auth_result}"})


@app.route('/auth/user', methods=['POST'])
def auth_user():
    data = request.get_json()
    
    auth_result: bool

    mycursor = mydb.cursor()
    
    sql = "SELECT StudentId, Status, CAST(AES_DECRYPT(UNHEX(EmailId), 'devsecops') AS CHAR) AS EmailId FROM tblstudents WHERE EmailId = HEX(AES_ENCRYPT(%s, 'devsecops')) and Password = %s"

    values = (data["Email"], data["Passwd"])

    mycursor.execute(sql, values)
    myresult = mycursor.fetchall()

    # commit para forçar o fim da transação, mesmo que SELECT
    mydb.commit()  

    auth_result: bool = (True if myresult != () else False)

    if auth_result == True:
        StudentId, Status, EmailId = myresult[0]
        return jsonify({"Result": f"{auth_result}", "StudentId": f"{StudentId}", "Status": f"{Status}", "EmailId": f"{EmailId}"})
    else:
        return jsonify({"Result": f"{auth_result}"})


# realiza tentativas de conexão com o banco
# Gambiarra necessária, dado que script cria container de API Gateway
#   sem necessariamente validar se MySQL está OK.
#   Mantido assim por causa de ganho de performance no setup
def main() -> None:
    global mydb
    
    while True:
        try:
            mydb = pymysql.connect(
            host="10.100.14.10",
            database="openshelf",
            user="root",
            password="passwd"
            )
            break
        except:
            pass


if __name__ == '__main__':
    main()
    app.run(host='0.0.0.0', port=5001, debug=True)

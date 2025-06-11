import pymysql
pymysql.install_as_MySQLdb()

from flask import Flask, request, jsonify
from authlib.integrations.flask_client import OAuth

app = Flask(__name__)

mydb: pymysql.connections.Connection


@app.after_request
def add_header(r):
    """ inibe a criação de cache """
    r.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    r.headers["Pragma"] = "no-cache"
    r.headers["Expires"] = "0"
    r.headers['Cache-Control'] = 'public, max-age=0'
    return r


@app.route('/author/list', methods=['GET'])
def author_list():

    auth_result: bool

    mycursor = mydb.cursor()
    sql = "SELECT * from tblauthors"

    mycursor.execute(sql)
    myresult = mycursor.fetchall()

    # commit para forçar o fim da transação, mesmo que SELECT
    mydb.commit()  

    auth_result: bool = (True if myresult != () else False)

    authors = []
    for author in myresult:
            id, AuthorName, creationDate, UpdationDate = author
            authors.append({
                "id": id,
                "AuthorName": AuthorName,
                "creationDate": creationDate,
                "UpdationDate": UpdationDate
            })

    if auth_result:
        return authors
    
    return jsonify({"Result": f"{auth_result}"})


@app.route('/author/register', methods=['POST'])
def author_register():
    data = request.get_json()

    mycursor = mydb.cursor()
    
    sql = "INSERT INTO tblauthors (AuthorName) VALUES (%s)"
    values = (data["AuthorName"])
    
    # executa a query
    mycursor.execute(sql, values)
    
    # commit para forçar o fim da transação, mesmo que SELECT
    mydb.commit()  
    
    return jsonify({"Result": "True", "AuthorName": data["AuthorName"]})


# realiza tentativas de conexão com o banco
# Gambiarra necessária, dado que script cria container de API Gateway
#   sem necessariamente validar se MySQL está OK.
#   Mantido assim por causa de ganho de performance no setup
def main() -> None:
    global mydb
    
    while True:
        try:
            mydb = pymysql.connect(
            host="mysql-service",
            database="openshelf",
            user="root",
            password="passwd"
            )
            break
        except:
            pass


if __name__ == '__main__':
    main()
    app.run(host='0.0.0.0', port=5003, debug=True)

import pymysql
pymysql.install_as_MySQLdb()

from flask import Flask, request, jsonify
from authlib.integrations.flask_client import OAuth

app = Flask(__name__)

mydb: pymysql.connections.Connection  


@app.route('/book/list', methods=['GET'])
def book_list():
    mycursor = mydb.cursor()
    sql = """SELECT 
                tblbooks.BookName,
                tblcategory.CategoryName,
                tblauthors.AuthorName,
                tblbooks.ISBNNumber,
                tblbooks.QuantityLeft,
                tblbooks.QuantityTotal,
                tblbooks.BookPrice,
                tblbooks.id as bookid 
            FROM tblbooks 
            JOIN tblcategory ON tblcategory.id=tblbooks.CatId 
            JOIN tblauthors ON tblauthors.id=tblbooks.AuthorId"""

    mycursor.execute(sql)
    myresult = mycursor.fetchall()

    books = []
    for book in myresult:
        BookName, CategoryName, AuthorName, ISBNNumber, QuantityLeft, QuantityTotal, BookPrice, bookid = book
        books.append({
            "BookName": BookName,
            "Description": CategoryName,
            "AuthorName": AuthorName,
            "ISBNNumber": ISBNNumber,
            "QuantityLeft": QuantityLeft,
            "QuantityTotal": QuantityTotal,
            "BookPrice": BookPrice,
            "BookId": bookid
        })

    return jsonify(books)


@app.route('/book/register', methods=['POST'])
def book_register():
    data = request.get_json()
    
    auth_result: bool

    mycursor = mydb.cursor()
    
    sql = "SELECT StudentId, Status, EmailId FROM tblstudents WHERE EmailId = %s and Password = %s"

    values = (data["Email"], data["Passwd"])
    
    mycursor.execute(sql, values)
    myresult = mycursor.fetchall()

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
            host="10.100.24.10",
            database="openshelf",
            user="root",
            password="passwd"
            )
            break
        except:
            pass


if __name__ == '__main__':
    main()
    app.run(host='0.0.0.0', port=5002, debug=True)

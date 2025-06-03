import pymysql
pymysql.install_as_MySQLdb()

from flask import Flask, request, jsonify
from authlib.integrations.flask_client import OAuth

app = Flask(__name__)

mydb: pymysql.connections.Connection  


@app.after_request
def add_header(r):
    """
    Add headers to both force latest IE rendering engine or Chrome Frame,
    and also to cache the rendered page for 10 minutes.
    """
    r.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    r.headers["Pragma"] = "no-cache"
    r.headers["Expires"] = "0"
    r.headers['Cache-Control'] = 'public, max-age=0'
    return r


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
    
    sql = """INSERT INTO 
                tblbooks(BookName,
                        Description,
                        CatId,
                        AuthorId,
                        QuantityTotal,
                        QuantityLeft,
                        ISBNNumber,
                        BookPrice)
            VALUES(%s,%s,%s,%s,%s,%s,%s,%s)"""

    values = (data["bookname"], data["description"], data["category"], data["author"], data["quantitytotal"], data["quantitytotal"], data["isbn"], data["price"])
    
    mycursor.execute(sql, values)
    mydb.commit()

    return jsonify({"Result": f"Success"})


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

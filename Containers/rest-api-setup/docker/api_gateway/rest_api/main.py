import logging
import datetime
from os import path

from flask import Flask, request, jsonify
from authlib.integrations.flask_client import OAuth
import requests
import pymysql
pymysql.install_as_MySQLdb()

app = Flask(__name__)

mydb: pymysql.connections.Connection  

logging.basicConfig(filename='/var/log/audit_log/openshelf_audit.log', level=logging.INFO)


@app.after_request
def add_header(r):
    """ inibe a criação de cache """
    r.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    r.headers["Pragma"] = "no-cache"
    r.headers["Expires"] = "0"
    r.headers['Cache-Control'] = 'public, max-age=0'
    return r


@app.route('/auth/admin', methods=['POST'])
def auth_admin():
        data = request.get_json()
        
        logging.info('[%s] (/auth/user) User Admin %s is trying to authenticate', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("Username", "None"))
        
        header = {"Content-Type": "application/json"}

        url = "http://10.100.1.10:5001/auth/admin"

        response = requests.post(url, json=data, headers=header)

        if response.status_code != 200:
            return jsonify({"Result": "Error", "HTML Code": f"{response.status_code}"})

        try:
            # parse
            resp_json = response.json()
            result = resp_json.get("Result", "False")
        except Exception as e:
            logging.info("[%s] (/auth/admin) Internal error to API Gateway 'main.py': %s", datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), str(e))
            return jsonify({"Result": "Error", "Error": str(e)})

        if result == "False":
            logging.info('[%s] (/auth/user) User Admin "%s" fail to authenticate', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("Username", "None"))
        else:
            logging.info('[%s] (/auth/user) User Admin "%s" successfuly authenticate', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("Username", "None"))

        return jsonify({"Result": f"{result}"})


@app.route('/auth/user', methods=['POST'])
def auth_user():
        data = request.get_json()
        
        logging.info('[%s] (/auth/user) User "%s" is trying to authenticate', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("Email", "None"))
        
        header = {"Content-Type": "application/json"}

        url = "http://10.100.1.10:5001/auth/user"

        response = requests.post(url, json=data, headers=header)

        if response.status_code != 200:
            return jsonify({"Result": "Error", "HTML Code": f"{response.status_code}"})

        try:
            # parse
            resp_json = response.json()
            result = resp_json.get("Result", "False")
            StudentId = resp_json.get("StudentId")
            Status = resp_json.get("Status")
            EmailId = resp_json.get("EmailId")
        except Exception as e:
            logging.info("[%s] (/auth/user) Internal error to API Gateway 'main.py': %s", datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), str(e))
            return jsonify({"Result": "Error", "Error": str(e)})

        if result == "False":
            logging.info('[%s] (/auth/user) User "%s" fail to authenticate', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("Email", "None"))
        else:
            logging.info('[%s] (/auth/user) User "%s" successfuly authenticate', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("Email", "None"))

        return jsonify({"Result": f"{result}", "StudentId": f"{StudentId}", "Status": f"{Status}", "EmailId": f"{EmailId}"})


@app.route('/book/list', methods=['POST'])
def book_list():
    data = request.get_json()

    logging.info('[%s] (/book/list) User "%s" list all books', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("stdId", "None"))
    
    header = {"Content-Type": "application/json"}
    url = "http://10.100.2.10:5002/book/list"

    response = requests.get(url, headers=header)

    if response.status_code != 200:
        return jsonify({"Result": "Error", "HTML Code": f"{response.status_code}"})

    try:
        books = response.json()
    except Exception as e:
        logging.info("[%s] (/book/list) Error parsing response: %s", datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), str(e))
        return jsonify({"Result": "Error", "Error": str(e)})

    return jsonify(books)


@app.route('/book/register', methods=['POST'])
def book_register():
        data = request.get_json()
        
        logging.info('[%s] (/book/register) User "%s" is trying to register a book', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("stdId", "None"))
        
        header = {"Content-Type": "application/json"}

        url = "http://10.100.2.10:5002/book/register"

        response = requests.post(url, json=data, headers=header)

        if response.status_code != 200:
            return jsonify({"Result": "Error", "HTML Code": f"{response.status_code}"})

        resp_json = response.json()
        result = resp_json.get("Result", "False")

        if result == "False":
            logging.info('[%s] (/book/register) User "%s" fail to register a book', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("stdId", "None"))
        else:
            logging.info('[%s] (/book/register) User "%s" successfuly register a book', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("result", "None"))

        return jsonify({"Result": f"{result}"})
    

@app.route('/author/list', methods=['GET'])
def author_list():
    data = request.get_json()

    logging.info('[%s] (/author/list) User "%s" list all books', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("stdId", "None"))
    
    header = {"Content-Type": "application/json"}
    url = "http://10.100.3.10:5003/author/list"

    response = requests.get(url, headers=header)

    if response.status_code != 200:
        return jsonify({"Result": "Error", "HTML Code": f"{response.status_code}"})

    try:
        books = response.json()
    except Exception as e:
        logging.info("[%s] (/author/list) Error parsing response: %s", datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), str(e))
        return jsonify({"Result": "Error", "Error": str(e)})

    return jsonify(books)


@app.route('/author/register', methods=['POST'])
def author_register():
        data = request.get_json()
        
        logging.info('[%s] (/author/register) User "%s" is trying to register a author "%s"', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("stdId", "None"), data.get("AuthorName", "None"))
        
        header = {"Content-Type": "application/json"}

        url = "http://10.100.3.10:5003/author/register"

        response = requests.post(url, json=data, headers=header)

        if response.status_code != 200:
            return jsonify({"Result": "Error", "HTML Code": f"{response.status_code}"})

        resp_json = response.json()
        result = resp_json.get("Result", "False")

        if result == "False":
            logging.info('[%s] (/author/register) User "%s" fail to register author ', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("stdId", "None"))
        else:
            logging.info('[%s] (/author/register) User "%s" successfuly register a book', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"), data.get("result", "None"))


if __name__ == '__main__':
    logging.info('[%s] API Gateway started', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"))
    app.run(host='0.0.0.0', port=5000, debug=True, use_reloader=False)

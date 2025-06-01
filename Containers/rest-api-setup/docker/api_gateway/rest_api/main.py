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


if __name__ == '__main__':
    logging.info('[%s] API Gateway started', datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"))
    app.run(host='0.0.0.0', port=5000, debug=True, use_reloader=False)

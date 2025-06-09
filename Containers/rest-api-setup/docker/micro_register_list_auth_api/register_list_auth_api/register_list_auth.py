import logging
import datetime
from flask import Flask, jsonify

app = Flask(__name__)

# Configuração de log
logging.basicConfig(
    filename='/var/log/audit_log/openshelf_register_list_auth.log',
    level=logging.INFO
)

@app.after_request
def add_header(response):
    """ Impede caching """
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response

@app.route('/ping', methods=['GET'])
def ping():
    timestamp = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ")
    logging.info('[%s] /ping accessed from register_list_auth', timestamp)
    return jsonify({"Result": "pong", "Service": "register_list_auth"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5003, debug=True)
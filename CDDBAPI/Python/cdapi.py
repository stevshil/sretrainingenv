#!/usr/bin/env python

import sys, json, os
from flask import Flask, request
from flask_cors import CORS
from waitress import serve
from dotenv import load_dotenv
import dbservice

curdir=os.getcwd()
# config = dotenv_values(".env")
load_dotenv()

app = Flask(__name__)
CORS(app)
dbs=dbservice.dbservice(app)

@app.route("/")
def index():
    # General page
    return("<h1>Hello</h1>")

@app.route("/api/cds", methods=["GET"])
def getAllCDs():
    return(dbs.getAllCDs())

@app.route("/api/cds/<id>", methods=["GET"])
def getCD(id):
    return(dbs.getCD(id))
    
@app.route("/api/cds/<id>", methods=["DELETE"])
def deleteCD(id):
    return(dbs.deleteCD(id))

@app.route("/api/cds", methods=["POST"])
def addCD():
    return(dbs.addCD(request.json))

@app.route("/api/cds/<id>", methods=["PUT"])
def updateCD(id):
    return(dbs.updateCD(id,request.json))

debugon=False
if __name__ == "__main__":
    try:
        if sys.argv[1] == "DEBUG":
            print("DEBUG mode on")
            debugon=True
            try:
                app.run(host='0.0.0.0',port=8080,debug=True)
            except Exception as e:
                print(str(e))
                pass
    except Exception as e:
        print(str(e))
        if debugon == False:
            print("PRODUCTION mode on")
            serve(app, host='0.0.0.0', port=8080)
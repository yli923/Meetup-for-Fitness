from flask import Flask, jsonify, request, abort
from flask.ext.mysql import MySQL
import json, codecs
import boto3
from werkzeug.utils import secure_filename
import datetime

config = json.load(codecs.open('config.json', encoding='utf-8'))
app = Flask(__name__)
mysql = MySQL()
client = boto3.client('s3')

app.config['MYSQL_DATABASE_USER'] = config['db_user']
app.config['MYSQL_DATABASE_PASSWORD'] = config['db_passwd']
app.config['MYSQL_DATABASE_DB'] = config['db_db']
app.config['MYSQL_DATABASE_HOST'] = config['db_host']
mysql.init_app(app)

@app.route('/auth/login',methods=['POST'])
def auth_login():
	if not request.json or not 'username' in request.json or not 'password' in request.json:
		abort(400, '{"message":"false"}')
	username = request.json['username']
	password = request.json['password']
	db = mysql.connect()
	cursor = db.cursor()
	cursor.execute("SELECT * FROM User WHERE username = %s AND password = %s",[username,password])
	if cursor.rowcount == 1:
			results = cursor.fetchall()
			userId = results[0][0]
			db.close()
			return json.dumps({'existing user':True,'userId':userId})
	else: 
		db.rollback()
		db.close()
		abort(400, '{"message":"login failed"}') 

@app.route('/user/info', methods=['POST'])
def add_user_info():
	if not request.json or not 'username' in request.json or not 'password' in request.json or not 'gender' in request.json or not 'email' in request.json or not 'avatarURL' in request.json or not 'description' in request.json:
		abort(400, '{"message":"Input parameter incorrect or missing"}')
	username = request.json['username']
	password = request.json['password']
	gender = request.json['gender']
	email = request.json['email']
	avatarURL = request.json['avatarURL']
	description = request.json['description']
	db = mysql.connect()
	cursor = db.cursor()
	cursor.execute("SELECT * FROM User WHERE username = '%s'"%username)
	if cursor.rowcount == 0:
		try:
			cursor.execute("INSERT INTO User(username,password,gender,email,avatarURL,description) values (%s,%s,%s,%s,%s,%s)",[username,password,gender,email,avatarURL,description])
			userId = cursor.lastrowid
			db.commit()
			db.close()
			return 'Insert User Info Success'
		except:
			db.rollback()
	   		db.close()
	   		abort(400, '{"message":"insert unsuccessful"}')
	else:
		db.rollback()
		db.close()
		abort(400, '{"message":"user exists"}')


if __name__ == '__main__':
	app.run(host='0.0.0.0',port='80')
	#app.run()
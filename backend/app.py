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
		return json.dumps({'existing user':False}) 

@app.route('/auth/signup', methods=['POST'])
def auth_signup():
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
			return json.dumps({'insert successful':True,'userId':userId})
		except:
			db.rollback()
			db.close()
	   		abort(400, '{"message":"insert unsuccessful"}')
	else:
		db.rollback()
		db.close()
		abort(400, '{"message":"user exists"}')

@app.route('/activity', methods=['GET'])
def get_all_activity():	
	activityList = []
	db = mysql.connect()
	cursor = db.cursor()
	cursor.execute("SELECT * FROM Activity ORDER BY postTime;")
	if cursor.rowcount > 0:
		aList = cursor.fetchall()
		for aRow in aList:
			userId = aRow[0]
			aid = aRow[1]
			aName = aRow[2]
			aInfo = aRow[3]
			location = aRow[4]
			aTime = aRow[5]
			postTime = aRow[6]
			sportsId = aRow[7]
			maxPeople = aRow[8]
			teamId = aRow[9]
			sportsCur = db.cursor()
			sportsCur.execute("SELECT sportsType FROM SportsType WHERE sportsId = '%s'" %sportsId)
			sportsType = [item[0] for item in sportsCur.fetchall()]
			if teamId == -1:
				currentActivity = {}
				currentActivity['userId'] = userId
				currentActivity['aid'] = aid
				currentActivity['aName'] = aName
				currentActivity['aInfo'] = aInfo
				currentActivity['location'] = location
				currentActivity['aTime'] = aTime
				currentActivity['postTime'] = postTime
				currentActivity['sportsType'] = sportsType
				currentActivity['maxPeople'] = maxPeople
				activityList.append(currentActivity)
			else:
				teamCur = db.cursor()
				teamCur.execute("SELECT tName FROM TeamInfo WHERE teamId = '%s'" %teamId)
				tName = [item[0] for item in teamCur.fetchall()]
				currentActivity = {}
				currentActivity['userId'] = userId
				currentActivity['aid'] = aid
				currentActivity['aName'] = aName
				currentActivity['aInfo'] = aInfo
				currentActivity['location'] = location
				currentActivity['aTime'] = aTime
				currentActivity['postTime'] = postTime
				currentActivity['sportsType'] = sportsType
				currentActivity['maxPeople'] = maxPeople
				currentActivity['teamId'] = teamId
				currentActivity['teamName'] = tName
				activityList.append(currentActivity)
	db.close()
	return jsonify({'activities':activityList})

@app.route('/activity/add/allInfo/<userId>', methods=['POST'])
def add_activity(userId):
	if not request.json or not 'aName' in request.json or not 'aInfo' in request.json or not 'location' in request.json or not 'aTime' in request.json or not 'sportsType' in request.json or not 'maxPeople' in request.json or not 'teamId' in request.json: 
		abort(400, '{"message":"Input parameter incorrect or missing"}')
	aName = request.json['aName']
	aInfo = request.json['aInfo']
	location = request.json['location']
	aTime = request.json['aTime']
	sportsType = request.json['sportsType']
	maxPeople = request.json['maxPeople']
	teamId = request.json['teamId']
	postTime = datetime.datetime.now()
	db = mysql.connect()
	cursor = db.cursor()
	cursor.execute("SELECT sportsId FROM SportsType WHERE sportsType = '%s'"%sportsType)
	sportsId = [item[0] for item in cursor.fetchall()]
	try:
		cursor.execute("INSERT INTO Activity(userId,aName,aInfo,location,aTime,postTime,sportsId,maxPeople,teamId) values (%s,%s,%s,%s,%s,%s,%s,%s,%s)",[userId,aName,aInfo,location,aTime,postTime,sportsId,maxPeople,teamId])
		aid = cursor.lastrowid
		db.commit()
		db.close()
		return("success")
	except:
		db.rollback()
		db.close()
		return("fail")

@app.route('/activity/sportsType', methods=['GET'])
def get_sportsType():
	sportsList = []
	db = mysql.connect()
	cursor = db.cursor()
	cursor.execute("SELECT sportsType FROM SportsType") 
	if cursor.rowcount > 0:
		sportsList = [item[0] for item in cursor.fetchall()]
		db.close()
		return jsonify({'SportsType':sportsList})
	else :
		db.close()
		abort(400,"fail")

@app.route('/activity/<userId>', methods=['GET'])
def get_user_activity(userId):	
	activityList = []
	db = mysql.connect()
	cursor = db.cursor()
	cursor.execute("SELECT * FROM Activity WHERE userId = '%s'"%userId)
	if cursor.rowcount > 0:
		aList = cursor.fetchall()
		for aRow in aList:
			aid = aRow[0]
			aName = aRow[1]
			aInfo = aRow[2]
			location = aRow[3]
			aTime = aRow[4]
			postTime = aRow[5]
			sportsId = aRow[6]
			maxPeople = aRow[7]
			isTeam = aRow[8]
			sportsCur = db.cursor()
			sportsCur.execute("SELECT sportsType FROM SportsType WHERE sportsId = '%s'" %sportsId)
			sportsType = [item[0] for item in sportsCur.fetchall()]
			currentActivity = {}
			currentActivity['userId'] = userId
			currentActivity['aid'] = aid
			currentActivity['aName'] = aName
			currentActivity['aInfo'] = aInfo
			currentActivity['location'] = location
			currentActivity['aTime'] = aTime
			currentActivity['postTime'] = postTime
			currentActivity['sportsType'] = sportsType
			currentActivity['maxPeople'] = maxPeople
			currentActivity['teamId'] = teamId
			activityList.append(currentActivity)
	db.close()
	return jsonify({'activities':activityList})

@app.route('/friends/<userId>', methods=['GET'])
def get_user_friends(userId):
	friendList = []
	db = mysql.connect()
	cursor = db.cursor()
	cursor.execute("SELECT friendId FROM Friends WHERE userId = '%s'"%userId) 
	if cursor.rowcount > 0:
		friendList = [item[0] for item in cursor.fetchall()]
		db.close()
		return jsonify({'Friends List':friendList})
	else :
		db.close()
		abort(400,"fail")

@app.route('/friends/add/<userId>', methods=['POST'])
def add_friends(userId):
	if not request.json or not 'friendId' in request.json:
		abort(400, '{"message":"Input parameter incorrect or missing"}')
	friendId = request.json['friendId']
	db = mysql.connect()
	cursor = db.cursor()
	cursor.execute("SELECT friendId FROM Friends WHERE userId = %s AND friendId = %s",[userId,friendId]) 
	if cursor.rowcount == 0:
		cursor.execute("INSERT INTO Friends(userId, friendId) values (%s,%s)",[userId,friendId])
		cursor.execute("INSERT INTO Friends(userId, friendId) values (%s,%s)",[friendId,userId])
		db.commit()
		db.close()
		return("success")
	else:
		db.rollback()
		db.close()
		return("fail")


@app.route('/teams/<userId>', methods=['GET'])
def get_user_teams(userId):
	teamsList = []
	db = mysql.connect()
	cursor = db.cursor()
	cursor.execute("SELECT teamId FROM TeamPlayer WHERE userId = '%s'"%userId) 
	if cursor.rowcount > 0:
		teamList = [item[0] for item in cursor.fetchall()]
		db.close()
		return jsonify({'Users Team List':teamList})
	else :
		db.close()
		abort(400,"fail")

@app.route('/teams/add/allInfo/<userId>', methods=['POST'])
def add_team(userId):
	if not request.json or not 'tName' in request.json or not 'tInfo' in request.json or not 'sportsType' in request.json or not 'tAvatarURL' in request.json: 
		abort(400, '{"message":"Input parameter incorrect or missing"}')
	tName = request.json['tName']
	tInfo = request.json['tInfo']
	sportsType = request.json['sportsType']
	tAvatarURL = request.json['tAvatarURL']
	postTime = datetime.datetime.now()
	db = mysql.connect()
	cursor = db.cursor()
	cursor.execute("SELECT sportsId FROM SportsType WHERE sportsType = '%s'"%sportsType)
	sportsId = [item[0] for item in cursor.fetchall()]
	try:
		cursor.execute("INSERT INTO TeamInfo(userId,tName,tInfo,postTime,sportsId,tAvatarURL) values (%s,%s,%s,%s,%s,%s)",[userId,tName,tInfo,postTime,sportsId,tAvatarURL])
		teamId = cursor.lastrowid
		db.commit()
		db.close()
		return("success")
	except:
		db.rollback()
		db.close()
		return("fail")

@app.route('/team/add/member/<teamId>', methods=['POST'])
def add_team_member(teamId):
	if not request.json or not 'userId' in request.json:
		abort(400, '{"message":"Input parameter incorrect or missing"}')
	userId = request.json['userId']
	db = mysql.connect()
	cursor = db.cursor()
	cursor.execute("SELECT userId FROM TeamPlayer WHERE userId = %s AND teamId = %s",[userId,teamId]) 
	if cursor.rowcount == 0:
		cursor.execute("INSERT INTO TeamPlayer(userId, teamId) values (%s,%s)",[userId,teamId])
		db.commit()
		db.close()
		return("success")
	else:
		db.rollback()
		db.close()
		return("fail")


if __name__ == '__main__':
	app.run(host='0.0.0.0',port='80')
	#app.run()
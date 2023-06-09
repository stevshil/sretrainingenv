#!/usr/bin/env python

import requests, json, os, sys, time
import mysql.connector as myconn
from dotenv import load_dotenv

curdir=os.getcwd()
# config = dotenv_values(".env")
load_dotenv()

# Variables
dbcds=[]
tracksdbcds={}
deezercdinfo={}

# DB connections
print("DB connection")
print("HOST: "+(os.environ['DBSRV'])[0:-5])
print("PORT: "+(os.environ['DBSRV'])[-4:])
mydb=myconn.connect(
    host=(os.environ['DBSRV'])[0:-5],
    user=os.environ['DBUSER'],
    password=os.environ['DBPASS'],
    port=(os.environ['DBSRV'])[-4:],
    database="tpscd"
)

# Get artist
print("Getting CD info")
mycursor = mydb.cursor()
sql="SELECT id,artist,title FROM compact_discs;"
mycursor.execute(sql)
myresult = mycursor.fetchall()

print("Creating CD array")
for cd_id,artist,title in myresult:
    if " " in artist:
        artist=artist.replace(" ","_")
        artist=artist.lower()
    dbcds.append({"cd_id": cd_id, "title": title, "artist": artist})

#print(dbcds)
mycursor.close()

# Get all tracks from DB
print("Retrieving all tracks in DB")
mycursor = mydb.cursor()
sql="SELECT cd_id,title FROM tracks;"
mycursor.execute(sql)
myresult = mycursor.fetchall()

for cd_id,title in myresult:
    if cd_id in tracksdbcds:
        tracksdbcds[cd_id].append(title)
    else:
        tracksdbcds[cd_id]=[title]
mycursor.close()
#print("tracksdbcds: "+repr(tracksdbcds))

print("Getting data from Deezer")
url = "https://api.deezer.com/search"
headers = {
    "Content-Type": "application/json"
}
reqsess=requests.Session()

for item in dbcds:
    # Get info from Deezer
    querystring = {"q": (item["artist"]).lower()}
    # print(str(querystring))

    try:
        response = reqsess.get(url, headers=headers, params=querystring, timeout=5)
    except Exception as e:
        print("ERROR: "+str(e))
        continue

    album=0
    tracklist=""

    data=response.json()
    # print(data)
    for album in data['data']:
        # print(album['album']['title']+" - "+ item["title"])
        if album['album']['title'] == item["title"]:
            print("Processing: "+album['album']['title']+" DB: "+item["title"])
            # print(album)
            albumid=album['id']
            tracklist=album['album']['tracklist']
            deezercdinfo[item['cd_id']]=tracklist

print("Getting track lists for CDs")
sqldata={}
for tracklist in deezercdinfo:
    trackurl=deezercdinfo[tracklist]
    cd_id=tracklist
    try:
        response = reqsess.get(trackurl, headers=headers, timeout=5)
        tracks=response.json()
        for track in tracks['data']:
            if "track_position" in track:
                if cd_id not in sqldata:
                    sqldata[cd_id]=[track['title']]
                else:
                    sqldata[cd_id].append(track['title'])
    except Exception as e:
        print("ERROR: "+str(e))
        pass

print(sqldata)

print("Adding tracks to DB")
for tracks in dbcds:
    if tracks['cd_id'] not in sqldata.keys():
        continue
    mycursor=mydb.cursor()
    sqlstr="INSERT INTO tracks (cd_id,title) VALUES (%s,%s)"
    for entries in sqldata[tracks['cd_id']]:
        try:
            if entries in tracksdbcds[tracks['cd_id']]:
                continue
        except:
            pass
        insert_data=[tracks['cd_id'],entries]
        # print(insert_data)
        if len(insert_data) > 0:
            mycursor.execute(sqlstr, insert_data)
    
    # Update track numbers in cds
    # updateSQL="UPDATE compact_discs SET tracks="+len()
    print("Calculating track totals")
    numTracksSQL="SELECT count(cd_id) from tracks WHERE cd_id="+str(tracks['cd_id'])
    mycursor2 = mydb.cursor()
    mycursor2.execute(numTracksSQL)
    print(numTracksSQL)
    myresult = mycursor2.fetchone()

    updateSQL="UPDATE compact_discs SET tracks="+str(myresult[0])+" WHERE id="+str(tracks['cd_id'])
    mycursor3=mydb.cursor()
    mycursor3.execute(updateSQL)

    mydb.commit()
    
    mycursor.close()
    mycursor2.close()
    mycursor3.close()

        
mydb.close()
print("Finished")

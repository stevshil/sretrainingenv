#!/usr/bin/env python

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import create_engine
import os, json, sys
import pymysql
pymysql.install_as_MySQLdb()
from dotenv import load_dotenv

curdir=os.getcwd()
load_dotenv()

class dbservice:
    # Set up DB
    def __init__(self, app):
        engine_string="mysql://"+os.environ['DBUSER']+":"+os.environ['DBPASS']+"@"+os.environ['DBSRV']+"/tpscd"
        app.config["SQLALCHEMY_DATABASE_URI"] = engine_string
        app.config["SQLALCHEMY_TRACK_MODIFICATIONS"]=False
        db=SQLAlchemy(app)
        db.reflect(bind='__all__', app=None)
        model = db.Model
        meta = db.metadata
        engine = db.engine
        db.create_all()
        self.db=db
        self.app=app
        self.compact_discs=db.metadata.tables['compact_discs']
        self.tracks=db.metadata.tables['tracks']

    def getAllCDs(self):
        s = self.db.select([self.compact_discs])
        CDs=self.db.engine.execute(s).fetchall()
        CDCols=self.db.metadata.tables['compact_discs'].columns.keys()
        # return(toJSON(CDCols,CDs))
        return(convert_to_dict(CDs))
    
    def getCD(self,id):
        CDCols=self.db.metadata.tables['compact_discs'].columns.keys()
        CDs = self.db.session.query(self.compact_discs).filter(self.compact_discs.c.id==id).first()
        self.db.session.commit()
        CDtracks = self.db.session.query(self.tracks).filter(self.tracks.c.cd_id==id).all()
        CDs=convert_to_dict(CDs)
        CDtracks=convert_to_dict(CDtracks)
        data=[CDs,CDtracks]
        return(data)

    def deleteCD(self,id):
        delTracks=0
        cds=0

        # First we need to delete all tracks
        s = self.db.delete(self.tracks).where(self.tracks.c.cd_id == id)
        resulttracks = self.db.engine.execute(s)
        if resulttracks:
            delTracks=1
        else:
            self.db.engine.rollback()
        self.app.logger.info(resulttracks)

        # Now we can delete CD
        if tracks == 1:
            s = self.db.delete(self.compact_discs).where(self.compact_discs.c.id == id)
            resultcd = self.db.engine.execute(s)
            if resultcd:
                cds=1
            else:
                self.db.engine.rollback()
            self.app.logger.info(resultcd)

        if delTracks == 1 and cds == 1:
            return({"status": "Deleted"})
        else:
            return({"status": "Failed"})
        
    def addCD(self,data):
        # Data comes in JSON format
        """
        {
            "title": "Steve Does That",
            "artist": "Steve",
            "tracks": 2,
            "price": 20.99,
            "trackTitles": [
                "Baa Baa Baby", 
                "Baby Ewe Love Me"
            ]
        }
        """

        tracks=0
        cds=0

        # Get number of tracks from array
        numTracks=len(data['trackTitles'])

        # Insert CD first to get CD ID
        s = self.compact_discs.insert().values(title=data['title'],artist=data['artist'],price=data['price'],tracks=numTracks)
        result=self.db.session.execute(s)
        if result:
            self.app.logger.info("RESULT: "+str(result.lastrowid))
            newCdID=result.lastrowid
        else:
            cds=1

        # Insert trackTitles into tracks using CD ID
        tracksIn=[]
        for track in data['trackTitles']:
            tracksIn.append({'cd_id': newCdID, 'title': track})
        s2 = self.tracks.insert().values(tracksIn)
        result=self.db.session.execute(s2)
        if result:
            firstTrack=result.lastrowid
            self.app.logger.info(firstTrack)
        else:
            tracks=1

        if cds == 0 and tracks == 0:
            self.db.session.commit()
            return({'status': 'OK', 'ID':newCdID, 'firstTrackId':firstTrack})
        else:
            self.db.session.rollback()
            return({"status": "FAILED"})
    
    def updateCD(self,id,data):
        """
        trackTitles needs to now be in the format of
        [
            { 'currentTitle': titlename, 'newTitle': newtitlename },
            { 'currentTitle': titlename, 'newTitle': newtitlename }
        ]

        The rest of the JSON is as insert
        """
        cds=0
        tracks=0
        cdInfo=data.copy()
        del cdInfo['trackTitles']
        # s = self.db.update(self.compact_discs).filter(self.compact_discs.c.id==id).values(cdInfo)
        # resultcd = self.db.engine.execute(s)
        s = self.db.session.query(self.compact_discs).filter(self.compact_discs.c.id==id)
        resultcd=s.update(cdInfo)
        if resultcd:
            # self.app.logger.info("RESULT: "+str(dir(resultcd)))
            cds=0
        else:
            cds=1

        resultTracks=[]
        if cds == 0:
            for the_track in data['trackTitles']:
                CDtracks = self.db.session.query(self.tracks).filter(self.tracks.c.cd_id==id, self.tracks.c.title==the_track['currentTitle'])
                self.db.app.logger.info("the_track: "+str(the_track))
                new_track={'cd_id': id, 'title': the_track['newTitle']}
                resultTrack = CDtracks.update(new_track)
                if resultTrack:
                    resultTracks.append(1)

        if len(resultTracks) == len(data['trackTitles']) and cds == 0:
            self.db.session.commit()
            return({"status": "Tracks updated OK"})
        else:
            self.db.session.rollback()      
            return({"status": "FAILED"})

# Class functions, not methods

# def toJSON(incols,indata):
#         data=[]
#         for item in indata:
#             newdict={}
#             for cols in range(0,len(incols)):
#                 newdict[incols[cols]]=item[cols]
#                 #print(str(incols[cols])+"-"+str(item[cols]))
#             data.append(newdict)
#         return(data)

def convert_to_dict(data):
    if type(data) is list:
        return [q._asdict() for q in data]
    else:
        return data._asdict()
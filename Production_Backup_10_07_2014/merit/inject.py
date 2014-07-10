#!/usr/bin/python
import MySQLdb
import pika
import json
import logging
import sys

import datetime
from time import sleep

try:
	name = str(sys.argv[1])
except IndexError:
	print "usage inject.py retailer-name target-minutes"
	exit(1)

try:
	target = str(sys.argv[2])
except IndexError:
	print "usage inject.py retailer-name target-minutes"
	exit(1)

try:
	count = str(sys.argv[3])
except IndexError:
	count = "1000000"

# logging
LOG_FORMAT = ('%(levelname) -10s %(asctime)s %(name) -30s %(funcName) '
              '-35s %(lineno) -5d: %(message)s')
LOGGER = logging.getLogger(__name__)

logging.basicConfig(level=logging.WARNING, format=LOG_FORMAT)

# mq connection
connection = pika.BlockingConnection(pika.ConnectionParameters(
        host='frawspcmq'))

channel = connection.channel()

channel.queue_declare(queue='anorak.workers')

# db connection
db = MySQLdb.connect(	host="collection-db-prod-merit.cloud.trendinglines.co.uk", # your host
                     	user="myadmin", # your username
			passwd="dfFDG567HGf45", # your password
                      	db="meritproddata_thu") # name of the database


# create a db cursor
cur = db.cursor() 

cur.execute("SELECT RobotName,ObjectKey FROM Retailer WHERE RobotName = '" + name + "'")
for row in cur.fetchall():
	RobotName = row[0];
	retailer_id = row[1];



#cur.execute("SELECT count(*) FROM Product WHERE retailer_id = '" + retailer_id + "' AND detail_collected in ('n','N') limit " + count)
cur.execute("SELECT count(*) FROM Product_List WHERE retailer_id = '" + retailer_id + "' AND detail_collected in ('n','N') limit " + count)
row = cur.fetchone()
items = row[0]

if items == 0:
	print "Nothing to do"
	exit();


delay = float(target)*60/float(items)


print "Injecting", items, "items from",RobotName,"with a delay of",delay,"seconds between records, for an ETA of ",target,"minutes"

# execute sql
cur.execute("SELECT url, ObjectKey, RobotName FROM Product_List WHERE retailer_id = '" + retailer_id + "' AND detail_collected in ('n','N') limit " + count)
#cur.execute("SELECT url, ObjectKey, RobotName FROM Product_List WHERE retailer_id = '" + retailer_id + "' AND detail_collected in ('n') AND ObjectKey not in(select product_id from Product_Completed WHERE retailer_id = '" + retailer_id + "') limit " + count)
#cur.execute("SELECT url, ObjectKey, RobotName FROM Product_List WHERE retailer_id = '" + retailer_id + "' AND detail_collected='n' AND ObjectKey not in(select ObjectKey from Product WHERE retailer_id = '" + retailer_id + "') limit " + count)

# add rows to mq
for row in cur.fetchall():

    RobotName = row[2].split('--')[0]
    ObjectKey = row[1]
    url = row[0]

    messageBody = '{"ObjectKey": "' + ObjectKey + '", "RobotName": "' + RobotName + '", "url": "' + url + '", "RetailerId": "' + retailer_id + '"}'

    print datetime.datetime.now().time(), messageBody
    sleep(delay);

    channel.basic_publish(exchange='anorak.workers', routing_key='anorak.workers', body=messageBody)

# close mq connection
connection.close()

# close db connection
db.close()

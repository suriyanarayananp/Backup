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
	print "usage inject.py retailer-name"
	exit(1)

# logging
LOG_FORMAT = ('%(levelname) -10s %(asctime)s %(name) -30s %(funcName) '
              '-35s %(lineno) -5d: %(message)s')
LOGGER = logging.getLogger(__name__)

logging.basicConfig(level=logging.WARNING, format=LOG_FORMAT)

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



cur.execute("SELECT count(*) FROM Product WHERE retailer_id = '" + retailer_id + "' AND detail_collected = 'n'")
row = cur.fetchone()
items_n = row[0]


cur.execute("SELECT count(*) FROM Product WHERE retailer_id = '" + retailer_id + "' AND detail_collected = 'y'")
row = cur.fetchone()
items_y = row[0]

cur.execute("SELECT count(*) FROM Product WHERE retailer_id = '" + retailer_id + "' AND detail_collected = 'x'")
row = cur.fetchone()
items_x = row[0]

total = items_n + items_y + items_x

print "%-20s %7d %6.2f%% %6.2f%% %6.2f%%" % (RobotName, total, float(items_y)*100/total, float(items_x)*100/total, float(items_n)*100/total)

# close db connection
db.close()

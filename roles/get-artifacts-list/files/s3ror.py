#!/usr/bin/python

import boto3
import sys

BUCKET_NAME = sys.argv[1]
OBJECT_PREFIX = sys.argv[2]
#OBJECT_PREFIXNAME = sys.argv[3]
START = int(sys.argv[3])
COUNT = int(sys.argv[4])

get_last_modified = lambda obj: int(obj['LastModified'].strftime('%s'))

s3 = boto3.client('s3')
objs = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix=OBJECT_PREFIX)['Contents']
files = [obj['Key'].replace(OBJECT_PREFIX +"_", "").replace(".tar.gz","") for obj in sorted(objs, key=get_last_modified, reverse=True)][START:COUNT]
print(files)


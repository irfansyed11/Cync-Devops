#!/usr/bin/python

import boto3
import sys
import json

BUCKET_NAME = sys.argv[1]
OBJECT_NAME = sys.argv[2]
KEY_NAME = sys.argv[3]
VALUE_NAME = sys.argv[4]

s3 = boto3.client('s3')
response = s3.put_object_tagging(
        Bucket=BUCKET_NAME,
        Key=OBJECT_NAME,
        Tagging={'TagSet': [{'Key': KEY_NAME, 'Value': VALUE_NAME }]}
        )

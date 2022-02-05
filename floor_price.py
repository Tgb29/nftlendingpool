import boto3
import json
import logging

dynamodb = boto3.resource('dynamodb')

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def lambda_handler(event, context):
    logger.info(event)
    body = json.loads(event['body'])


    return {
        "floor": 375.85168
    }


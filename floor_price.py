import boto3
import json
import logging
import http.client

dynamodb = boto3.resource('dynamodb')

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def get_floor(event, context):
    logger.info(event)

    floor = dynamodb.Table('Config').get_item(Key={'configKey': 'floor_price'})['Item']['last_update']

    '''
    return {
        "floor": floor
    }
    '''

    return {
        "floor": 375.85168
    }


def call_covalent(event, context):
    logger.info(event)

    path = "/v1/137/nft_market/collection/0x9d29e9fb9622f098a3d64eba7d2ce2e8d9e7a46b/?key=ckey_66758c596cb54b5b9824c81edf9"
    conn = http.client.HTTPSConnection("api.covalenthq.com")
    conn.request("GET", path)
    
    response = conn.getresponse()
    logger.info(response)
    
    decoded_response = response.read().decode('utf-8')
    logger.info(decoded_response)

    covalent = json.loads(decoded_response)
    logger.info(covalent)

    floor = covalent['data']['items'][0]

    dynamodb.Table('Config').update_item(
        Key={
            'configKey': 'floor_price'
        },
        UpdateExpression="set last_update=:lu",
        ExpressionAttributeValues={
            ":lu": floor
        }
    )
    logger.info('config updated')

    return 

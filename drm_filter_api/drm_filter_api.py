#!/usr/bin/env python3.6
import os
import logging
import aws_lambda_logging
import json
import uuid
from dateutil.tz import tzlocal
from dateutil.tz import tzutc
import unittest
from unittest.mock import patch
from botocore.exceptions import ClientError

aws_lambda_logging.setup(level=os.environ.get('LOGLEVEL', 'INFO'), env=os.environ.get('ENV'))
logging.info(json.dumps({'message': 'initialising'}))
aws_lambda_logging.setup(level=os.environ.get('LOGLEVEL', 'INFO'), env=os.environ.get('ENV'))


def handler(event, context):
    """Handler for drm-filter-api"""
    aws_lambda_logging.setup(level=os.environ.get('LOGLEVEL', 'INFO'), env=os.environ.get('ENV'))

    try:
        logging.debug(json.dumps({'message': 'logging event', 'event': event}))
    except:
        logging.exception(json.dumps({'message': 'logging event'}))
        raise

    try:
        request = json.loads(event['body'])
        logging.debug(json.dumps({'message': "decoding message", "request": request}))
    except:
        logging.exception(json.dumps({'message': "decoding message"}))
        response = {
            "statusCode": 400,
            "body": json.dumps({"error": "Could not decode request: JSON parsing failed"}),
            'headers': {
                'Content-Type': 'application/json',
            }
        }
        return response

    try:
        body = filter_drm(request)
        logging.debug(json.dumps({'message': "filtering response", "body": body}))
    except:
        logging.exception(json.dumps({'message': "filtering response"}))
        response = {
            "statusCode": 503,
            "body": json.dumps({"error": "Failed to filter payload"}),
            'headers': {
                'Content-Type': 'application/json',
            }
        }
        return response

    response = {
        "statusCode": 200,
        "body": json.dumps(body),
        'headers': {
            'Content-Type': 'application/json',
        }
    }
    logging.info(json.dumps({'message': 'responding', 'response': response}))
    return response


def filter_drm(request):
    """Takes request input and returns shows with DRM enabled and at least 1 episode"""

    matching = [show for show in request['payload'] if show.get('drm') is True and show['episodeCount'] > 0]
    logging.debug(json.dumps({"message": "filtering shows", "matching": matching}))
    formatted = [{"image": show['image']['showImage'], "slug": show['slug'], "title": show['title']} for show in matching]
    logging.debug(json.dumps({"message": "formatting shows", "formatted": formatted}))
    return {"response": formatted}


class filter_tests(unittest.TestCase):
    def test_filter(self, *args):
        unittest.util._MAX_LENGTH = 2000
        request = json.loads(open('./test/request.json', 'r').read())
        actual = filter_drm(request)
        response = json.loads(open('./test/response.json', 'r').read())
        logging.debug(json.dumps({"message": "test_filter", "actual": actual, "resonse": response}))
        self.assertEqual(response, actual)


def unit_test(event, context):
    result = []
    suite = unittest.TestLoader().loadTestsFromTestCase(filter_tests)
    result.append(unittest.TextTestRunner().run(suite))

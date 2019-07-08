#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import logging

import boto3
import requests

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.WARN)

# add as many endpoints as needed
config = {
    "http://localhost:11223/stats": {
        "MetricName": "current_sessions",
        "Dimensions": [
            {
                "Name": "current_sessions",
                "Value": "sessions"
            },
        ],
        "Unit": "None",
        "Value": 0
    }
}

if __name__ == "__main__":
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    # Create CloudWatch client
    cloudwatch = boto3.client("cloudwatch")

    for value in config.keys():
        try:
            r = requests.get(value)
            if r.status_code == 200:
                result = r.json()
                config[value]["Value"] = result["response"]["value"]
                # Put custom metrics
                cloudwatch.put_metric_data(MetricData=[config[value]],
                                           Namespace="Zato/Stats")
        except Exception as e:
            logger.error(e.message)

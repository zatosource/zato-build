#!/usr/bin/env python3

from os.path import abspath
import argparse
import json
import sys
import requests
import yaml

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-t', '--token', type=str, required=True, help="TravisCI token")
    parser.add_argument(
        '-f',
        '--file',
        type=str,
        default="travis.yml",
        help="Path to TravisCI configuration file (default travis.yml)")
    parser.add_argument(
        '-r',
        '--repo',
        type=str,
        default="zatosource/zato-build",
        help="Repository path (default zatosource/zato-build)")
    parser.add_argument(
        '-b',
        '--branch',
        type=str,
        required=True,
        help="Repository branch name")
    args = parser.parse_args()

    endpoint = "https://api.travis-ci.org/repo/{repo}/requests".format(
        repo=args.repo.replace("/", "%2F"))

    if args.branch == "":
        print("Branch name can't be empty")
        sys.exit(1)

    with open(abspath(args.file)) as f:
        # use safe_load instead load
        travisConfig = yaml.safe_load(f)

    # print(json.dumps(travisConfig, indent=2))
    payload = {
        "request": {
            "message": "Custom build request from API",
            "branch": args.branch,
            "config": travisConfig
        }
    }
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Travis-API-Version": "3",
        "Authorization": "token {token}".format(token=args.token),
    }
    if "env" in travisConfig.keys() and travisConfig["env"][0] != "":
        payload["request"]["message"] = "branch: '{}' environment '{}'".format(
            args.branch, travisConfig["env"][0])
    try:
        r = requests.post(endpoint, headers=headers, data=json.dumps(payload))
        print("Build triggered.. build status: {}".format(
            json.loads(r.text)["@type"]))
    except Exception as e:
        print(e)

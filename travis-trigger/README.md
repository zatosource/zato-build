
- Install [Travis CI command line client](https://github.com/travis-ci/travis.rb#installation) to get your API token
- Get the access token:
```
$ travis login --org
$ travis token --org
Your access token is *****
```
- Trigger build specifying the access token obtained in the previous step:
```
./trigger-build.py -t YOURTOKEN -f travis.yml
```

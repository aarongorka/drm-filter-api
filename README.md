# drm-filter-api

Uses the [serverless](https://serverless.com/) framework to deploy to AWS Lambda.

## Requirements
  * Docker
  * docker-compose
  * Make

## Deploying
To create the virtualenv, install requirements using pip and then create the package.zip for uploading to Lambda:
```
make build
```
To deploy, fill out your `.env` file and then:
```
make deploy
```
## Testing
To run tests, first `make build` and then `make test`.

# drm-filter-api

## Deploying
To install the required NPM modules for Serverless:
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

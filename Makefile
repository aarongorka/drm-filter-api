PACKAGE_DIR=package/package
ARTIFACT_NAME=package.zip
ARTIFACT_PATH=package/$(ARTIFACT_NAME)
ifdef DOTENV
	DOTENV_TARGET=dotenv
else
	DOTENV_TARGET=.env
endif
ifdef AWS_ROLE
	ASSUME_REQUIRED?=assumeRole
endif


################
# Entry Points #
################
build: $(DOTENV_TARGET)
	docker-compose run --rm lambda-build make _build

deploy: $(DOTENV_TARGET) $(ASSUME_REQUIRED)
	docker-compose run --rm serverless make _deploy

logs: $(DOTENV_TARGET) $(ASSUME_REQUIRED)
	docker-compose run --rm serverless make _logs

unitTest: $(ASSUME_REQUIRED) $(DOTENV_TARGET)
	docker-compose run --rm lambda drm_filter_api.unit_test

smokeTest: $(DOTENV_TARGET) $(ASSUME_REQUIRED)
	docker-compose run --rm serverless make _smokeTest

remove: $(DOTENV_TARGET)
	docker-compose run --rm serverless make _remove

styleTest: $(DOTENV_TARGET)
	docker-compose run --rm pep8 --ignore 'E501,E128' drm_filter_api/*.py

run: $(DOTENV_TARGET)
	cp -a drm_filter_api/. $(PACKAGE_DIR)/
	docker-compose run --rm lambda drm_filter_api.handler

test: $(DOTENV_TARGET) styleTest unitTest

shell: $(DOTENV_TARGET)
	docker-compose run --rm lambda-build sh

##########
# Others #
##########

# Removes the .env file before each deploy to force regeneration without cleaning the whole environment
rm_env:
	rm -f .env
.PHONY: rm_env

# Create .env based on .env.template if .env does not exist
.env:
	@echo "Create .env with .env.template"
	cp .env.template .env

# Create/Overwrite .env with $(DOTENV)
dotenv:
	@echo "Overwrite .env with $(DOTENV)"
	cp $(DOTENV) .env

$(DOTENV):
	$(info overwriting .env file with $(DOTENV))
	cp $(DOTENV) .env
.PHONY: $(DOTENV)

venv:
	python3.6 -m venv --copies venv
	sed -i '43s/.*/VIRTUAL_ENV="$$(cd "$$(dirname "$$(dirname "$${BASH_SOURCE[0]}" )")" \&\& pwd)"/' venv/bin/activate  # bin/activate hardcodes the path when you create it making it unusable outside the container, this patch makes it dynamic. Double dollar signs to escape in the Makefile.
	sed -i '1s/.*/#!\/usr\/bin\/env python/' venv/bin/pip*

_build: venv requirements.txt
	mkdir -p $(PACKAGE_DIR)
	sh -c 'source venv/bin/activate && pip install -r requirements.txt'
	cp -a venv/lib/python3.6/site-packages/. $(PACKAGE_DIR)/
	cp -a drm_filter_api/. $(PACKAGE_DIR)/
	@cd $(PACKAGE_DIR) && python -O -m compileall -q .  # creates .pyc files which might speed up initial loading in Lambda
	cd $(PACKAGE_DIR) && zip -rq ../package .

$(ARTIFACT_PATH): $(DOTENV_TARGET) _build

_deploy: 
	rm -fr .serverless
	sls deploy -v

_smokeTest:
	sls invoke -f handler

_logs:
	sls logs -f handler --startTime 5m -t

_remove:
	sls remove -v
	rm -fr .serverless

_clean:
	rm -fr .serverless package .requirements venv/ run/ __pycache__/
.PHONY: _deploy _remove _clean

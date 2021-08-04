# Get current directory, without special '.' character
VOLUME=$(subst .,,$(shell basename $(PWD)))

APP_DIR=$(PWD)
TS=$(shell date +%Y%m%d%H%M%S)

develop: clean build run

clean:
	docker-compose rm -vf
	docker-compose down 

build:
	docker buildx bake -f docker-compose.yml \
		--set app.args.DOCKER_REGISTRY=docker.io/library \
		--set app.args.DOWNLOAD_URL=https://download.limesurvey.org/latest-stable-release/limesurvey5.0.12+210729.zip \
		--set app.args.DOWNLOAD_SHA256=93539eeffffb1dbfc5b11b6ae539a51bd90c964f5127b96a23ab420c714fb5e2 

run: 
	docker-compose up -d db
	sleep 20 # Initial startup takes longer
	docker-compose up -d app
	docker-compose logs -f

reset: clean
	rm -rf db/data/*
	rm -rf backend/config/*
	rm -rf backend/plugins/*
	rm -rf backend/upload/*

db-start:
	docker-compose up -d db
	docker-compose logs -f db

app-start:
	docker-compose up -d app
	docker-compose logs -f app

db-shell:
	docker-compose exec db /bin/bash

db-term:
	docker-compose exec db /bin/bash -c 'psql -U $${POSTGRES_USER} $${POSTGRES_DB}'

app-shell:
	docker-compose exec app /bin/bash

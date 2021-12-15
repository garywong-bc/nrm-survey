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
		--set app.args.DOCKER_REGISTRY=docker.io/library

build-nocache:
	docker buildx bake --no-cache -f docker-compose.yml \
		--set app.args.DOCKER_REGISTRY=docker.io/library

# http://localhost:8080/index.php/admin/authentication/sa/login
run: 
	docker-compose up -d
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

root-app-shell:
	docker-compose exec -u root app /bin/bash
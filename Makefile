# Get current directory, without special '.' character
VOLUME=$(subst .,,$(shell basename $(PWD)))

APP_DIR=$(PWD)
TS=$(shell date +%Y%m%d%H%M%S)

develop: clean build run

clean:
	docker-compose rm -vf
	docker-compose down 

build:
	docker buildx bake -f docker-compose.yml

run: 
	docker-compose up -d db
	sleep 20 # Initial startup takes longer
	docker-compose up -d app
	docker-compose logs -f

db-delete: clean
	rm -rf db/data/*

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

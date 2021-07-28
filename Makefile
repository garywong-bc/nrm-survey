# Get current directory, without special '.' character
VOLUME=$(subst .,,$(shell basename $(PWD)))

APP_DIR=$(PWD)
TS=$(shell date +%Y%m%d%H%M%S)

develop: clean build run

clean:
	docker compose rm -vf

build:
	docker buildx bake -f docker-compose.yml

run: 
	docker-compose up -d
	docker-compose logs -f

db.data.delete: clean
	docker volume rm $(VOLUME)_mysql

db.start:
	docker-compose up -d db
	docker-compose logs -f db
# rm -rf db/data/*

db-shell:
	docker-compose exec db /bin/bash

db-term:
	docker-compose exec db /bin/bash -c 'psql -U $${POSTGRES_USER} $${POSTGRES_DB}'

app-shell:
	docker-compose exec -u www-data app /bin/bash

web-shell:
	docker-compose exec -u www-data -w /var/www/html/ web /bin/bash

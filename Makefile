.PHONY: shell up down rebuild

up:
	docker compose up -d --build

down:
	docker compose down

shell:
	docker exec -it drupal8-example-web-1 bash

rebuild:
	docker compose build --no-cache web
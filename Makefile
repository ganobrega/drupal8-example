.PHONY: shell up down

up:
	docker compose up -d --build

down:
	docker compose down

shell:
	docker exec -it drupal8-example-web-1 bash

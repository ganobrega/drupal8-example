.PHONY: shell up down rebuild backup-drupal backup-db restore restore-db migrate-db

up:
	docker compose up -d --build
	@CRON_LINE="*/15 * * * * cd $(PWD) && make backup >/dev/null 2>&1"; \
		(crontab -l 2>/dev/null | grep -F -v -x "$$CRON_LINE" || true; echo "$$CRON_LINE") | crontab -

down:
	docker compose down

shell:
	docker exec -it drupal8-example-web-1 bash

rebuild:
	docker compose build --no-cache web

backup:
	make backup-drupal
	make backup-db

backup-drupal:
	chmod +x scripts/backup-sites.sh
	./scripts/backup-sites.sh

backup-db:
	chmod +x scripts/backup-db.sh
	./scripts/backup-db.sh

restore:
	chmod +x scripts/restore-sites.sh
	./scripts/restore-sites.sh $(BACKUP)

restore-db:
	chmod +x scripts/restore-db.sh
	./scripts/restore-db.sh $(BACKUP)

migrate-db:
	./scripts/migrate-db-to-host.sh
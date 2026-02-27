.PHONY: up down rebuild backup backup-sites backup-db backup-vendor restore-sites restore-db restore-vendor

up:
	docker compose up -d --build

down:
	docker compose down

rebuild:
	docker compose build --no-cache web

backup:
	chmod +x scripts/backup-all.sh
	./scripts/backup-all.sh

backup-sites:
	chmod +x scripts/backup-sites.sh
	./scripts/backup-sites.sh

backup-vendor:
	chmod +x scripts/backup-vendor.sh
	./scripts/backup-vendor.sh

backup-db:
	chmod +x scripts/backup-db.sh
	./scripts/backup-db.sh

restore-sites:
	chmod +x scripts/restore-sites.sh
	./scripts/restore-sites.sh $(BACKUP)

restore-db:
	chmod +x scripts/restore-db.sh
	./scripts/restore-db.sh $(DB_DUMP)

restore-vendor:
	chmod +x scripts/restore-vendor.sh
	./scripts/restore-vendor.sh $(VENDOR_BACKUP)
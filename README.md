# Drupal 8 com Docker

> **Requisito:** Execute todos os comandos e passos deste guia **dentro do WSL 2** (Windows Subsystem for Linux 2). O ambiente foi pensado para rodar no WSL 2; usar PowerShell ou CMD no Windows pode causar problemas de caminhos e permissões.


```bash
wsl
mkdir ~/projects/drupal8
cd ~/projects/drupal8

```

---

# 1 — Criar o repositório (Git)

Esse é **sempre o primeiro passo**.
Docker e Drupal entram dentro dele.

Estrutura inicial (vazia)
```
drupal8/
├── docker/
│   ├── Dockerfile
│   └── php.ini
├── docker-compose.yml
├── .gitignore
└── README.md
```

```
git init
git commit --allow-empty -m "init project"
```


# 2 — Subir o Docker (sem Drupal ainda)

Antes de CMS, valida o **ambiente**.

## docker-compose.yml (base)
```yml
version: "3.8"

services:
  db:
    image: mysql:5.7
    environment:
      MYSQL_DATABASE: drupal
      MYSQL_USER: drupal
      MYSQL_PASSWORD: drupal
      MYSQL_ROOT_PASSWORD: root
    volumes:
      - db_data:/var/lib/mysql

  web:
    build: ./docker
    ports:
      - "8080:80"
    volumes:
      - ./app:/var/www/html
    depends_on:
      - db

volumes:
  db_data:
```

### docker/Dockerfile

```dockerfile FROM php:7.4-apache

RUN apt-get update && apt-get install -y \
    unzip git libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install gd pdo pdo_mysql zip \
 && a2enmod rewrite

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY php.ini /usr/local/etc/php/

WORKDIR /var/www/html
```

### Subir

```bash
docker compose up -d --build
```

👉 Se `http://localhost:8080` abrir (mesmo vazio), tá tudo certo.

# 3 — Criar o Drupal com Composer (dentro do container)

Agora sim o CMS entra.

```bash
docker ps
```

Busque o ID do container que está ligado o drupal8-example-web-1

```bash
docker exec -it 123 bash
composer create-project drupal/recommended-project:^8.9 app -n --prefer-dist --no-progress
exit
```

A pasta app/ agora existe → já é código Git.

```bash
git add app composer.lock
git commit -m "Add Drupal 8 base project"
```

# 4 — Configurar o .gitignore

```
/vendor/
/app/web/sites/*/files/
/app/web/sites/*/private/
/app/web/sites/*/settings.php
.env
```

Commit:

```bash
git add .gitignore
git commit -m "Configure gitignore"
```

# 5 — Instalar pelo navegador

Abra:

```
http://localhost:8080
```

Banco:
- Host: `db`
- DB: `drupal`
- User: `drupal`
- Senha: `drupal`

Pronto 🎉

## Conferir banco de dados

Rode no projeto:

```bash
docker compose exec db mysql -u drupal -p drupal
```

No prompt do MySQL:
```bash
SHOW DATABASES;
USE drupal;
SHOW TABLES;
```

## Dump do banco de dados

Para gerar um dump local do banco MySQL em `dump-drupal.sql`:

```bash
docker compose exec db mysqldump --no-tablespaces -u drupal -pdrupal drupal > dump-drupal.sql
```

## Restaurar banco a partir do dump

Para apagar o banco atual `drupal`, recriá‑lo e importar o dump:

```bash
# Dropar e recriar o banco
docker compose exec db mysql -uroot -proot -e "DROP DATABASE IF EXISTS drupal; CREATE DATABASE drupal;"

# Importar o dump (rodar na pasta do projeto, onde está o dump-drupal.sql)
docker compose exec -T db mysql -udrupal -pdrupal drupal < dump-drupal.sql
```
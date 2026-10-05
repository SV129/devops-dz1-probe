#!/bin/bash
set -e

PREFIX=saidova-08
IMAGE=${PREFIX}/probe:2.0
PUB_PORT=8024
INNER_PORT=5008
DB_PORT=8026
MARKER=netlab

# 1. Снести старые контейнеры (том не трогаем!)
docker rm -f -v ${PREFIX}-web ${PREFIX}-db 2>/dev/null || true

# 2. Собрать образ приложения версии 2.0
docker build --build-arg VERSION=2.0 -t ${IMAGE} .

# 3. Создать том, если его ещё нет
docker volume create ${PREFIX}-data >/dev/null

# 4. Запустить базу на томе, с публикацией порта 8026
docker run -d --name ${PREFIX}-db \
  -e MARIADB_ROOT_PASSWORD=lab -e MARIADB_DATABASE=lab \
  -p ${DB_PORT}:3306 \
  -v ${PREFIX}-data:/var/lib/mysql \
  mariadb:11

# 5. Запустить приложение, которое ходит в базу через host.docker.internal
docker run -d --name ${PREFIX}-web \
  --add-host host.docker.internal:host-gateway \
  -p ${PUB_PORT}:${INNER_PORT} \
  -e APP_PORT=${INNER_PORT} \
  -e MARKER=${MARKER} \
  -e DATABASE_URL=mysql://root:lab@host.docker.internal:${DB_PORT}/lab \
  ${IMAGE}

# 6. Подождать готовности базы (до 60 секунд)
SECONDS=0
until curl -sf -m 3 localhost:${PUB_PORT}/notes > /dev/null || [ $SECONDS -ge 60 ]; do
  sleep 2
done

curl -s localhost:${PUB_PORT}/notes | python3 -m json.tool --no-ensure-ascii
echo
echo "Стенд поднят. Открой http://localhost:${PUB_PORT}/me"

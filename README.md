# antonLytkin18_microservices
antonLytkin18 microservices repository

[![Build Status](https://travis-ci.com/otus-devops-2019-02/antonLytkin18_microservices.svg?branch=master)](https://travis-ci.com/otus-devops-2019-02/antonLytkin18_microservices)

### Домашнее задание №12

1. Для сохранения списка образов в файл, необходимо выполнить команду:

`$ docker images > docker-monolith/docker-1.log`

2. Основные различия между образом и контейнером описаны в файле `docker-monolith/docker-1.log`.

### Домашнее задание №13

1.1. Для создания инстанса в GCP и дальнейших манипуляций с ним с помощью `docker-machine`, необходимо выполнить команды:

`$ export GOOGLE_PROJECT=docker-245017`
````
$ docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-zone europe-west1-b \
    docker-host
````

1.2. Для того, чтобы открыть порт `9292` для доступа извне, необходимо выполнить команду:
````
$ gcloud compute firewall-rules create reddit-app \
     --allow tcp:9292 \
     --target-tags=docker-machine \
     --description="Allow PUMA connections" \
     --direction=INGRESS 
````

1.3. Сменить хост на удаленный:

`$ eval $(docker-machine env docker-host)`

1.4. Скачать заранее подготовленный образ и запустить контейнер с приложением:

`$ docker run --name reddit -d -p 9292:9292 antonlytkin/otus-reddit:1.0`

2.1. Перед сборкой образа `packer`'ом, необходимо скачать сторонние роли `ansible`:

`$ ansible-galaxy install -r docker-monolith/infra/ansible/requirements.yml`

`$ packer build -var-file docker-monolith/infra/packer/variables.json docker-monolith/infra/packer/docker.json`

2.2. Для создания инстанса с установленным `docker`'ом, необходимо воспользоваться командой:

`$ cd docker-monolith/infra/terraform/ && terraform init && terraform apply`

2.3. Для деплоя приложения необходимо выполнить команду:

`$ cd docker-monolith/infra/ansible/ && ansible-playbook playbooks/deploy.yml`

### Домашнее задание №14

1. Для переопределения переменных окружения, заданных в `Dockerfile`'е, необходимо воспользоваться параметром `-e`:

````
$ docker run -d --network=reddit --network-alias=post_db_another --network-alias=comment_db_another mongo:latest
$ docker run -d --network=reddit --network-alias=post_another -e POST_DATABASE_HOST=post_db_another antonlytkin/post:1.0
$ docker run -d --network=reddit --network-alias=comment_another -e COMMENT_DATABASE_HOST=comment_db_another antonlytkin/comment:1.0
$ docker run -d --network=reddit -p 9292:9292 -e POST_SERVICE_HOST=post_another -e COMMENT_SERVICE_HOST=comment_another antonlytkin/ui:1.0
````

2. Для создания отдельного хранилища и подключения его к контейнеру, необходимо выполнить команды:

````
$ docker volume create reddit_db
$ docker run -d --network=reddit --network-alias=post_db_another --network-alias=comment_db_another -v reddit_db:/data/db mongo:latest
```` 

### Домашнее задание №15

1. Для изменения префикса сущностей при запуске контейнеров с помощью `docker-compose`, необходимо выполнить команду:

`$ docker-compose -p my_reddit up -d`

Однако следует помнить, что остановка запущенных контейнеров должна производиться с указанием того же префикса.

Иначе `docker-compose` будет пытаться найти контейнеры в сетях, имеющих префикс по умолчанию:

`$ docker-compose -p my_reddit down`

2. Чтобы иметь возможность редактирования кода, необходимо в `docker-compose.override.yml` добавить соответствия томов для каждого из инстансов:
````dockerfile
volumes:
  - ./ui:/app
````
3. Для запуска `puma` в режиме отладки, необходимо для каждого инстанса добавить конструкцию `command` в `docker-compose.override.yml`:
````dockerfile
command: ["puma", "--debug", "-w", "2"]
````

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

### Домашнее задание №16

1. Для создания инстанса под gitlab, необходимо выполнить команды:
````bash
$ export GOOGLE_PROJECT=docker-245017
$ docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-zone europe-west1-b \
    gitlab-host
````
2. Открываем необходимые для `Gitlab`'а порты:
````bash
$ gcloud compute firewall-rules create gitlab-app \
     --allow tcp:80,tcp:443,tcp:2222\
     --target-tags=docker-machine \
     --description="Allow Gitlab connections" \
     --direction=INGRESS 
````

3. Добавляем переменную окружения, хранящую `ip` инстанса. Будет использоваться в `docker-compose.yml`:
`$ export GITLAB_HOST=$(docker-machine ip gitlab-host)`

4. Запускаем контейнеры:
````bash
$ eval $(docker-machine env gitlab-host)
$ docker-compose up -d
````

5. Запускаем контейнер с `runner`'ом, который будет запускать команды для всех стадий `pipeline`'а:
````bash
$ docker run -d --name gitlab-runner --restart always \
    -v /srv/gitlab-runner/config:/etc/gitlab-runner \
    -v /var/run/docker.sock:/var/run/docker.sock \
    gitlab/gitlab-runner:latest 
````

6. Запускаем `runner` и вводим все запрашиваемые параметры:

`$ docker exec -it gitlab-runner gitlab-runner register --run-untagged --locked=false`

7. Для того, чтобы `runner` смог поднять контейнер в `docker`'е, необходимо сделать доступным файл сокета путем замены строк в файле конфигурации `runner`'а:

`$ sed -i 's/volumes = \["\/cache"]/volumes = ["\/var\/run\/docker.sock:\/var\/run\/docker.sock", "\/cache"]/g' /srv/gitlab-runner/config/config.toml`

8. Добавляем переменные, используемые в `.gitlab.ci.yml` в настройках `Gitlab`'а:
````dotenv
DOCKER_HUB_USERNAME
DOCKER_HUB_PASSWORD
VERSION
SSH_PRIVATE_KEY
STAGING_IP
````

9. При каждом пуше будет запущена сборка `docker`-образа и по требованию деплой окружения `stage`.

### Домашнее задание №17

1. Создадим правила файрвола и инстанс в GCP, после чего подключимся к удаленному окружению:
````bash
$ gcloud compute firewall-rules create prometheus-default --allow tcp:9090
$ gcloud compute firewall-rules create puma-default --allow tcp:9292
$ export GOOGLE_PROJECT=docker-245017
$ docker-machine create --driver google \
      --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
      --google-machine-type n1-standard-1 \
      --google-zone europe-west1-b \
      docker-host
$ eval $(docker-machine env docker-host)
````

2. Соберем образ `mongodb-exporter`:
````bash
$ git clone https://github.com/percona/mongodb_exporter.git && cd mongodb_exporter/ && make docker
$ cd ../ && rm -rf mongodb_exporter/
````

3. Соберем образ `blackbox-exporter`:
````bash
$ docker build -t $USER_NAME/blackbox-exporter monitoring/blackbox-exporter
````

4. Соберем образ `prometheus`:
````bash
$ export USER_NAME=antonlytkin
$ docker build -t $USER_NAME/prometheus monitoring/prometheus
````

5. Запустим контейнеры:
````bash
$ cd docker/ && docker-compose up -d
````

6. Образы хранятся в [DockerHub'е](https://cloud.docker.com/u/antonlytkin/).

### Домашнее задание №18

1. Создадим необходимые переменные окружения, правила файрвола и инстанс в GCP, после чего подключимся к удаленному окружению:
````bash
$ export GOOGLE_PROJECT=docker-245017
$ export USER_NAME=antonlytkin

$ gcloud compute firewall-rules create cadvisor-default --allow tcp:8080
$ gcloud compute firewall-rules create grafana-default --allow tcp:3000
$ gcloud compute firewall-rules create alertmanager-default --allow tcp:9093

$ docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-zone europe-west1-b \
    docker-host

$ eval $(docker-machine env docker-host)
````

2. Соберем необходимые образы:
````bash
$ docker build -t $USER_NAME/alertmanager monitoring/alertmanager
$ docker build -t $USER_NAME/blackbox-exporter monitoring/blackbox-exporter

$ git clone https://github.com/percona/mongodb_exporter.git && cd mongodb_exporter/ && make docker
$ cd ../ && rm -rf mongodb_exporter/
````

3. Для того, чтобы получать метрики от `docker`'а напрямую, необходимо подключиться к удаленной машине и создать файл
`/etc/docker/daemon.json` со следующим содержимым:

````json
{
  "metrics-addr" : "0.0.0.0:9323",
  "experimental" : true
}

````

После чего перезагрузить `docker`:

`$ service docker restart`

4. Для того, чтобы `prometheus` мог отслеживать метрики от `docker`'а, необходимо добавить строки в `prometheus.yml`:

````yaml
  - job_name: "docker"
    static_configs:
      - targets:
          - "172.17.0.1:9323"
````

После чего пересобрать образ `prometheus`'а:

`$ docker build -t $USER_NAME/prometheus monitoring/prometheus`

5. Для `grafana` был импортирован `dashboard`, работающий с метриками `docker`'а:

`monitoring/grafana/dashboards/DockerEngineMetrics.json`

6. Запустим контейнеры с микросервисами и мониторингом:
````bash
$ cd docker/ && docker-compose up -d && docker-compose -f docker-compose-monitoring.yml up -d
````

7. Собранные образы хранятся в [DockerHub'е](https://cloud.docker.com/u/antonlytkin/).

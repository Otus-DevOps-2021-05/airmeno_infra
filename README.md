# Lesson 5 (cloud bostion)


## Задание

1. Подключение через бастион хост
2. Подключение к `someinternalhost` в одну команду
3. Дополнительное задание: подключение из консоли при помощи команды 
вида `ssh someinternalhost` из локальной консоли рабочего устройства

4. VPN-сервер для серверов Yandex.Cloud
5. Дополнительное задание: валидный сертификат для панели управления VPNсервера

## Решение
<details>
  <summary>Решение</summary>

### Подключение через бастион хост

```
bastion_IP = 178.154.246.27
someinternalhost_IP = 10.128.0.24
```


### Подключение к `someinternalhost` в одну команду

```
ssh -At appuser@bostion.ip ssh appuser@someinternalhost.ip

ssh -i ~/.ssh/appuser -A -J appuser@bostion.ip appuser@someinternalhost.ip

ssh -A -J appuser@bostion.ip appuser@someinternalhost.ip
```

### 3. Дополнительное задание: подключение из консоли при помощи команды вида `ssh someinternalhost` из локальной консоли рабочего устройства

Для подключения командой `ssh someinternalhost` создаем файл `~/.ssh/config` с содержанием:

```
host someinternalhost
HostName bostion.ip
Port 22
User appuser
Identityfile ~/.ssh/appuser
RequestTTY force
RemoteCommand ssh someinternalhost.ip
ForwardAgent yes
```

### 4. VPN-сервер для серверов Yandex.Cloud

С официального сайта забираем файл установки pritunl:

```
sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list << EOF
deb https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse
EOF

sudo tee /etc/apt/sources.list.d/pritunl.list << EOF
deb https://repo.pritunl.com/stable/apt focal main
EOF

sudo apt-get --assume-yes install gnupg
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
sudo apt-get update
sudo apt-get --assume-yes install pritunl mongodb-org
sudo systemctl start pritunl mongod
sudo systemctl enable pritunl mongod
```

Устанавливаем:

```
sudo bash setupvpn.sh
```

Следуем инструкциям установщика по адресу:
```
https://<адрес bastion VM>/setup
```

После настройки создаем пользователя `test` с PIN `6214157507237678334670591556762`, добавлем сервер и организацию и включаем в организацию пользователя и сервер.

Файл настройки клиента VPN (пользователь = test) - [cloud-bostion.ovpn](cloud-bostion.ovpn)

### 5. Дополнительное задание: валидный сертификат для панели управления VPNсервера

Домен для bostion - 178-154-246-27.sslip.io

Доступ к printunl - https://178-154-246-27.sslip.io

![Image 1](images/bostion1.png)

![Image 2](images/bostion2.png)

</details>


# Lesson 6 (YC App Deploy)

## Задание

1. Установим и настроим yc CLI для работы с нашим аккаунтом;
2. Создадим хост с помощью CLI;
3. Установим на нем ruby для работы приложения;
4. Установим MongoDB и запустим;
5. Задеплоим тестовое приложение, запустим и проверим его работу.

6. Дополнительное задание: созданиe startup script, который будет запускаться при создании инстанса.

## Решение
<details>
  <summary>Решение</summary>

### 1. Установим и настроим yc CLI для работы с нашим аккаунтом

Установим:
```
curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

Проиницилизируем и создадим профиль (по-умолчанию):

```
yc init
```

Вводим имя нашего  аккаунта на Яндекс Облако, получаем токен, далее создаем профиль, выбираем каталог созданный в профиле "облака" и зону размещения.

Прверим наш профиль:
```
yc config profile get <имя профиля>
```
Имя профиля = default


Некоторые команды для управления инстансами в YC:

```
yc compute instance list

yc compute instance start/stop <INSTANCE-NAME>

yc compute instance delete <INSTANCE-NAME>

yc compute instance get --full <INSTANCE-NAME>
```

### 2. Создадим хост с помощью CLI

```
yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --ssh-key ~/.ssh/appuser.pub
```

Необходимые данные
```
testapp_IP = 178.154.203.173
testapp_port = 9292
```

### Задачи с 3 по 5 пункты

 - [install_ruby.sh](install_ruby.sh)
 - [install_mongodb.sh](install_mongodb.sh)
 - [deploy.sh](deploy.sh)


Сделаем скрипты исполняемыми:

```
chmod +x *.sh
```

### 6. Дополнительное задание: созданиe startup script, который будет запускаться при создании инстанса

Объеденим скрипты в единый и оптимизируем исполнение:


[startup-script.sh](startup-script.sh)
```
#!/bin/bash

wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

sudo apt-get update
sudo apt-get install -y ruby-full ruby-bundler build-essential mongodb-org git

sudo systemctl enable --now mongod

git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
```

Создадим файл с метаданными [metadata.yaml](metadata.yaml) и команду для создания инстанса:

```
yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --metadata-from-file user-data=metadata.yaml
```

После создания инстанса автоматически будет выполнен заданный скрипт. 

</details> 


# Lesson 7 (YC Packer)

## Задание

1. Создание новой ветки
2. Установка Packer
3. Создание сервисного аккаунта на YC
4. Подготовка и сборка образа с помощью Packer

5. `*` Построение bake-образа
6. `*` Автоматизация создания ВМ

## Решение
<details>
  <summary>Решение</summary>

### 1. Создание новой ветки

Создаем новую ветку в репозитории и переносим в директорию config-scripts все скрипты из предыдущего задания:

```
git checkout -b packer-base

git mv *.sh config-scripts/ && git mv metadata.yaml config-scripts/
```

### 2. Установка Packer 

https://www.packer.io/downloads

```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer
```

Проверим:

```
$  packer -v

1.7.3
```

### 3. Сервсиный аккаунт для Packer

Получим данные для нашего YC:

```
yc config list
```

Из параметров нужен `folder-id`. Создаем переменные для окружения (будем использовать в разных местах):

```
SVC_ACCT="packer-user"
FOLDER_ID="folder-id_from_config"
```

Создаем сервисный аккаунт:

```
yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID
```

Если посмотреть в YC => Каталог => Сервисные аккаунты, то увидим, что пользователь создан, но у него нет роли. Назначить роль можно через веб, но создадим через консоль:

```
ACCT_ID=$(yc iam service-account get $SVC_ACCT | grep ^id | awk '{print $2}')

yc resource-manager folder add-access-binding --id $FOLDER_ID --role editor --service-account-id $ACCT_ID
``` 

Если проверить через веб, можно убедиться, что `packer-user` уже имеет роль `editor`.

**Создаем service account key file**

Создаем и сохраняем за переделами репозитория IAM key:
```
yc iam key create --service-account-id $ACCT_ID --output ~/key.json
```

### 4. Подготовка и сборка образа с помощью Packer

**Создание файла-шаблона Packer**

Создаем директорию `packer` и внутри файл `ubuntu16.json`. Создаем builders и provisioners


```
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "~/key.json",
            "folder_id": "b1gqsnnn5lhvmg8osug4",
            "source_image_family": "ubuntu-1604-lts",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1"
        }
    ]
}

{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "~/key.json",
            "folder_id": "folder-id_from_config",
            "source_image_family": "ubuntu-1604-lts",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1",
            "use_ipv4_nat": "true"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

Скопируем скрипты в указанные директории из `ubuntu16.json`.

Выполним проверку на синтаксис:

```
packer validate ./ubuntu16.json
```

**Вероятные ошибки:**

```
==> yandex: Error creating network: server-request-id = b8b864e7-e820-4279-9d77-c4bc141ec3ec server-trace-id = d4660b864ca49486:a91e4f7eb2529a2b:d4660b864ca49486:1 client-request-id = 407e35ae-ca89-43c0-8b47-d974ef6029a6 client-trace-id = ae43a2fb-40e8-43b2-9aaf-125ecb4a8f59 rpc error: code = ResourceExhausted desc = Quota limit vpc.networks.count exceeded
Build 'yandex' errored after 1 second 523 milliseconds: Error creating network: server-request-id = b8b864e7-e820-4279-9d77-c4bc141ec3ec server-trace-id = d4660b864ca49486:a91e4f7eb2529a2b:d4660b864ca49486:1 client-request-id = 407e35ae-ca89-43c0-8b47-d974ef6029a6 client-trace-id = ae43a2fb-40e8-43b2-9aaf-125ecb4a8f59 rpc error: code = ResourceExhausted desc = Quota limit vpc.networks.count exceeded
```

Удалим все созданные сети (подсети).

```
==> yandex: Provisioning with shell script: scripts/install_ruby.sh

...

==> yandex:
==> yandex: WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
==> yandex:
==> yandex: E: Could not get lock /var/lib/dpkg/lock-frontend - open (11: Resource temporarily unavailable)
==> yandex: E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), is another process using it?
```

Говорит о том, что apt чем-то занят и не может залочить для установки другого пакета. Посмотрим скрипт `install_ruby.sh`. Предположительно `apt update` не успел закочить процесс, а `apt install` уже пытается установить. Сделаем паузу между этими командами:

```
echo "Sleep 30 sec for apt update"; sleep 30s; echo "start apt install"

```

**Проверка образа**

Создаем ВМ на основе нашего образа и ставим reddit:

```
sudo apt-get update
sudo apt-get install -y git
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
```

http://vm_ip_adress:9292 

**Параметризирование шаблона**

Создаем `variables.json`, `.gitignore` файлы и для коммита в репозиторий `variables.json.examples`. В gitignore включаем variables.json.

```
$ cat variables.json.examples

{
  "key": "key.json",
  "folder_id": "folder-id_from_config",
  "image": "ubuntu-1604-lts"
}
```

Вносим изменения в файл [ubuntu16.json](packer/ubuntu16.json).


Проверим и запустим сборку:

```
packer validate -var-file=./variables.json ./ubuntu16.json
packer build -var-file=./variables.json ./ubuntu16.json
```

### 5. Построение bake-образа `*`

На основе ubuntu16.json создадим immutable.json и заменим требуемые значения согласно инструкции.

Напишем [systemd unit](packer/files/puma.service) для запуска puma. Подготивим [immutable.json](packer/immutable.json).

Проверим и запустим сборку:

```
packer validate -var-file=./variables.json ./immutable.json
packer build -var-file=./variables.json ./immutable.json
```

Проверим наши имиджы и запомним id, он понадобится для скрипта `config-scripts/create-reddit-mv.sh`:

```
yc compute image list
```

После сборки создадим сеть и подсети, поскольку мы удалили из-за ошибки в сборке и ограничений в ЯО, можно через веб или:

```
yc vpc network create --name default
```

Не забываем создавать подсети:

```
 yc vpc subnet create --name test-subnet-1 \
  --description "My test subnet" \
  --folder-id b1g6ci08ma55klukmdjs \
  --network-id enplom7a98s1t0lhass8 \
  --zone ru-central1-b \
  --range 192.168.0.0/24
```
> https://cloud.yandex.ru/docs/vpc/operations/subnet-create


### 6. Автоматизация создания ВМ `*`

Cкрипт создания ВМ [create-reddit-mv.sh](config-scripts/create-reddit-vm.sh)

</details>  

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


# Lesson 5 (YC App Deploy)

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
testapp_IP = 178.154.230.100
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

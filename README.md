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

Cкрипт создания ВМ [create-reddit-vm.sh](config-scripts/create-reddit-vm.sh)

</details>  

# Lesson 8 (YC Terraform 1)

## Задание

1. Установка Terraform и создание инфраструктуры
2. Создание ВМ с помощью Terraform
3. Входные переменные Terraform

4. Балансировщик на 2 инстанса `*`

## Решение
<details>
  <summary>Решение</summary>

### 1. Установка Terraform 

Установим terraform требуемой версии (0.12.8):

```
wget https://releases.hashicorp.com/terraform/0.12.8/terraform_0.12.8_linux_amd64.zip
unzip terraform_0.12.8_linux_amd64.zip

sudo mv terraform /usr/local/bin; rm terraform_0.12.8_linux_amd64.zip
```
Проверим:

```
$ terraform -v

Terraform v0.12.8
```

Создаем директорию `terraform` и файл внутри файл `main.tf`. Редактируем файл `.gitignore`

```
...


*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform/
```

Для работы Terraform создадим сервисный аккаунт `terraform`:

```
yc config list

FOLDER_ID="folder-id_from_config"

уc iam service-account create --name terraform --folder-id $FOLDER_ID

yc resource-manager folder add-access-binding --id $FOLDER_ID --role editor --service-account-id $(yc iam service-account get terraform | grep ^id | awk '{print $2}')

yc iam key create --service-account-id terraform_user_id --output ~/terraform.json
```

Редактируем файл `main.tf`:

```
provider "yandex" {
  version   = 0.35
  token     = "<OAuth или статический ключ сервисного аккаунта>"
  cloud_id  = "<идентификатор облака>"
  folder_id = "<идентификатор каталога>"
  zone      = "ru-central1-a"
}
```

параметры для файла:

```
yc config list
```

Проводим инициализацию, будет загружен провайдер указанный в mian.tf (yandex):

```
terraform init
```

### 2. Создание ВМ с помощью Terraform


Добавим требуемые условия (согласно инструкции) для создания новой ВМ в `main.tf` и даем комманды:

```
terraform plan

terraform apply
```

Подправим ошибку в конфигурации:

```
...
  resources {
    cores  = 2
    memory = 2
  }
...
```

добавим подключение по ssh, в `main.tf`:

```
metadata = {
  ssh-keys = "ubuntu:${file("~/.ssh/appuser.pub")}"
}
```

и еще раз `terraform apply`

```
$ terraform show | grep nat_ip_address
        nat_ip_address = "217.28.231.223"
$ shh ubuntu@217.28.231.223
```

Успешно подключились.

Создадим новый файл `outputs.tf` для вывода информации о создоваемый ВМ, чтоб каждый раз не использовать `terraform show`

```
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```

и проверим:

```
terraform refresh

terraform output
```

**Создаем Provisioner**

Добавляем в `main.tf` два provisioner-а:

```
provisioner "file" {
  source = "files/puma.service"
  destination = "/tmp/puma.service"
}
```
[files/puma.service](terraform/files/puma.service) это systemd unit файл и:

```
provisioner "remote-exec" {
  script = "files/deploy.sh"
}
```
[files/deploy.sh](terraform/files/deploy.sh) это скрипт установки приложения.


Парметры подключения провиженеров к ВМ:

```
connection {
    type = "ssh"
    host = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file("~/.ssh/yc")
    }

```

Применим наши изменения:

```
terraform taint yandex_compute_instance.app
terraform plan
terraform apply
```

После успешного выполенения получим:

```
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

external_ip_address_app = 217.28.231.189
```

Наш сервис доступен http://217.28.231.189:9292

### 3. Входные переменные Terraform

Определим наши входные переменные. Создадим файл [variables.tf](terraform/variables.tf) и определим параметры в `main.tf`:

```
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
```

и 

```
  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

```

Создаем файл `terraform.tfvars`, из которого загружаются значения автоматически при каждом запуске:

```
cloud_id = "b1g7mh55020i2hpup3cj"
folder_id = "b1g4871feed9nkfl3dnu"
zone = "ru-central1-a"
image_id = "fd8mmtvlncqsvkhto5s6"
public_key_path = "~/.ssh/appuser.pub"
subnet_id = "e9bem33uhju28r5i7pnu"
service_account_key_file = "key.json"
```

Пересоздадим все ресурсы созданные при помощи terraform:

```
terraform destroy

terraform plan
terraform apply
```


### 4. Балансировщик на 2 инстанса `*`

Создаем файл `lb.tf`, внитури блок целевой группы (target group):

```
resource "yandex_lb_target_group" "reddit_target_group" {
  name      = "reddit-lb-group"
  folder_id = var.folder_id
  region_id = var.region_id

  target {
    address = yandex_compute_instance.app.network_interface.0.ip_address
      subnet_id = var.subnet_id
  }
}
```

и создаем сам балансировщик соедененный с целевой группой:

```
resource "yandex_lb_network_load_balancer" "lb" {
  name = "reddit-lb"
  type = "external"

  listener {
    name        = "listener"
    port        = 80
    target_port = 9292

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.reddit_target_group.id

    healthcheck {
      name = "tcp"
      tcp_options {
        port = 9292
      }
    }
  }
}
```

Для удобства балансировщик слушает порт 80 и передает на порт нашего приложения 9292.

Посмотреть балансировщики:

```
yc load-balancer target-group list

yc load-balancer network-load-balancer list
```

> https://cloud.yandex.ru/docs/network-load-balancer/operations/internal-lb-create
> https://registry.terraform.io/providers/yandex-cloud/yandex/0.44.0/docs/resources/lb_network_load_balancer
> https://registry.terraform.io/providers/yandex-cloud/yandex/0.44.0/docs/resources/lb_target_group


Добавим переменную на вывод external IP для балансировщика:

``` 
output "loadbalancer_ip_address" {
  value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
}
```

Дадим команду на сборку:

```
terraform plan

terraform apply
```

Проверим, что наше приложение доступно по адресу балансировщика.

Добавим еще один инстанс **reddit-app2**:

в `main.tf`:
```
resource "yandex_compute_instance" "app2" {
  name  = "reddit-app2"

...
```

в `outputs.tf` заменим на:

```
output "external_ip_address_app" {
  value = yandex_compute_instance.app[*].network_interface.0.nat_ip_address
}
```

в `lb.tf` добавим еще один таргет:

```
target {
  address = yandex_compute_instance.app2.network_interface.0.ip_address
  subnet_id = var.subnet_id
}
```

> Возможная ошибка:

```
Error: error executing "/tmp/terraform_2015131243.sh": Process exited with status 100
```
Установим паузу на выполнение скрипта 30 сек.


**Создаем ВМ с помощью count**

Добавим переменную в `variables.tf` со занчением по умолчанию = 1: 

```
variable instance_count {
  description = "count instances"
  default     = 1
}
```

в `main.tf` удалим параметы для **reddit-app2** и добавим:

```
resource "yandex_compute_instance" "app" {
  name  = "reddit-app-${count.index}"
  count = var.instance_count

...

  connection {
    type  = "ssh"
    host  = self.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }
```

в `lb.tf` заменим значения target на dynamic:

```
  dynamic "target" {
    for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
    content {
      subnet_id = var.subnet_id
      address   = target.value
    }
  }
```

Теперь меняя значение переменно `instance_count` можно получать данное значение инстансов за балансировщиком.

> https://www.terraform.io/docs/language/expressions/dynamic-blocks.html
> https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each


```
terraform plan

terraform apply -auto-approve
```

Плюсы динамического расширения и балансировки:
* не надо писать много кода (вероятность опечатки и ошибки);
* легко масштабировать.

Минусы для данного решения:
* нет общей базы mongodb (при потере инстанса, теряем и его базу).

</details>

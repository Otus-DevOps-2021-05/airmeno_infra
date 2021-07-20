[![Build Status](https://travis-ci.com/Otus-DevOps-2021-05/airmeno_infra.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2021-05/airmeno_infra)

# Lesson 12 (Ansible 3)

## Работа с ролями и окружениями

<details>
  <summary>Решение</summary>

1. Создаем инфраструктуру под роли:
```
ansible-galaxy init app
ansible-galaxy init db
```
Переносим наши плейбуки в роли, модифицируем плейбуки в запуск роли.

2. Переносим наши переменнные окружения `ansible/environments` в две директории окружений `stage` и `prod`.

3. Модифицируем ansible.cfg.

4. Директорию `ansible` организуем согласно Best Practices.

5. Из Ansible Galaxy используем роль `jdauphant.nginx` и настраиваем обратное проксирование с помощью nginx.

Создадим файлы `environments/stage/requirements.yml` и `environments/prod/requirements.yml` и добавим:
```
- src: jdauphant.nginx
  version: v2.21.1
```
Установим роль:
```
ansible-galaxy install -r environments/stage/requirements.yml
```
Добавим переменные в `stage/group_vars/app` и `prod/group_vars/app`

```
nginx_sites:
  default:
    - listen 80
    - server_name "reddit"
    - location / {
        proxy_pass http://127.0.0.1:9292;
      }
```

Добавим вызов роли jdauphant.nginx в плейбук `app.yml`. Применим плейбук `ansible-playbook playbooks/site.yml` и убедимся что наша служба доступна на 80-м порту.

6. Работа с Ansible Vault

Подготовим необходимое окружение, создадим файл `vault.key` в `~/.ansible/` и зашифруем наши файлы с паролями пользователей:

```
ansible-vault encrypt environments/prod/credentials.yml
ansible-vault encrypt environments/stage/credentials.yml
```
Убедимся, что файлы зашифрованы и добавим вызов плейбука в файл `site.yml`.

### Задание со ⭐: Работа с динамическим инвентори

Чтоб не вводить каждый раз переменную `db_host:` в `ansible/environments/stage/group_vars/app` сделаем его динамически определеямой в [inventory.json](ansible/environments/prod/inventory.json).  


### Задание со ⭐⭐: Настройка TravisCI

Модифицируем `.travis.yml`. 

Для проверок TravisCI нам нужна аналогичная инфраструктура с packer, ansible, terraform:

```
ansible --version
ansible 2.10.5

terraform -v
Terraform v0.12.8

packer -v
1.7.3
```
установим:

```
sudo apt-get update
sudo apt-get install pip
sudo pip install ansible==2.10.5
sudo pip install ansible-lint
sudo apt-get install unzip git -y
wget https://releases.hashicorp.com/terraform/0.12.8/terraform_0.12.8_linux_amd64.zip
sudo unzip terraform_0.12.8_linux_amd64.zip -d /usr/local/bin
wget https://releases.hashicorp.com/packer/1.7.3/packer_1.7.3_linux_amd64.zip
sudo unzip -o packer_1.7.3_linux_amd64.zip -d /usr/local/bin
curl https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
tflint -v
ansible-lint --version
terraform --version
packer --version
```

и добавим наши проверки:

```
- echo "Prepared to validate"
- /usr/local/bin/packer validate -var-file=packer/variables.json.example packer/app.json
- /usr/local/bin/packer validate -var-file=packer/variables.json.example packer/db.json
- cd packer
- /usr/local/bin/packer validate -var-file=variables.json.example ubuntu16.json
- /usr/local/bin/packer validate -var-file=variables.json.example immutable.json
- cd ../terraform/stage
- mv backend.tf backend.tf.example
- terraform init
- terraform validate
- tflint
- cd ../prod
- mv backend.tf backend.tf.example
- terraform init
- terraform validate
- tflint
- cd ../../ansible/playbooks
- ansible-lint playbooks/app.yml
- ansible-lint playbooks/clone.yml
- ansible-lint playbooks/db.yml
- ansible-lint playbooks/deploy.yml
- ansible-lint playbooks/packer_app.yml
- ansible-lint playbooks/packer_db.yml
- ansible-lint playbooks/reddit_app_multiple_plays.yml
- ansible-lint playbooks/reddit_app_one_play.yml
- ansible-lint playbooks/site.yml
- ansible-lint playbooks/users.yml
- ansible-galaxy install -r environments/stage/requirements.yml
```

Добавим бейдж со статусом билда в README.md. 

</details>

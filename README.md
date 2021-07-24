[![Build Status](https://travis-ci.com/Otus-DevOps-2021-05/airmeno_infra.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2021-05/airmeno_infra)

# Lesson 13 (Ansible 4)

## Разработка и тестирование Ansible ролей и плейбуков


* Локальная разработка при помощи Vagrant, доработка ролей для провижининга в Vagrant
* Тестирование ролей при помощи Molecule и Testinfra
* Переключение сбора образов пакером на использование ролей
* ⭐ Подключение Travis CI для автоматического прогона тестов

<details>
  <summary>Решение</summary>

### Локальная разработка при помощи Vagrant, доработка ролей для провижининга в Vagrant

Установим vagrant любым удобным способом - https://www.vagrantup.com/downloads, в качестве провайдера virtualbox. У меня установлены через apt.

```
vagrant -v 

Vagrant 2.2.17
```

Создаем vagrantfile и запускаем создание инфраструктуры:

```
vagrant up

vagrant status
```

Дорабатываем наши роли согласно инструкции и проверям наши провиженеры:

```
vagrant provision dbserver
vagrant provision appserver
```

Тестируем достпуность mongo от appserver:

```
vagrant ssh appserver

telnet 10.10.10.10 27017
```

Исправим пользователя `ubuntu` на `vagrant` поскольку vagrant по умаолчанию провижн запускает от имени юзера `vagrant`.

⭐ В Vagrant в виде переменной передим настройки для nginx proxy_pass:

```
nginx_sites: {
  default: ["listen 80", "server_name 'puma'", "location / {proxy_pass http://127.0.0.1:9292;}"]
}  
```

### Тестирование ролей при помощи Molecule и Testinfra

Создаем окружение - https://docs.python-guide.org/dev/virtualenvs/ и установим необходимые пакеты:

```
molecule init scenario --scenario-name default -r db -d vagrant
```

Производим тесты.

В tests/test_default.py допишем нашу проверку порта 27017:

```
# check mongodb port
def test_mongo_port(host):
    socket = host.socket('tcp://0.0.0.0:27017')
    assert socket.is_listening
```

### Переключение сбора образов пакером на использование ролей

Редактируем наши плейбуки packer_db.yml и packer_app.yml, вместо тасков подключаем роли. Приводим к виду в app.json и db.json в директории packer наш провиженер: 
```
{
    "type": "ansible",
    "playbook_file": "ansible/playbooks/packer_app.yml",
    "user": "ubuntu",
    "extra_arguments": ["--tags","ruby"],
    "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"] 
}
```
</details>

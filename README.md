# Laravel Starter Pack by mv

### Before start be sure your host machine meets the prerequisites

Latest versions of *git*, *docker*, *docker-compose* and *make*. Check it by running following commands:

```
git --version
docker -v
docker-compose -v
make -v
```

### How to start developing

#### Easy way

##### Fresh project

1. For initialize project you can start configuration rule:

```
make init-project
```

2. Set up .env in *app* path ( Laravel configuration file )

##### Existing project

1. Copy your laravel project into *app* path

2. Configure main env file

```
make configure-env
```

3. Build containerts and start that

```
make docker-build
```

#### Hard way

For launch development environment run following steps:

1. Set up .env file in *mapstrom* path

```
**SITE_PORT** - port for HTTP 
**SECURE_SITE_PORT** - port for HTTPS  
**MYSQL_ROOT_PASSWORD** - password for root user  
**MYSQL_DATABASE** - database name  
**MAILHOG_WEB_PORT** - MailHog webinterface port
```

2. Set up .env in *mapstrom/app* path ( Laravel configuration file )

3. Build and start project:

```
make docker-build
```

4. Quick DB setuping:

```
make init-db
```

### Useful tips

- Will be later
- You can find all commands, just type:
```
make help
```
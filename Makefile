.DEFAULT_GOAL := help

-include .env

GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
YEL="\033[0;33m"
NC="\033[0m"

build_laravel_root_dev 	:= "npm run dev; exit;"
build_laravel_root_prod := "npm run prod; exit;"

db_run_migrations		:= "php artisan migrate; exit;"

fresh_laravel_commands  := "cd /; composer create-project --prefer-dist laravel/laravel lartmp; cp -r /lartmp/. /application/; rm -rf /lartmp; chown -R www-data:www-data /application"

v1 						:= "docker-compose ps"
v2						:= "docker-compose ps; docker-compose top"
v3						:= "docker-compose ps; docker-compose top; docker-compose logs"

PROJECT_NAME			:= $(@shell grep 'PROJECT_NAME' .env | sed -e "s/^PROJECT_NAME=//" )
DB_NAME					:= $(@shell grep 'MYSQL_DATABASE' .env | sed -e "s/^MYSQL_DATABASE=//" )
DB_ROOT_PASSWORD		:= $(@shell grep 'MYSQL_ROOT_PASSWORD' .env | sed -e "s/^MYSQL_ROOT_PASSWORD=//" )

# BASIC

help:									#*# Avaliable rules.
	@grep -E '(^[a-zA-Z_-]+:.*?#*#.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":|#*#"}; {printf "\033[32m%-30s\033[0m %s\n", $$2, $$5}' | sed -e 's/\[32m##/[33m/' | sort

init-project:							#*# Initialize a new project.
	@echo $(GREEN)"Okay, now we will create new Laravel application!"$(NC)

	@while [ -z "$$CONTINUE" ]; do \
        read -r -p "Are you sure want set up NEW project enviroment? [y/N]: " CONTINUE; \
    done ; \
    [ $$CONTINUE = "y" ] || [ $$CONTINUE = "Y" ] || (echo $(RED)"Exiting..."$(NC); exit 1;)

	make configure-env

	@echo $(GREEN)".env file configured! Let's try start containers..."$(NC)
	docker-compose up -d --build
	@echo $(GREEN)"All containers successfully builded and started!"$(NC)

	make fresh-laravel
	echo $(GREEN)"Done! Now you can manually configure your Laravel env file ( or use 'make configure-laravel-env' ) and start development."$(NC)
	
fresh-laravel:							#*# Download last Laravel version from repo.
	make docker-start
	@echo $(BLUE)"..........ATTENTION.........."$(NC)

	@while [ -z "$$CONTINUE2" ]; do \
        read -r -p "Now we will try upload fresh Laravel into app. Are you sure want continue? [y/N]: " CONTINUE2; \
    done ; \
    [ $$CONTINUE2 = "y" ] || [ $$CONTINUE2 = "Y" ] || (echo $(RED)"Exiting..."$(NC); exit 1;)

	docker-compose exec fpm bash -c $(fresh_laravel_commands) \
	|| docker-compose exec -T fpm bash -c $(fresh_laravel_commands)
	@echo $(PROJECT_NAME)

configure-laravel-env:					#*# Configure Laravel env file according to main env.
	@echo $(BLUE)"..........ATTENTION.........."$(NC)

	@while [ -z "$$CONTINUE2" ]; do \
        read -r -p "Now we will try edit your Laravel env file. Are you sure want continue? [y/N]: " CONTINUE2; \
    done ; \
    [ $$CONTINUE2 = "y" ] || [ $$CONTINUE2 = "Y" ] || (echo $(RED)"Exiting..."$(NC); exit 1;)

	@docker-compose exec fpm bash -c 'sed -i "s/DB_HOST=127.0.0.1/DB_HOST=$(PROJECT_NAME)-mysql/g" /application/.env'
	@echo $(GREEN)
	@printf 'Database Host   \u2714\n'
	@echo $(NC)
	@docker-compose exec fpm bash -c 'sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$(DB_NAME)/g" /application/.env'
	@echo $(GREEN)
	@printf 'Database Name   \u2714\n'
	@echo $(NC)
	@docker-compose exec fpm bash -c 'sed -i "s/DB_PASSWORD=/DB_PASSWORD=$(DB_ROOT_PASSWORD)/g" /application/.env'
	@echo $(GREEN)
	@printf 'Database Password   \u2714\n'
	@echo $(NC)
	@docker-compose exec fpm bash -c 'sed -i "s/MAIL_HOST=smtp.mailtrap.io/MAIL_HOST=$(PROJECT_NAME)-mailhog/g" /application/.env'
	@echo $(GREEN)
	@printf 'Mail Host   \u2714\n'
	@echo $(NC)
	@docker-compose exec fpm bash -c 'sed -i "s/MAIL_PORT=2525/MAIL_PORT=1025/g" /application/.env'
	@echo $(GREEN)
	@printf 'Mail Port   \u2714\n'
	@echo $(NC)

configure-env:							#*# Configure main env file.
	@echo "" > .env;

	@while [ -z "$$PROJECT_NAME" ]; do \
        read -r -p "Choose name of the project: " PROJECT_NAME; \
    done ; \
	echo "PROJECT_NAME="$$PROJECT_NAME >> .env

	@while [ -z "$$SITE_PORT" ]; do \
        read -r -p "Specify HTTP port: " SITE_PORT; \
    done ; \
	echo "SITE_PORT="$$SITE_PORT >> .env

	@while [ -z "$$MYSQL_ROOT_PASSWORD" ]; do \
        read -r -p "Enter MySQL password for root user: " MYSQL_ROOT_PASSWORD; \
    done ; \
	echo "MYSQL_ROOT_PASSWORD="$$MYSQL_ROOT_PASSWORD >> .env

	@while [ -z "$$MYSQL_DATABASE" ]; do \
        read -r -p "Enter name for MySQL database: " MYSQL_DATABASE; \
    done ; \
	echo "MYSQL_DATABASE="$$MYSQL_DATABASE >> .env

	@while [ -z "$$MAILHOG_WEB_PORT" ]; do \
        read -r -p "Choose port for MailHog web interface: " MAILHOG_WEB_PORT; \
    done ; \
	echo "MAILHOG_WEB_PORT="$$MAILHOG_WEB_PORT >> .env

terminal: 								#*# Connect to main container ( fpm ).
	@echo $(BLUE)"Launch into project terminal"$(NC)
	@docker-compose exec fpm bash

# DOCKER

docker-build: 							#*# Build this project.
	@echo $(BLUE)"Build and start all containers for $(PROJECT_NAME)"$(NC)

	@docker-compose up -d --build --remove-orphans
	make docker-stat

docker-kill: 							#*# Remove docker project.
	@echo $(BLUE)"Stop and remove containers, networks, images, and volumes for $(PROJECT_NAME)"$(NC)

	@docker-compose down
	make docker-stat

docker-start: 							#*# Start docker project.
	@echo $(BLUE)"Try to start containers for $(PROJECT_NAME)"$(NC)

	@docker-compose start

docker-stop: 							#*# Stop docker project.
	@echo $(BLUE)"Stop containers for $(PROJECT_NAME)"$(NC)
	
	@docker-compose stop

docker-rebuild: 						#*# Clean rebuild project
	make docker-kill
	make docker-start

docker-stat: 							#*# Containers statistics ( choose verbose mode by argument v 1, 2, 3).
	@echo $(BLUE)"Containers status for $(PROJECT_NAME)"$(NC)
	@if [ -z $(v) ]; then eval $(v1); elif [ $(v) -eq 2 ]; then eval $(v2); else eval $(v3); fi

# TESTS

test: 									#*# Run tests ( all types ).
	@echo $(BLUE)"Start testing for $(PROJECT_NAME)"$(NC)

	make test-phpunit

test-phpunit: 							#*# Run phpunit tests.
	@echo $(BLUE)"Start phpunit tests for $(PROJECT_NAME)"$(NC)

	@docker-compose exec fpm vendor/bin/phpunit

# BUILDS

build-frontend: 						#*# Build front-end ( all cases ).
	@echo $(BLUE)"Build all frontend components"$(NC)

	make build-frontend-laravel

build-frontend-laravel: 				#*# Build front-end for laravel.
	docker-compose exec php-fpm bash -c $(build_frontend_commands) \
	|| docker-compose exec -T php-fpm bash -c $(build_frontend_commands)

# DATABASE

init-db: 								#*# Initialize DB migrations, seeds, Passport clients.
	@echo $(BLUE)"Initialize DB for $(PROJECT_NAME)"$(NC)

	make db-migrations

db-migrations: 							#*# Run migrations.
	@echo $(BLUE)"Run migrations"$(NC)

	docker-compose exec php-fpm bash -c $(db_run_migrations) \
	|| docker-compose exec -T php-fpm bash -c $(db_run_migrations)
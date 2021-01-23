
include .env

build_code:
	docker build -f dockerfiles/base_image -t registry.cn-shenzhen.aliyuncs.com/lost-city/lost_city_backend_base:v1 .

stop_api:
	docker stop lost_city_backend_production

run_api:
	docker run -d --rm \
		-e RAILS_ENV=production \
		-p 3000:3000 \
		-v ${APP_PATH}/.env:/lost_city_backend/.env \
		-v ${APP_PATH}/log:/lost_city_backend/log \
		-v ${APP_PATH}/tmp:/lost_city_backend/tmp \
		--name lost_city_backend_production \
		registry.cn-shenzhen.aliyuncs.com/lost-city/lost_city_backend_base:v1 \
		sh shell/deploy_api.sh

run_deploy:
	docker pull registry.cn-shenzhen.aliyuncs.com/lost-city/lost_city_backend_base:v1 && \
	docker stop lost_city_backend_production && \
	docker run -d --rm \
		-e RAILS_ENV=production \
		-p 3050:3000 \
		-v ${APP_PATH}/.env:/lost_city_backend/.env \
		-v ${APP_PATH}/log:/lost_city_backend/log \
		-v ${APP_PATH}/tmp:/lost_city_backend/tmp \
		--name lost_city_backend_production \
		registry.cn-shenzhen.aliyuncs.com/lost-city/lost_city_backend_base:v1 \
		sh shell/deploy_api.sh


# 单独部署redis
run_redis:
	docker run -d \
		--rm \
		-v ${APP_PATH}/data/redis_data:/data \
		-p 7400:6379 \
		--name lost_city_redis \
		redis:4.0.14 \
		redis-server
# --appendonly yes


# 使用5.7版本
run_mysql:
	docker run -d \
		--rm \
		-p 4336:3306 \
		--name lost_city_mysql \
		-v ${APP_PATH}/data/mysql_data:/var/lib/mysql \
		-e MYSQL_ROOT_PASSWORD=lost_city123 \
		mysql:5.7
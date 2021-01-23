
include .env

build_code:
	docker build -f dockerfiles/base_image -t registry.cn-shenzhen.aliyuncs.com/lost-city/lost_city_backend_base:v1 .

stop_api:
	docker stop lost_city_backend_production

run_api:
	docker run -d --rm \
		-e RAILS_ENV=production \
		-p 3000:3000 \
		-v ${APP_PATH}/.env:/lost-city/backend/.env \
		-v ${APP_PATH}/log:/lost-city/backend/log \
		-v ${APP_PATH}/tmp:/lost-city/backend/tmp \
		--name lost_city_backend_production \
		registry.cn-shenzhen.aliyuncs.com/lost-city/lost_city_backend_base:v1 \
		sh shell/deploy_api.sh

run_deploy:
	podman pull registry.cn-shenzhen.aliyuncs.com/lost-city/lost_city_backend_base:v1 && \
	podman stop lost_city_backend_production && \
	podman run -d --rm \
		-e RAILS_ENV=production \
		-p 3000:3000 \
		-v ${APP_PATH}/.env:/lost-city/backend/.env \
		-v ${APP_PATH}/log:/lost-city/backend/log \
		-v ${APP_PATH}/tmp:/lost-city/backend/tmp \
		--name lost_city_backend_production \
		registry.cn-shenzhen.aliyuncs.com/lost-city/lost_city_backend_base:v1 \
		sh shell/deploy_api.sh

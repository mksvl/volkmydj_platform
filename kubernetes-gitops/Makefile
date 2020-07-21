SHELL = /bin/sh
PREFIX = $(shell pwd)
VERSION=v0.0.1
USER_NAME=volkmydj

export USER_NAME=volkmydj
export VERSION=v0.0.1

### BUild ###
build_addservice:
	cd src/adservice && docker build -t ${USER_NAME}/adservice:${VERSION} .

build_cartservice:
	cd src/cartservice && docker build -t ${USER_NAME}/cartservice:${VERSION} .

build_checkoutservice:
	cd src/checkoutservice && docker build -t ${USER_NAME}/checkoutservice:${VERSION} .

build_currencyservice:
	cd src/currencyservice && docker build -t ${USER_NAME}/currencyservice:${VERSION} .

build_emailservice:
	cd src/emailservice && docker build -t ${USER_NAME}/emailservice:${VERSION} .

build_frontend:
	cd src/frontend && docker build -t ${USER_NAME}/frontend:${VERSION} .

build_loadgenerator:
	cd src/loadgenerator && docker build -t ${USER_NAME}/loadgenerator:${VERSION} .

build_paymentservice:
	cd src/paymentservice && docker build -t ${USER_NAME}/paymentservice:${VERSION} .

build_productcatalogservice:
	cd src/productcatalogservice && docker build -t ${USER_NAME}/productcatalogservice:${VERSION} .

build_recommendationservice:
	cd src/recommendationservice && docker build -t ${USER_NAME}/recommendationservice:${VERSION} .

build_shippingservice:
	cd src/shippingservice && docker build -t ${USER_NAME}/shippingservice:${VERSION} .

build: build_addservice build_cartservice build_checkoutservice build_currencyservice build_emailservice build_frontend build_loadgenerator build_paymentservice build_productcatalogservice build_recommendationservice build_shippingservice


### Push ###

push_adservice:
	docker push ${USER_NAME}/adservice:${VERSION}

push_cartservice:
	docker push ${USER_NAME}/cartservice:${VERSION}

push_checkoutservice:
	docker push ${USER_NAME}/checkoutservice:{VERSION}

push_currencyservice:
	docker push ${USER_NAME}/currencyservice:${VERSION}

push_emailservice:
	docker push ${USER_NAME}/emailservice:${VERSION}

push_frontend:
	docker push ${USER_NAME}/frontend:${VERSION}

push_loadgenerator:
	docker push ${USER_NAME}/loadgenerator:${VERSION}

push_paymentservice:
	docker push ${USER_NAME}/paymentservice:${VERSION}

push_productcatalogservice:
	docker push ${USER_NAME}/productcatalogservice:${VERSION}

push_recommendationservice:
	docker push ${USER_NAME}/recommendationservice:${VERSION}

push_shippingservice:
	docker push ${USER_NAME}/shippingservice:${VERSION}

push: push_adservice push_cartservice push_currencyservice push_emailservice push_frontend push_loadgenerator push_paymentservice push_productcatalogservice push_recommendationservice push_shippingservice

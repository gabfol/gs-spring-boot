## DEV LOOP:
## - set env 
## 


# BEGIN: SET THESE ENV VARS WITH PROPER VALUES:
PROJECT_NAME="container-dev-workflow-with-maven"
DOCKER_REPO_NAME="gabfol"
APP_VERSION="1.2"
APP_PORT="8080"
export KUBECONFIG=/mnt/d/terraform0.10.8/oci_provisioning/terraform-kubernetes-installer/generated/kubeconfig
###### END 

#### THESE VARS ARE USED IN THE TARGETS:
APP_DIR=$(shell basename $$PWD)
APP_NAME=$(APP_DIR)
APP_HOSTNAME=$(APP_NAME)
APP_DEV_IMG=$(DOCKER_REPO_NAME)"/"$(APP_NAME)"-dev-img:"$(APP_VERSION)
APP_PROD_IMG=$(DOCKER_REPO_NAME)"/"$(APP_NAME)"-prod-img:"$(APP_VERSION)
APP_INSTANCE=$(APP_NAME)"-pod-"$(APP_VERSION)
APP_DB=$(APP_NAME)"-db"

## CODING LOOP (the worst way....): 
reload-app: stop-container remove-img build-img run-dev-container


###### DEV TARGETS:
build-dev-img: 
	-docker build -t $(APP_DEV_IMG) --target=builder --build-arg app_port=$(APP_PORT) --build-arg app_dir=$(APP_DIR) --build-arg app_name=$(APP_NAME) --build-arg MAVEN_VERSION=3.3.9 .	

build-prod-img: 
	-docker build -t $(APP_PROD_IMG) --build-arg app_port=$(APP_PORT) --build-arg app_dir=$(APP_DIR) --build-arg app_name=$(APP_NAME) --build-arg MAVEN_VERSION=3.3.9 .	

remove-dev-img:
	-docker rmi $(APP_DEV_IMG)	

remove-prod-img:
	-docker rmi $(APP_PROD_IMG)	

run-dev-container:
	-docker run --rm -itd --name $(APP_INSTANCE)-dev -e "APP_PORT=$(APP_PORT)" -p $(APP_PORT):$(APP_PORT) -v $(APP_DIR):/usr/src/app/$(APP_NAME) $(APP_DEV_IMG) bash 
#	C:\Users\GFOLCHI>docker run --rm -itd --name springboot-dev  -e "APP_PORT=8080" -p 8080:8080  -v D:\demos\gs-spring-boot:/usr/src/app/gs-spring-boot gabfol/gs-spring-boot-dev-img:1.2 bash

run-prod-container:
	-docker run --rm -it --name $(APP_INSTANCE)-prod -e "APP_PORT=$(APP_PORT)" -p $(APP_PORT):$(APP_PORT) $(APP_PROD_IMG)  

stop-container:
	-docker stop $(APP_INSTANCE)
#	C:\Users\GFOLCHI>docker stop springboot

## PUBLISH BEFORE DEPLOY 
publish-app: 
	docker push $(APP_PROD_IMG)

## DEPLOY TO KUBE:
deploy-kube: #delete-kube publish-app 
	-kubectl run $(APP_NAME) --image=$(APP_PROD_IMG) --env="APP_PORT=$(APP_PORT)" --port=$(APP_PORT)
	@echo "*******************SLEEPING FOR 30 secs "
	sleep 30
	@ $(eval PODNAME = $(shell kubectl get po -o jsonpath='{$$.items[?(@.metadata.labels.run == "$(APP_NAME)")].metadata.name}'))
	@echo "*******************DEPLOYED POD:" $(PODNAME)
	-kubectl expose pod $(PODNAME) --name=$(APP_NAME) --type=NodePort --port=$(APP_PORT)

delete-kube:
	-kubectl delete deployment $(APP_NAME)	
	-kubectl delete service $(APP_NAME)

###### DEBUG TARGETS:
show-env: 
	@echo "PROJECT_NAME="$(PROJECT_NAME)
	@echo "DOCKER_REPO_NAME="$(DOCKER_REPO_NAME)
	@echo "APP_VERSION="$(APP_VERSION)
	@echo "APP_PORT="$(APP_PORT)
	@echo "APP_DIR="$(APP_DIR)
	@echo "APP_NAME="$(APP_NAME)
	@echo "APP_HOSTNAME="$(APP_HOSTNAME)
	@echo "APP_DEV_IMG="$(APP_DEV_IMG)
	@echo "APP_PROD_IMG="$(APP_PROD_IMG)
	@echo "APP_INSTANCE="$(APP_INSTANCE)
	@echo "APP_DB="$(APP_DB)	
	@echo "KUBECONFIG="$(KUBECONFIG)	

show-kube:
	@echo "CLUSTER: ******************************************"
	@kubectl cluster-info
	@echo "NODES: ******************************************"
	@kubectl get nodes -o yaml | grep node.info/external.ipaddress
	@echo "PODS: ******************************************"
	@kubectl get pods
	@echo "DEPLOYMENTS: ******************************************"
	@kubectl get deploy
	@echo "SERVICES: ******************************************"
	@kubectl get services
	
temp-kube:
#	kubectl get po -o jsonpath='{$$.items[?(@.metadata.labels.run == "angular-node-creditscore")].metadata.name}'
	@echo "++++++++++++++++++++++++++++++++++++++  "$(APP_NAME)	
	@ $(eval PODNAME = $(shell kubectl get po -o jsonpath='{$$.items[?(@.metadata.labels.run == "$(APP_NAME)")].metadata.name}'))
	@echo "*******************DEPLOYED POD:" $(PODNAME)
	
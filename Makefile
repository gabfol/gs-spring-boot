## DEV LOOP:
## - set env 
## 


# BEGIN: SET THESE ENV VARS WITH PROPER VALUES:
PROJECT_NAME="container-dev-workflow-with-maven"
DOCKER_REPO_NAME="gabfol"
APP_VERSION="1.0"
APP_PORT="8080"
export KUBECONFIG=/mnt/d/terraform0.10.8/oci_provisioning/terraform-kubernetes-installer/generated/kubeconfig
###### END 

#### THESE VARS ARE USED IN THE TARGETS:
APP_DIR=$(shell basename $$PWD)
APP_NAME=$(APP_DIR)
APP_HOSTNAME=$(APP_NAME)
APP_IMG=$(DOCKER_REPO_NAME)"/"$(APP_NAME)"-img:"$(APP_VERSION)
APP_INSTANCE=$(APP_NAME)"-pod-"$(APP_VERSION)
APP_DB=$(APP_NAME)"-db"

## CODING LOOP: 
reload-app: stop-container remove-img build-img run-container

## PUBLISH BEFORE DEPLOY 
publish-app: 
	docker push $(APP_IMG)

## DEPLOY TO KUBE:
deploy-kube:
	-kubectl run $(APP_NAME) --image=$(APP_IMG) --env="APP_PORT=$(APP_PORT)" --port=$(APP_PORT)
	@echo "*******************SLEEPING FOR 15 secs "
	sleep 15
	@ $(eval PODNAME = $(shell kubectl get po -o jsonpath='{$$.items[?(@.metadata.labels.run == "$(APP_NAME)")].metadata.name}'))
	@echo "*******************DEPLOYED POD:" $(PODNAME)
	-kubectl expose pod $(PODNAME) --name=$(APP_NAME) --type=NodePort --port=$(APP_PORT)
	
delete-kube:
	-kubectl delete deployment $(APP_NAME)	
	-kubectl delete service $(APP_NAME)

###### PRIVATE TARGETS:
build-img: 
	-docker build -t $(APP_IMG) --build-arg app_port=$(APP_PORT) --build-arg app_dir=$(APP_DIR) --build-arg app_name=$(APP_NAME) --build-arg MAVEN_VERSION=3.3.9 .	

remove-img:
	-docker rmi $(APP_IMG)	

run-container:
	-docker run --rm -itd --name $(APP_INSTANCE) -e "APP_PORT=$(APP_PORT)" -p $(APP_PORT):$(APP_PORT) -v $(APP_DIR):/usr/src/app/$(APP_NAME) $(APP_IMG) bash 

stop-container:
	-docker stop $(APP_INSTANCE)

###### DEBUG TARGETS:
show-env: 
	@echo "PROJECT_NAME="$(PROJECT_NAME)
	@echo "DOCKER_REPO_NAME="$(DOCKER_REPO_NAME)
	@echo "APP_VERSION="$(APP_VERSION)
	@echo "APP_PORT="$(APP_PORT)
	@echo "APP_DIR="$(APP_DIR)
	@echo "APP_NAME="$(APP_NAME)
	@echo "APP_HOSTNAME="$(APP_HOSTNAME)
	@echo "APP_IMG="$(APP_IMG)
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
	
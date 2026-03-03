PROFILE ?= chaos-lab
IMAGE ?= direct-memory-lab:local

.PHONY: minikube-up minikube-down build-image deploy-256 deploy-unbounded logs pod reproduce-jps events

minikube-up:
	MINIKUBE_PROFILE=$(PROFILE) ./scripts/minikube-up.sh

minikube-down:
	minikube delete -p $(PROFILE)

build-image:
	MINIKUBE_PROFILE=$(PROFILE) IMAGE_NAME=$(IMAGE) ./scripts/build-image.sh

deploy-256:
	./scripts/apply-scenario.sh fixed-256m

deploy-unbounded:
	./scripts/apply-scenario.sh unbounded-direct-memory

logs:
	kubectl -n chaos-lab logs -f deploy/direct-memory-lab

pod:
	kubectl -n chaos-lab get pods -l app=direct-memory-lab

reproduce-jps:
	./scripts/reproduce-jps-oom.sh

events:
	kubectl -n chaos-lab get events --sort-by=.metadata.creationTimestamp | tail -n 30

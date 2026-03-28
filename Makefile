PROFILE ?= chaos-lab
IMAGE ?= direct-memory-lab:local
SCENARIO ?= memory/probe-induced-oom

.PHONY: minikube-up minikube-down build-image scenario trigger verify clean-scenario scenarios deploy-256 deploy-unbounded logs pod reproduce-jps events top

minikube-up:
	MINIKUBE_PROFILE=$(PROFILE) ./scripts/minikube-up.sh

minikube-down:
	minikube delete -p $(PROFILE)

build-image:
	MINIKUBE_PROFILE=$(PROFILE) IMAGE_NAME=$(IMAGE) ./scripts/build-image.sh

scenario:
	SCENARIO=$(SCENARIO) ./scripts/apply-scenario.sh

trigger:
	SCENARIO=$(SCENARIO) ./scripts/trigger-scenario.sh

verify:
	SCENARIO=$(SCENARIO) ./scripts/verify-scenario.sh

clean-scenario:
	SCENARIO=$(SCENARIO) ./scripts/delete-scenario.sh

scenarios:
	./scripts/list-scenarios.sh

deploy-256:
	SCENARIO=memory/probe-induced-oom ./scripts/apply-scenario.sh

deploy-unbounded:
	SCENARIO=memory/direct-oom ./scripts/apply-scenario.sh

logs:
	kubectl -n chaos-lab logs -f deploy/direct-memory-lab

pod:
	kubectl -n chaos-lab get pods -l app=direct-memory-lab

reproduce-jps:
	./scripts/reproduce-jps-oom.sh

events:
	kubectl -n chaos-lab get events --sort-by=.metadata.creationTimestamp | tail -n 30

top:
	kubectl -n chaos-lab top pod

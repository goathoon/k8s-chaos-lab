# k8s-chaos-lab

minikube 기반의 운영 장애 재현 실험실입니다.  
기존의 JVM direct memory 실험을 유지하면서, 여러 장애를 `시나리오 카탈로그` 방식으로 선택 실행할 수 있게 구성했습니다.

## 목표
- 운영환경에서 실제로 마주치는 장애를 로컬 Kubernetes에서 반복 재현
- 장애별로 `배포`, `트리거`, `검증` 절차를 표준화
- 플랫폼/SRE 관점에서 증상과 원인을 빠르게 관찰

## 구조
- 공통 베이스 리소스: `base/`
- 시나리오 카탈로그: `scenarios/<category>/<scenario>/`
- 공통 진입 스크립트: `scripts/apply-scenario.sh`, `scripts/trigger-scenario.sh`, `scripts/verify-scenario.sh`
- 샘플 워크로드: `app/src/main/java/lab/DirectMemoryProbeApp.java`

각 시나리오는 아래 파일 조합으로 구성됩니다.
- `scenario.yaml`: 이름, 설명, rollout 정책 같은 메타데이터
- `kustomization.yaml`: 공통 베이스 + overlay patch
- `patch-deployment.yaml`: 시나리오별 Deployment 변경사항
- `trigger.sh`: 선택적 장애 유발 스크립트
- `verify.sh`: 성공적인 재현 여부 판정 스크립트

## 제공 시나리오
```bash
make scenarios
```

현재 포함된 시나리오
- `memory/probe-induced-oom`: 평상시에는 살아있다가 `jps` 실행 시 추가 메모리 압박으로 재시작 유도
- `memory/direct-oom`: direct memory 증가로 컨테이너 OOMKill 유도
- `k8s/bad-readiness`: readiness probe 오설정으로 Running 이지만 Ready 되지 않는 상태 재현
- `k8s/crashloop`: 잘못된 JVM 옵션으로 CrashLoopBackOff 재현

## 사전 준비
- Docker
- minikube
- kubectl
- GNU make

## Quick Start
기본 메모리 시나리오를 바로 실행하려면:

```bash
make minikube-up
make build-image
make scenario SCENARIO=memory/probe-induced-oom
make trigger SCENARIO=memory/probe-induced-oom
make verify SCENARIO=memory/probe-induced-oom
```

## 공통 워크플로

### 1) 클러스터 생성
```bash
make minikube-up
```

기본값
- profile: `chaos-lab`
- kubernetes: `v1.30.0`
- cpu: `4`
- memory: `8192MB`

### 2) 이미지 빌드
```bash
make build-image
```

### 3) 시나리오 배포
```bash
make scenario SCENARIO=memory/direct-oom
```

### 4) 선택적 트리거 실행
트리거가 있는 시나리오에만 필요합니다.

```bash
make trigger SCENARIO=memory/probe-induced-oom
```

### 5) 재현 여부 검증
```bash
make verify SCENARIO=memory/probe-induced-oom
```

### 6) 상태 확인
```bash
make pod
make logs
make events
make top
```

### 7) 시나리오 정리
```bash
make clean-scenario SCENARIO=memory/direct-oom
```

## 호환용 명령
기존 흐름도 유지됩니다.

```bash
make deploy-256
make deploy-unbounded
make reproduce-jps
```

각 명령은 아래 시나리오에 매핑됩니다.
- `deploy-256` -> `memory/probe-induced-oom`
- `deploy-unbounded` -> `memory/direct-oom`
- `reproduce-jps` -> `memory/probe-induced-oom`의 trigger

## 시나리오 설계 원칙
- 공통 리소스는 `base/`에서 관리하고, 차이는 overlay patch로 표현
- 시나리오는 사람이 읽을 수 있어야 하고, trigger/verify가 자동화 가능해야 함
- 검증 기준은 가능하면 `kubectl` 결과로 기계 판정 가능해야 함
- 신규 장애는 기존 YAML 복제가 아니라 새 scenario 디렉터리 추가로 확장

## 관찰 포인트
- `kubectl get pods`의 `STATUS`, `READY`, `RESTARTS`
- `kubectl describe pod`의 `OOMKilled`, probe failure, waiting reason
- `kubectl logs`와 `kubectl logs --previous`
- `kubectl top pod`의 메모리/CPU 사용량
- `kubectl get events --sort-by=.metadata.creationTimestamp`

## 다음 확장 방향
- dependency timeout, DNS failure, CPU throttling, ephemeral storage pressure 시나리오 추가
- load generator / mock dependency Pod를 시나리오별로 조합
- metrics-server 외에 Prometheus/Grafana를 붙여 장기 관찰 강화

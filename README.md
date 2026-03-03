# k8s-chaos-lab

minikube 환경에서 JVM 메모리 이슈(특히 Direct Memory + `jps`)를 재현하기 위한 실험 프로젝트입니다.

## 실험 목적
- 목적 1: `-XX:MaxDirectMemorySize=256m` 설정 시 평상시에는 살아있지만, `jps` 실행 같은 추가 부하에서 OOM/재시작이 발생하는지 확인
- 목적 2: `MaxDirectMemorySize` 미설정 시 direct memory 사용이 증가하면서 컨테이너 OOM이 나는지 확인

핵심 포인트는 "애플리케이션 + direct memory + 진단 도구(`jps`) 프로세스의 합계 메모리"가 컨테이너 limit를 넘는 순간입니다.

## 구성 파일
- Java 실험 앱: `app/src/main/java/lab/DirectMemoryProbeApp.java`
- 이미지 빌드: `Dockerfile`
- 시나리오 A(256m 고정): `k8s/fixed-256m.yaml`
- 시나리오 B(미설정): `k8s/unbounded-direct-memory.yaml`
- 반복 `jps` 실행: `scripts/reproduce-jps-oom.sh`

## 사전 준비
- Docker
- minikube
- kubectl
- GNU make

## Quick Start
아래 순서만 실행하면 바로 재현 실험을 시작할 수 있습니다.

```bash
make minikube-up
make build-image
make deploy-256
make reproduce-jps
```

## 상세 실행 절차

### 1) minikube 클러스터 생성
```bash
make minikube-up
```

기본값
- profile: `chaos-lab`
- kubernetes: `v1.30.0`
- cpu: `4`
- memory: `8192MB`

### 2) 실험 이미지 빌드
minikube 내부 이미지 저장소로 빌드합니다.
```bash
make build-image
```

### 3) 시나리오 선택 배포

시나리오 A. `MaxDirectMemorySize=256m`
```bash
make deploy-256
```

시나리오 B. `MaxDirectMemorySize` 미설정
```bash
make deploy-unbounded
```

### 4) 상태/로그 확인
```bash
make pod
make logs
```

### 5) `jps` 반복 실행으로 트리거
```bash
make reproduce-jps
```

## 결과 확인 방법

### OOM/재시작 여부
```bash
make events
kubectl -n chaos-lab get pods -l app=direct-memory-lab
kubectl -n chaos-lab describe pod <POD_NAME>
```

아래 신호가 보이면 재현 성공으로 판단할 수 있습니다.
- `RESTARTS` 값 증가
- 이벤트/describe에 `OOMKilled` 또는 메모리 관련 종료 사유

### 비교 관찰 포인트
- A(256m 고정): 평상시 정상 -> `jps` 반복 시에만 불안정해지는지
- B(미설정): 별도 트리거 없이도 더 빠르게 OOM/재시작되는지

## 왜 `jps`가 영향이 있나
- `jps`도 JVM 기반 도구여서 실행 시 추가 heap/native 메모리를 사용합니다.
- 이미 메모리 limit 근처인 컨테이너에서는 작은 추가 사용량도 OOMKill 유발 요인이 됩니다.

## 튜닝 포인트
- `k8s/*.yaml`의 `resources.limits.memory`
- `DIRECT_TARGET_MB`
- `-Xmx`, `-XX:MaxDirectMemorySize`

## 다음 확장 아이디어
- 실제 운영 JVM 옵션(예: GC, metaspace, native memory tracking) 반영
- 사이드카/에이전트가 있는 배포 형태로 확장
- 부하 생성 Pod를 추가해 운영 유사 조건에서 재현 정확도 향상

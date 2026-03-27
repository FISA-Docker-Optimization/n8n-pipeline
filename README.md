# n8n 도커 공식 이미지 경량화 및 빌드 최적화

## 팀원
|<img src="https://github.com/Federico-15.png" width="120"/> | <img src="https://github.com/wooxxo.png" width="120"/>|
|:--:|:--:|
| [**류승환**](https://github.com/Federico-15) | [**우승연**](https://github.com/wooxxo) |


## 개요
n8n 공식 이미지를 멀티스테이지 빌드로 경량화하고 공식 이미지와 비교한 결과를 정리합니다.

---

## 1단계 : Builder (경량화 작업)

- `@n8n/nodes-langchain` → AI/LangChain 관련 노드 제거
- `.test.js` → 개발용 테스트 파일 제거
- `.d.ts` → TypeScript 타입 정의 파일 제거
```dockerfile
FROM n8nio/n8n:latest AS builder

USER root
RUN rm -rf /usr/local/lib/node_modules/n8n/node_modules/@n8n/nodes-langchain && \
    find /usr/local/lib/node_modules/n8n -name "*.test.js" -delete && \
    find /usr/local/lib/node_modules/n8n -name "*.d.ts" -delete

# 새 이미지에 필요한 것만 복사
FROM node:20-alpine
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin/n8n /usr/local/bin/n8n

ENV N8N_PORT=5678
EXPOSE 5678
VOLUME /root/.n8n
CMD ["n8n", "start"]
```

---

## 2단계 : 공식 이미지와 비교

<img width="534" height="226" alt="image (10)" src="https://github.com/user-attachments/assets/cbf96eb1-51cc-4133-b45f-afdd34074152" />

| 항목 | n8n-lite (공식) | n8n-lite-v2 (경량화) |
|------|----------------|-------------------|
| 빌드시간 | 6초 | 4초 |
| 이미지크기 | 2GB | 1.68GB |
| 빌드시간 차이 | - | 2초 절약 |
| 크기 차이 | - | 약 320MB 절감 |

---

## 경량화 한계 및 문제점

멀티스테이지 빌드로 node_modules 복사 시 semver 등 일부 모듈 누락 발생

**에러 내용:**
```
Error: Cannot find module 'semver/functions/satisfies'
```

**원인:** n8n의 복잡한 모듈 의존성 구조상 COPY만으로는 완전한 실행 환경 구성이 어려움

<img width="859" height="460" alt="image (11)" src="https://github.com/user-attachments/assets/541d27b2-6c3d-41b3-a31e-50da587cc7c6" />

---

## 3단계 : 빌드 최적화

### 방법 1 : .dockerignore 추가
빌드 컨텍스트에서 불필요한 파일을 제외해 빌드 속도 향상
```
.git
*.log
*.md
*.sh
node_modules
.env
.dockerignore
```

### 방법 2 : 베이스 이미지 버전 고정
`latest` 태그는 매번 최신 이미지를 확인해 캐시가 무효화될 수 있음
버전을 고정하면 캐시 재사용률이 높아져 재빌드 속도가 빨라짐
```dockerfile
# 변경 전 (캐시 무효화 가능)
FROM n8nio/n8n:latest

# 변경 후 (캐시 재사용)
FROM n8nio/n8n:2.14.1
```

<img width="505" height="221" alt="image (8)" src="https://github.com/user-attachments/assets/0aa490e9-cf3e-44a6-9c85-ec2e3131d816" />

### 방법 3 : BuildKit 활성화
병렬 빌드로 속도 향상
```bash
DOCKER_BUILDKIT=1 docker build --progress=plain -t n8n:latest .
```

### 캐시 동작 원리
Docker는 레이어 단위로 캐시를 저장하며, 변경이 없는 레이어는 재사용함
자주 변경되는 레이어를 아래에 배치할수록 캐시 재사용률이 높아짐
```
자주 안 바뀌는 것 (위)   → 캐시 재사용 ✅
자주 바뀌는 것 (아래)    → 새로 빌드
```

---

## 4단계 : 버전 고정 빌드 비교


| 항목 | latest 버전 | 버전 고정 (2.14.1) |
|------|------------|------------------|
| 첫 빌드 | 동일 | 동일 |
| 재빌드 | 캐시 무효화 가능 | 캐시 재사용 ✅ |
| 안정성 | 예기치 않은 변경 가능 | 버전 고정으로 안정적 |

---

## 결론

- 이미지 크기는 약 320MB 경량화 성공
- 그러나 모듈 누락으로 실행 불가
- n8n은 복잡한 의존성 구조로 멀티스테이지 경량화에 한계 존재
- 빌드 최적화는 `.dockerignore`, 버전 고정, BuildKit 활용으로 가능
- 안정적인 운영을 위해 공식 이미지 버전 고정 사용 권장

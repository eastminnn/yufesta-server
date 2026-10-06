# YU FESTA - Backend
[![Java](https://img.shields.io/badge/Java-17-007396?logo=openjdk&logoColor=white)](https://openjdk.org/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-4.1.1-6DB33F?logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![MySQL](https://img.shields.io/badge/MySQL-8.4-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Redis](https://img.shields.io/badge/Valkey-8-FF4438?logo=redis&logoColor=white)](https://valkey.io/)
[![AWS](https://img.shields.io/badge/AWS-ECS%20Fargate-FF9900?logo=amazonwebservices&logoColor=white)](https://aws.amazon.com/ecs/)

> YU FESTA는 축제 방문객이 별도 앱 설치 없이 QR로 접속하여 공연 일정, 동아리 라인업, 축제 지도와 공지를 확인하고, 인스타팅 동행 매칭과 분실물·응원 게시판을 이용할 수 있는 서비스입니다.

- 운영 일자: 2026.10.02

<img width="1600" height="900" alt="Image" src="https://github.com/user-attachments/assets/4a7c3ba4-85a5-491c-855d-0b4c528b85ea" />

## 핵심 기능

| 영역 | 기능 |
|---|---|
| 인스타팅 | 2회차 이성 동행 매칭, 성비 불균형을 고려한 1:N 배정, 결과 발표·재참여·신고 |
| 축제 정보 | 공연 타임테이블, 동아리 라인업, 지도 장소·이벤트, 공지사항 |
| 현장 커뮤니티 | 비로그인 익명 응원 메시지, 분실물 게시글·이미지·댓글·답글 |
| 콘텐츠 안전 | 개인정보·연락 유도 차단, 한국어 우회 표현 필터, 소형 LLM 문맥 분류, 작성 속도 제한 |
| 운영자 기능 | 장소·공지·분실물·응원·신고 관리, 인스타팅 회차 운영과 결과 발표 |

## 축제 당일 운영 결과

> 아래 수치는 팀 서비스 전체의 운영 결과입니다.

| 지표 | 결과 |
|---|---:|
| 방문 브라우저 | **2,080명** |
| 세션 | **3,850회** |
| 페이지뷰 | **30,100회** |
| 중앙 체류 시간 | **9분 42초** |
| 로그인 회원 | **653명** |
| 회차별 누적 신청 | **700건** |

축제 당일 2,080명이 방문해 총 30,100회의 페이지뷰를 기록했습니다. 회차별 신청은 1회차 218건, 2회차 314건, 현장에서 추가 운영한 3회차 168건으로 총 700건이 접수됐습니다.

## Architecture
<img width="1800" height="1120" alt="Image" src="https://github.com/user-attachments/assets/431b44b1-82eb-48a8-b110-92cd98542e83" />

## Tech Stack

| 구분 | 기술 |
|---|---|
| Language | Java 17 |
| Framework | Spring Boot 4.1.1, Spring MVC, Spring Security, Spring Data JPA |
| Database | MySQL 8.4, Flyway |
| Cache | Valkey/Redis, Caffeine |
| Authentication | Kakao·Google OAuth 2.0, JWT HttpOnly Cookie, CSRF |
| Storage | AWS S3, CloudFront, Thumbnailator |
| API | REST, SSE, springdoc-openapi/Swagger |
| Test | JUnit 5, Mockito, MockMvc, H2 MySQL mode, Hibernate Statistics |
| Infra | Docker, AWS ECS Fargate, RDS, ElastiCache, ALB, ECR, Terraform, GitHub Actions OIDC |

## 담당한 작업

### 1. 인증과 공통 백엔드 기반

- 전역 예외 처리와 공통 API 응답 포맷 구성
- 사용자·운영 설정 스키마 및 감사 필드 설계
- 카카오·구글 OAuth 로그인과 쿠키 기반 JWT 인증 구현
- CSRF 보호, 요청 ID 기반 HTTP 로깅, 개발·운영 프로필 분리
- 로그인 제공자의 이름·프로필 이미지를 저장하고 내 정보 API로 제공
- Flyway 마이그레이션 버전 충돌 시 기존 이력을 보존하고 신규 버전으로 이관

주요 PR: [#4](https://github.com/yu-festa/yufesta-server/pull/4), [#8](https://github.com/yu-festa/yufesta-server/pull/8), [#12](https://github.com/yu-festa/yufesta-server/pull/12), [#13](https://github.com/yu-festa/yufesta-server/pull/13), [#14](https://github.com/yu-festa/yufesta-server/pull/14), [#130](https://github.com/yu-festa/yufesta-server/pull/130), [#132](https://github.com/yu-festa/yufesta-server/pull/132)

### 2. 축제 지도와 공지

- 장소·장소 이벤트 공개 조회 및 운영자 등록·수정 API 구현
- 실제 화면 정책에 맞춰 장소 카테고리를 개편하고 조회 테스트 추가
- 공지사항 공개 조회 및 운영자 CRUD 구현
- 인스타팅 결과 발표 시 회차별 공지를 자동 생성하도록 배치 흐름 연동

주요 PR: [#37](https://github.com/yu-festa/yufesta-server/pull/37), [#54](https://github.com/yu-festa/yufesta-server/pull/54), [#69](https://github.com/yu-festa/yufesta-server/pull/69), [#71](https://github.com/yu-festa/yufesta-server/pull/71), [#96](https://github.com/yu-festa/yufesta-server/pull/96), [#142](https://github.com/yu-festa/yufesta-server/pull/142)

### 3. 응원·분실물·콘텐츠 신고

- 로그인 없이 작성 가능한 익명 응원 메시지와 브라우저 익명 키 관리 구현
- 분실물 조회·작성·해결·삭제 및 운영자 관리 API 구현
- 게시글당 이미지 1장 업로드·삭제와 본문용·썸네일 이미지 변환 구현
- 최상위 댓글과 1단계 답글, 게시글 단위 익명 별칭 유지 기능 구현
- 응원·분실물·댓글을 하나의 신고 모델로 처리하고 누적 신고 자동 숨김 구현
- 운영자 신고 검토, 콘텐츠 숨김·복구 및 대상 유형별 관리 기능 구현

주요 PR: [#74](https://github.com/yu-festa/yufesta-server/pull/74), [#80](https://github.com/yu-festa/yufesta-server/pull/80), [#81](https://github.com/yu-festa/yufesta-server/pull/81), [#82](https://github.com/yu-festa/yufesta-server/pull/82), [#86](https://github.com/yu-festa/yufesta-server/pull/86), [#87](https://github.com/yu-festa/yufesta-server/pull/87), [#108](https://github.com/yu-festa/yufesta-server/pull/108), [#111](https://github.com/yu-festa/yufesta-server/pull/111)

### 4. 콘텐츠 안전 파이프라인

```text
입력
 └─ 정규식 검사(연락처·URL·SNS 계정)
     └─ Unicode 정규화 + 한국어 로컬 정책
         └─ 소형 LLM 문맥 분류
             ├─ BLOCK → 저장 거절
             ├─ ALLOW → 저장
             └─ API 장애 → SKIPPED 저장 후 운영자 검토
```

- 공백·특수문자·숫자·초성으로 우회한 한국어 유해 표현 정규화
- 집단 지칭과 비하 표현을 조합해 검사하고 정상 단어는 허용 목록으로 보호
- `gpt-4.1-mini`와 Structured Outputs를 사용하여 `ALLOW/BLOCK`, 유형, 신뢰도를 구조화
- 외부 API 장애가 작성 기능 전체 장애로 번지지 않도록 `SKIPPED` 상태의 fail-open 정책 적용
- Redis 기반 사용자·익명 키별 작성 속도 제한과 Redis 장애 시 가용성 우선 정책 적용
- 원문 대신 콘텐츠 해시와 판정 유형만 로그에 남겨 민감한 사용자 입력 노출 방지

주요 PR: [#126](https://github.com/yu-festa/yufesta-server/pull/126), [#128](https://github.com/yu-festa/yufesta-server/pull/128), [#147](https://github.com/yu-festa/yufesta-server/pull/147), [#157](https://github.com/yu-festa/yufesta-server/pull/157)

## 성능 개선과 검증

### 한국어 콘텐츠 필터 개선

범용 Moderation API만으로는 한국어 우회 표현과 문맥성 공격을 충분히 판별하지 못했습니다. 명확한 패턴은 로컬에서 빠르게 거르고, 문맥 판단이 필요한 입력만 소형 LLM으로 보내는 단계형 구조로 개선했습니다.

| 지표 | 개선 전 | 로컬 필터 보강 후 |
|---|---:|---:|
| 유해 표현 차단 | 12/30 (40.0%) | **30/30 (100.0%)** |
| 정상 표현 오탐 | 0/20 (0.0%) | **0/20 (0.0%)** |
| p95 처리 시간 | 1,410ms | **550ms** |

- 차단률을 60%p 높이면서 정상 표현 오탐은 발생하지 않았습니다.
- 명확한 유해 표현의 외부 API 호출을 줄여 p95 처리 시간을 약 **61% 단축**했습니다.
- 이후 문맥 분류 평가에서도 유해 표현 30/30 차단, 정상 표현 0/20 오탐, SKIPPED 0/50을 확인했습니다.

관련 PR: [한국어 로컬 필터 보강 #147](https://github.com/yu-festa/yufesta-server/pull/147), [소형 LLM 문맥 분류 #157](https://github.com/yu-festa/yufesta-server/pull/157)

### 운영자 신고 목록 N+1 제거

신고 목록의 각 항목마다 대상 콘텐츠 상태를 다시 조회하면서 페이지 크기에 비례해 SQL이 증가했습니다. 대상 ID를 유형별로 모은 뒤 Projection과 `IN` 쿼리로 일괄 조회하고, Map으로 응답을 조립하도록 변경했습니다.

| 조회 크기 | 개선 전 SQL | 개선 후 SQL | 감소율 |
|---:|---:|---:|---:|
| 1건 | 8회 | 8회 | 0% |
| 10건 | 17.5회 | 8회 | 약 54.3% |
| 50건 | 74회 | **10회** | **약 86.5%** |

- 50건 조회 시 대상 상태 조회를 67회에서 3회로 축소했습니다.
- 분실물 이미지 연관 추가 조회를 17회에서 0회로 제거했습니다.
- Hibernate Statistics 기반 회귀 테스트로 혼합 대상 목록의 SELECT 상한을 고정했습니다.

관련 PR: [운영자 콘텐츠 신고 목록 N+1 개선 #152](https://github.com/yu-festa/yufesta-server/pull/152)

> 수치는 동일한 로컬 MySQL 조건에서 변경 전후를 반복 측정한 결과이며, 운영 환경 전체의 성능을 일반화한 값은 아닙니다.

## 주요 설계 결정

| 결정 | 이유 |
|---|---|
| 공개 콘텐츠에 자동 생성 닉네임 사용 | 사용자의 소셜 프로필과 공개 활동을 분리하고 익명성을 유지 |
| 삭제보다 숨김·복구 우선 | 신고·댓글·연관 데이터와 운영 이력을 보존 |
| 외부 콘텐츠 분류 장애 시 `SKIPPED` | OpenAI 장애가 전체 작성 기능 장애로 전파되는 것을 방지하고 운영자 사후 검토 제공 |
| Redis 속도 제한 장애 시 fail-open | 짧은 축제 운영 기간에 게시 기능 가용성을 우선 |
| 신고 대상 Projection 일괄 조회 | 엔티티 전체 로딩과 연관관계 N+1을 피하고 필요한 상태만 조회 |
| Flyway 기존 버전 수정 금지 | 이미 적용된 운영 이력의 checksum 충돌과 배포 실패 방지 |

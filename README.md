# docker-reset

![버전](https://img.shields.io/badge/버전-1.0.0-blue.svg)
![라이선스](https://img.shields.io/badge/라이선스-MIT-green.svg)

**Docker 공장 초기화 스크립트** - Docker 환경을 안전하게 정리하기 위한 종합 도구입니다.

## 개요

`docker-reset`은 Docker 환경을 완전히 초기화하는 Bash 스크립트입니다. 기존의 모든 컨테이너, 이미지, 볼륨, 네트워크, 캐시를 안전하게 백업 및 삭제하고, 진행 상태를 터미널 내에서 직관적인 컬러 진행 바(progress bar)로 시각화합니다.

## 주요 기능

- **설정 백업**: Docker 컨텍스트, Compose 파일, 설정 폴더(`~/.docker`)를 `~/.docker_backup`에 저장
- **완전한 리소스 정리**: 컨테이너, 이미지, 볼륨, 네트워크를 단계별로 체계적으로 제거
- **Swarm 및 플러그인 정리**: Swarm 모드에서 서비스/노드 탈퇴 및 Docker 플러그인 제거
- **캐시 정리**: `docker system prune -af --volumes` 명령으로 불필요한 캐시 일괄 제거
- **실행 로그**: `./logs` 디렉토리에 타임스탬프 기반 로그 파일 생성 및 세부 기록
- **컬러 진행 바**: 전체 진행 및 단계별 진행률을 40칸 컬러 바와 퍼센트로 표현
- **터미널 UI 제어**: 커서 숨기기/보이기, 특정 라인 이동, 화면 초기화 등 터미널 UI 제어
- **메시지 시스템**: 정보, 성공, 경고, 오류 등 상황별 색상 구분된 메시지 출력
- **오류 처리**: 볼륨 삭제 실패 시 해당 볼륨을 사용 중인 컨테이너 정보 상세 로깅

## 요구 사항

- **OS**: macOS 또는 Linux
- **셸**: Bash (`#!/usr/bin/env bash` 호환 환경)
- **Docker**: `docker` CLI가 시스템 경로에 등록되어 있어야 함
- **rsync**: 설정 폴더 백업 시 권장 (`rsync` 없으면 `cp` 사용)

## 설치 및 실행 방법

1. 스크립트 파일을 원하는 위치에 복사하거나 클론합니다:

```bash
chmod +x docker-reset_v1.00.sh
```

2. 스크립트를 실행합니다:

```bash
./docker-reset_v1.00.sh
```

3. 실행 시 삭제 경고 메시지가 표시되며, `Y`를 입력하여 진행을 승인합니다.

## 디렉토리 구조

```
├─ docker-reset_v1.00.sh    # 메인 실행 스크립트
├─ logs/                    # 실행 시 생성되는 로그 파일 디렉토리
└─ ~/.docker_backup/        # 사용자 홈 디렉토리에 생성되는 백업 폴더
   ├─ *.tar                 # Docker 컨텍스트 백업
   ├─ docker-compose*.yml   # 발견된 Docker Compose 파일
   └─ docker_config/        # Docker 설정 폴더 백업
```

## 스크립트 구조

- **스크립트 헤더**: 색상 및 변수 정의
- **화면 제어 함수**: `clear_screen`, `hide_cursor`, `move_to_line` 등 UI 제어
- **진행 바 함수**: `draw_progress_bar`, `update_progress`
- **로그 함수**: `log_cmd`, `add_message`
- **메시지 함수**: `echo_info`, `echo_success`, `echo_warn`, `echo_error` 상황별 메시지 출력
- **백업/삭제 함수**: `backup_docker_config`, `delete_with_progress`, `stop_running_containers` 등
- **메인 흐름**: `confirm_prompt` → `docker_reset` → 완료 메시지
- **종료 처리**: `cleanup` 함수를 통한 커서 복원 및 정리 작업

## 설정 옵션

| 옵션 | 설명 |
|------|------|
| `TOTAL_STEPS` | 전체 단계 수 (기본 8) |
| `main_step_names` | 단계별 이름 배열 |
| `main_step_weights` | 각 단계 진행 비중(총합 100) |
| `BAR_FILLED`, `BAR_EMPTY` | 진행 바 문자 |
| `HEADER_LINES`, `PROGRESS_BAR_LINE` | UI 레이아웃 라인 번호 |
| `MESSAGE_LINE`, `MAX_MESSAGES` | 메시지 표시 시작 라인 및 최대 메시지 수 |

## 상세 기능 설명

### 색상 및 서식 설정

- ANSI Escape 코드로 텍스트 컬러 및 굵기 설정
- `reset`, `green`, `red`, `yellow`, `blue`, `cyan`, `magenta`, `bold` 지원

### 진행 바 설정

- 총 길이 40칸(`len=40`)으로 정확한 퍼센트 표시
- 100% 시 자동 초록색(`green`)으로 전환
- 매 업데이트마다 동일 라인(`PROGRESS_BAR_LINE`)에 재출력

### 메시지 시스템

- `echo_info`: 파란색으로 일반 정보 메시지 출력
- `echo_success`: 녹색으로 성공 메시지 출력
- `echo_warn`: 노란색으로 경고 메시지 출력
- `echo_error`: 빨간색 굵은 글씨로 오류 메시지 출력
- 메시지가 최대 표시 수를 초과하면 화면 초기화

### 로그 관리

- `logs/docker_reset_<TIMESTAMP>.log` 파일에 상세 기록
- 각 명령 실행 전후 및 오류 로그 포함
- 실패 시 세부 정보(예: 제거 실패한 볼륨의 컨테이너 목록) 추가 기록
- 타임스탬프 형식: YYYYMMDD_HHMMSS

### 화면 제어 함수

- `move_to_line`: ANSI 좌표 이동
- `clear_line` / `clear_from_cursor`: 라인/커서 이후 영역 지우기
- `hide_cursor` / `show_cursor`: 터미널 커서 감추기/표시
- `cleanup`: 스크립트 종료 시 커서 복원 및 화면 정리

### 삭제/백업 작업

1. **백업**: 
   - Docker 컨텍스트: `docker context export` 명령으로 *.tar 파일로 저장
   - Compose 파일: 현재 디렉토리에서 3단계 깊이까지 `docker-compose*.yml` 파일 검색하여 백업
   - 설정 폴더: `~/.docker`를 `rsync` 또는 `cp`를 이용해 백업 (소켓 파일 제외)

2. **Swarm 처리**:
   - `docker info`로 Swarm 활성 상태 확인
   - 활성 시 `docker service rm`으로 서비스 제거 후 `docker swarm leave --force`로 탈퇴

3. **단계별 삭제**:
   - `docker stop`: 실행 중인 컨테이너 중지
   - `docker rm -f`: 모든 컨테이너 강제 삭제
   - `docker rmi -f`: 모든 이미지 강제 삭제
   - `docker volume rm`: 모든 볼륨 삭제
   - `docker network rm`: 사용자 정의 네트워크 삭제
   - `docker plugin rm -f`: 설치된 플러그인 강제 삭제

4. **캐시 정리**:
   - `docker system prune -af --volumes`를 두 차례 실행하여 캐시 완전 정리
   - 두 번째 실행은 검증 및 안전망 역할

## 사용 예시

```bash
$ ./docker-reset_v1.00.sh
⚠️ 이 스크립트는 Docker의 모든 자원을 삭제합니다. 진행하시겠습니까? (Y/N) Y
... (진행 바 출력) ...
🎊 Docker Factory Reset 완료!
자세한 로그: ./logs/docker_reset_20250427_153045.log
```

## 기여 방법

1. 이슈(issue) 또는 풀 리퀘스트(PR) 생성
2. 코드 스타일 및 문서 가이드라인 준수 (Bash 스크립트 스타일)
3. 새로운 기능 제안 및 버그 리포트 환영

## Oh My Zsh 별칭 설정 (선택 사항)

`oh-my-zsh`를 사용하는 경우, 다음과 같이 `~/.zshrc` 파일에 별칭(alias)을 추가하면 어느 위치에서든 `docker-reset` 명령어로 스크립트를 실행할 수 있습니다.

1. `~/.zshrc` 파일을 엽니다.

   ```bash
   nano ~/.zshrc
   ```

2. 파일 맨 아래에 다음 줄을 추가합니다.

   ```bash
   # Docker 리셋 스크립트 별칭
   alias docker-reset='yourpath/docker-reset_v1.00.sh'
   ```

3. 터미널을 재시작하거나 다음 명령어로 설정을 적용합니다.

   ```bash
   source ~/.zshrc
   ```

이제 터미널에서 `docker-reset`만 입력하여 스크립트를 실행할 수 있습니다.

## 라이선스

MIT 라이선스

```
MIT License

Copyright (c) 2025 TechJuiceLab

Permission is hereby granted, free of charge, to any person obtaining a copy...
```

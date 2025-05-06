#!/usr/bin/env bash
# Author: TechJuiceLab
# Description: Docker Factory Reset Script with Fixed Progress Bar

# ─── 색상 및 서식 설정 ─────────
reset=$'\e[0m'
green=$'\e[0;32m'
red=$'\e[0;31m'
yellow=$'\e[1;33m'
blue=$'\e[0;34m'
cyan=$'\e[0;36m'
magenta=$'\e[0;35m'
bold=$'\e[1m'

# ─── 진행 바 문자 설정 ────────────
BAR_FILLED=$'█'
BAR_EMPTY=$'░'

# ─── 로그 파일 생성 ────────────────
timestamp=$(date +%Y%m%d_%H%M%S)
log_dir="./logs"; mkdir -p "$log_dir"
log_file="$log_dir/docker_reset_$timestamp.log"

# ─── 화면 제어 함수 ─────────────
clear_screen() {
  clear
}

hide_cursor() {
  printf "\e[?25l"
}

show_cursor() {
  printf "\e[?25h"
}

move_to_line() {
  local line=$1
  printf "\e[${line};0H"
}

clear_from_cursor() {
  printf "\e[0J"
}

clear_line() {
  printf "\e[2K"
}

# ─── 화면 레이아웃 상수 ───────────
HEADER_LINES=5       # 헤더 표시 라인 수
MESSAGE_LINE=7       # 메시지 표시 시작 라인
MAX_MESSAGES=15      # 최대 메시지 수
PROGRESS_BAR_LINE=25 # 진행 바 표시 라인
CURRENT_MESSAGE_LINE=$MESSAGE_LINE

# ─── 진행 단계 정의 ────────────────
TOTAL_STEPS=8
current_main_step=0
main_step_names=("초기화" "컨테이너 종료" "컨테이너 삭제" "이미지 삭제" "볼륨 삭제" "네트워크 삭제" "캐시 정리" "검증")
main_step_weights=(5 10 15 20 20 10 15 5)  # 합계 100

# ─── 메시지 정의 ─────────────────
MSG_TITLE="Docker Factory Reset by TechJuiceLab"
MSG_WARNING="⚠️ 이 스크립트는 Docker의 모든 컨테이너·이미지·볼륨·네트워크·캐시를 완전히 삭제합니다!"
MSG_PROMPT="진행하시겠습니까? (Y/N) "
MSG_CANCELED="취소되었습니다."
MSG_YN_PROMPT="Y 또는 N을 입력하세요."
MSG_COMPLETE="🎊 Docker Factory Reset 완료!"
MSG_BACKUP="Docker 설정 백업 완료: ~/.docker_backup/"
MSG_DESKTOP_DETECTED="Docker Desktop이 감지되었습니다. GUI에서도 삭제가 필요할 수 있습니다."
MSG_LOG_FILE="로그 파일:"
MSG_OVERALL_PROGRESS="전체 진행 상황:"
MSG_CURRENT_STAGE="현재 단계"

# ─── 헤더 출력 ───────────────────
print_header() {
  move_to_line 1
  clear_from_cursor
  echo -e "${bold}${blue}=========================================="
  echo -e "   $MSG_TITLE"
  echo -e "==========================================${reset}"
  echo -e "${blue}${MSG_LOG_FILE} ${log_file}${reset}"
  echo
}

# ─── 메시지 출력 ───────────────────
add_message() {
  local color=$1
  local message=$2
  
  # 로그에 메시지 기록
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
  
  # 현재 메시지 라인이 너무 많으면 초기화
  if [ $CURRENT_MESSAGE_LINE -gt $((MESSAGE_LINE + MAX_MESSAGES)) ]; then
    move_to_line $MESSAGE_LINE
    clear_from_cursor
    CURRENT_MESSAGE_LINE=$MESSAGE_LINE
  fi
  
  # 화면에 메시지 출력
  move_to_line $CURRENT_MESSAGE_LINE
  clear_line
  echo -e "${color}${message}${reset}"
  CURRENT_MESSAGE_LINE=$((CURRENT_MESSAGE_LINE + 1))
  
  # 진행 바 다시 그리기
  draw_progress_bar
}

echo_info() { add_message "$blue" "$1"; }
echo_success() { add_message "$green" "$1"; }
echo_warn() { add_message "$yellow" "$1"; }
echo_error() { add_message "$red$bold" "$1"; }

# ─── 진행 바 그리기 ───────────────
draw_progress_bar() {
  local pct=$CURRENT_PCT
  local name="${main_step_names[$current_main_step]}"
  local len=40
  
  # 100%를 넘지 않도록 처리
  if ((pct > 100)); then
    pct=100
  fi
  
  # 진행 바 길이 계산 (정확히 계산하여 100%일 때 빈 부분이 없도록)
  local fill=$((len*pct/100))
  local emp=$((len-fill))
  
  # 진행 바 문자로 채우기
  local bar_filled="" bar_empty=""
  for ((i=0; i<fill; i++)); do
    bar_filled+="${BAR_FILLED}"
  done
  for ((i=0; i<emp; i++)); do
    bar_empty+="${BAR_EMPTY}"
  done
  
  local progress_color="${cyan}"
  if ((pct >= 100)); then
    progress_color="${green}"
  fi
  
  # 진행 바 위치로 이동하여 그리기
  move_to_line $PROGRESS_BAR_LINE
  clear_line
  printf "${bold}${magenta}%s${reset} [${progress_color}%s${reset}%s] ${green}%3d%%${reset} | ${bold}%s${reset}: ${yellow}%s${reset}\n" \
    "$MSG_OVERALL_PROGRESS" "$bar_filled" "$bar_empty" "$pct" "$MSG_CURRENT_STAGE" "$name"
}

# ─── 진행률 업데이트 ─────────────
CURRENT_PCT=0
CURRENT_STEP_PCT=0

update_progress() {
  local step=$1 
  local prog=$2
  CURRENT_STEP_PCT=$prog
  
  local cum=0
  for ((i=0;i<step;i++)); do 
    cum=$((cum+main_step_weights[i]))
  done
  local contrib=$((main_step_weights[step]*prog/100))
  CURRENT_PCT=$((cum+contrib))
  
  # 100%를 초과하지 않도록 보정
  if [ "$CURRENT_PCT" -gt 100 ]; then
    CURRENT_PCT=100
  fi
  
  draw_progress_bar
}

# ─── 명령 실행 및 로깅 ───────────
log_cmd() {
  local cmd="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $cmd" >> "$log_file"
  LANG=C LC_ALL=C eval "$cmd" >> "$log_file" 2>&1
  return ${PIPESTATUS[0]}
}

# ─── 삭제/백업 작업 ──────────────────
delete_with_progress() {
  local ids=(); local cmd=$2; local act=$3
  while IFS= read -r l; do [[ -n "$l" ]] && ids+=("$l"); done <<< "$1"
  
  if (( ${#ids[@]} == 0 )); then
    echo_success "  - $act 대상 없음"
    update_progress $current_main_step 100
    return
  fi
  
  echo_info "▶️ $act (${#ids[@]})"
  local fails=()
  
  for i in "${!ids[@]}"; do
    log_cmd "$cmd ${ids[i]}"; code=$?
    update_progress $current_main_step $((100*(i+1)/${#ids[@]}))
    ((code)) && fails+=("${ids[i]}")
    sleep 0.05 # 진행 상황을 볼 수 있도록 약간의 지연
  done
  
  if (( ${#fails[@]} )); then
    echo_error "  - $act 실패: ${fails[*]}"
    # 실패한 볼륨 정보는 로그에만 기록
    if [[ "$act" == "볼륨 삭제" ]]; then
      for v in "${fails[@]}"; do
        echo "* 볼륨 '$v' 사용 컨테이너:" >> "$log_file"
        docker ps -a --filter "volume=$v" --format " → {{.Names}} ({{.ID}}) [{{.Status}}]" >> "$log_file"
      done
    fi
  else
    echo_success "  - $act 완료"
  fi
  
  # 실패 항목 반환
  echo "${fails[*]}"
}

backup_docker_config() {
  echo_info "▶️ 설정 백업..."
  mkdir -p ~/.docker_backup
  local steps=("컨텍스트" "Compose 파일" "설정 폴더")
  
  for idx in "${!steps[@]}"; do
    update_progress $current_main_step $(( (idx+1) * 100 / ${#steps[@]} ))
    
    case "${steps[idx]}" in
      "컨텍스트") log_cmd "docker context ls -q | xargs -r -I{} docker context export {} ~/.docker_backup/{}.tar" ;;  
      "Compose 파일") log_cmd "find . -maxdepth 3 -name \"docker-compose*.yml\" -exec cp {} ~/.docker_backup/ \\;" ;;  
      "설정 폴더") [[ -d ~/.docker ]] && log_cmd "(command -v rsync &>/dev/null && rsync -a --exclude='*.sock' ~/.docker/ ~/.docker_backup/docker_config/ || cp -r ~/.docker ~/.docker_backup/docker_config)" ;;  
    esac
    sleep 0.2 # 진행 상황을 볼 수 있도록 약간의 지연
  done
  
  echo_success "  - $MSG_BACKUP"
}

stop_running_containers() {
  local run=$(docker ps -q)
  if [[ -n "$run" ]]; then 
    delete_with_progress "$run" "docker stop" "컨테이너 종료"
  else 
    update_progress $current_main_step 100
    echo_success "- 실행 컨테이너 없음"
  fi
}

handle_swarm_resources() {
  if docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo_info "▶️ Swarm 리소스 삭제"
    delete_with_progress "$(docker service ls -q)" "docker service rm" "Swarm 서비스 삭제"
    log_cmd "docker swarm leave --force"
    update_progress $current_main_step 100
    echo_success "- Swarm 비활성화"
  fi
}

remove_docker_plugins() {
  delete_with_progress "$(docker plugin ls -q)" "docker plugin rm -f" "플러그인 삭제"
  update_progress $current_main_step 100
}

docker_reset() {
  set_current_step 0; backup_docker_config
  set_current_step 1; stop_running_containers
  set_current_step 2; handle_swarm_resources
  set_current_step 3; delete_with_progress "$(docker ps -aq)" "docker rm -f" "컨테이너 삭제"
  set_current_step 4; delete_with_progress "$(docker images -q)" "docker rmi -f" "이미지 삭제"
  set_current_step 5; delete_with_progress "$(docker volume ls -q)" "docker volume rm" "볼륨 삭제"
  set_current_step 6; delete_with_progress "$(docker network ls --filter type=custom -q)" "docker network rm" "네트워크 삭제"
  set_current_step 7; remove_docker_plugins
  
  set_current_step 8; 
    echo_info "▶️ 캐시 정리" 
    log_cmd "docker system prune -af --volumes"
    update_progress $current_main_step 50
    echo_success "- 캐시 삭제 완료"
  
    echo_info "▶️ 검증 & 안전망 프루닝"
    log_cmd "docker system prune -af --volumes"
    update_progress $current_main_step 100
}

confirm_prompt() {
  echo_warn "$MSG_WARNING"
  move_to_line $((CURRENT_MESSAGE_LINE + 1))
  read -p "$MSG_PROMPT" ans
  CURRENT_MESSAGE_LINE=$((CURRENT_MESSAGE_LINE + 2))
  
  case "$ans" in
    [Yy]*) return 0 ;;
    [Nn]*) echo_error "$MSG_CANCELED"; show_cursor; exit 1 ;;
    *) echo_warn "$MSG_YN_PROMPT"; confirm_prompt ;;
  esac
}

set_current_step() { 
  current_main_step=$1
  update_progress $1 0
}

cleanup() {
  show_cursor
  move_to_line $((PROGRESS_BAR_LINE + 2))
}

main() {
  # 초기 화면 설정
  clear_screen
  hide_cursor
  print_header
  
  # 트랩 설정 (스크립트 종료 시 커서 복원)
  trap cleanup EXIT
  
  # 진행 바 초기화
  update_progress 0 0
  
  # 실행 확인
  confirm_prompt
  
  # 리셋 실행
  docker_reset
  
  # 완료 메시지
  echo_success "$MSG_COMPLETE"
  echo_info "자세한 로그: $log_file"
  
  # 스크립트 종료 시 커서를 진행 바 아래로 이동
  move_to_line $((PROGRESS_BAR_LINE + 3))
}

# Docker 명령어 확인
command -v docker &>/dev/null || { echo_error "Docker 필요"; exit 1; }

# 실행
main
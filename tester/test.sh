#!/usr/bin/env bash

# modern_multi_progress.sh
# 모던한 터미널 진행 표시 바 (여러 개) - 컬러와 유니코드 블록 사용

bars=("Install" "Download" "Compile" "Test" "Deploy")
durations=(5 8 10 12 7)  # 각 바 완료까지 걸리는 시간(초)
width=30                # 바 너비

# ANSI 컬러 설정 (실제 ESC 문자 사용)
RESET=$'\e[0m'
FG_GREEN=$'\e[32m'
FG_CYAN=$'\e[36m'
BAR_FILLED=$'█'
BAR_EMPTY=$'░'

# 커서 숨기기
tput civis

# 초기 출력: 빈 바와 라벨 표시
for label in "${bars[@]}"; do
    printf "%-${width}s %s\n" "" "$label"
done

# 최대 시간 계산
max_time=0
for d in "${durations[@]}"; do (( d>max_time )) && max_time=$d; done

# 진행 표시 루프
for (( t=1; t<=max_time; t++ )); do
    # bars 수만큼 위로 이동
    printf "\033[%dA" "${#bars[@]}"

    for idx in "${!bars[@]}"; do
        d=${durations[idx]}
        label=${bars[idx]}
        if (( t >= d )); then
            percent=100
        else
            percent=$(( t * 100 / d ))
        fi
        filled=$(( percent * width / 100 ))
        empty=$(( width - filled ))

        # 색상: 완료된 바는 초록, 진행 중 바는 시안
        if (( percent == 100 )); then
            color=$FG_GREEN
        else
            color=$FG_CYAN
        fi

        # 진행 바 그리기
        printf "["
        # 채워진 부분
        printf "%s" "$color"
        for ((i=0; i<filled; i++)); do printf "%s" "$BAR_FILLED"; done
        printf "%s" "$RESET"
        # 빈 부분
        for ((i=0; i<empty; i++)); do printf "%s" "$BAR_EMPTY"; done
        printf "%s" "$RESET"
        # 퍼센트 및 라벨
        printf "] %s%3d%%%s - %s\n" "$color" "$percent" "$RESET" "$label"
    done

    sleep 1
done

# 완료 후 줄 바꿈 및 커서 복원
printf "\n"
tput cnorm

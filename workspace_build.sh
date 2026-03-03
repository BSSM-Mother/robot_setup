#!/bin/bash
# 워크스페이스 빌드 스크립트 (자동 클론 & 빌드)

set -e

echo "=========================================="
echo "워크스페이스 자동 설정 및 빌드 시작"
echo "=========================================="

# ROS_DISTRO 감지 함수
detect_ros_distro() {
    for distro in jazzy humble foxy; do
        if [ -f "/opt/ros/$distro/setup.bash" ]; then
            echo "$distro"
            return 0
        fi
    done
    echo "humble"
}

# 옵션 처리
ROS_DISTRO=""
REPO_URL="https://github.com/bitbyte08/robot_workspace.git"

while [[ $# -gt 0 ]]; do
    case $1 in
        --distro)
            ROS_DISTRO="$2"
            shift 2
            ;;
        --repo)
            REPO_URL="$2"
            shift 2
            ;;
        *)
            REPO_URL="$1"
            shift
            ;;
    esac
done

# 명시적으로 지정되지 않았으면 설치된 배포판 감지
if [ -z "$ROS_DISTRO" ]; then
    ROS_DISTRO=$(detect_ros_distro)
    echo "감지된 ROS 배포판: $ROS_DISTRO"
else
    echo "명시적으로 지정된 ROS 배포판: $ROS_DISTRO"
fi

if [ ! -f "/opt/ros/$ROS_DISTRO/setup.bash" ]; then
    echo "에러: /opt/ros/$ROS_DISTRO/setup.bash를 찾을 수 없습니다. 먼저 ROS2를 설치하세요."
    exit 1
fi
source /opt/ros/$ROS_DISTRO/setup.bash

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/robot_workspace"

echo "[1/5] 워크스페이스 초기화 중..."
if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "워크스페이스가 없습니다. 레포지토리에서 클론 중: $REPO_URL"
    mkdir -p "$(dirname "$WORKSPACE_DIR")"
    git clone "$REPO_URL" "$WORKSPACE_DIR" || { echo "에러: 레포지토리 클론 실패 ($REPO_URL)"; exit 1; }
    echo "클론 완료!"
else
    echo "기존 워크스페이스 사용: $WORKSPACE_DIR"
fi

cd "$WORKSPACE_DIR" || { echo "에러: 워크스페이스 디렉토리로 이동 실패: $WORKSPACE_DIR"; exit 1; }

echo "[2/5] 빌드 캐시 정리 중..."
if [ -d "build" ] || [ -d "install" ] || [ -d "log" ]; then
    echo "기존 빌드 결과물 제거 중..."
    rm -rf build install log
fi

echo "[3/5] Git 서브모듈 초기화 중..."
git submodule update --init --recursive

echo "[4/5] colcon 빌드 중 (symlink-install)..."
colcon build \
    --symlink-install \
    --cmake-args -DCMAKE_BUILD_TYPE=Release

echo "[5/5] 빌드 결과 검증 중..."
if [ -f "install/setup.bash" ]; then
    echo "빌드 성공!"
else
    echo "오류: 빌드 실패"
    exit 1
fi

echo "=========================================="
echo "워크스페이스 빌드 완료!"
echo "=========================================="

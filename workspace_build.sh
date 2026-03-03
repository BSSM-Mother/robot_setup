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
REPO_URL="https://github.com/BSSM-Mother/robot_workspace.git"
SKIP_DESCRIPTION=true
UPDATE_SUBMODULES=false

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
        --with-description)
            SKIP_DESCRIPTION=false
            shift
            ;;
        --update-submodules)
            UPDATE_SUBMODULES=true
            shift
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
if [ "$UPDATE_SUBMODULES" = true ]; then
    echo "서브모듈을 원격 최신 버전으로 업데이트 중..."
    git submodule update --init --recursive
    git submodule update --remote --recursive
    git submodule foreach --recursive git checkout origin/main 2>/dev/null || git submodule foreach --recursive git checkout origin/master 2>/dev/null || true
else
    echo "서브모듈을 저장된 버전으로 초기화 중..."
    git submodule update --init --recursive
fi

echo "[4/6] 패키지 리소스 디렉토리 검증 중..."
if [ -d "src/robot_description" ]; then
    if [ ! -d "src/robot_description/meshes" ]; then
        echo "경고: src/robot_description/meshes 디렉토리가 없어 생성합니다."
        mkdir -p "src/robot_description/meshes"
    fi
fi

echo "[5/6] colcon 빌드 중 (symlink-install)..."
if [ "$SKIP_DESCRIPTION" = true ]; then
    echo "실로봇 모드: robot_description 패키지 빌드 제외"
    colcon build \
        --symlink-install \
        --packages-skip robot_description \
        --cmake-args -DCMAKE_BUILD_TYPE=Release
else
    colcon build \
        --symlink-install \
        --cmake-args -DCMAKE_BUILD_TYPE=Release
fi

echo "[6/6] 빌드 결과 검증 중..."
if [ -f "install/setup.bash" ]; then
    echo "빌드 성공!"
else
    echo "오류: 빌드 실패"
    exit 1
fi

echo "=========================================="
echo "워크스페이스 빌드 완료!"
echo "=========================================="

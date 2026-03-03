#!/bin/bash
# ROS 의존성 설치 스크립트 (rosdep)

set -e

echo "=========================================="
echo "ROS 의존성(rosdep) 설치 시작"
echo "=========================================="

# ROS_DISTRO 감지 함수
detect_ros_distro() {
    # 시스템에 설치된 ROS 배포판 찾기
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
while [[ $# -gt 0 ]]; do
    case $1 in
        --distro)
            ROS_DISTRO="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# 명시적으로 지정되지 않았으면 감지
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

echo "[1/2] rosdep 초기화 중..."
sudo rosdep init 2>/dev/null || echo "rosdep 이미 초기화됨"
rosdep update

echo "[2/2] 워크스페이스 의존성 설치 중..."
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/robot_workspace"

if [ ! -d "$WORKSPACE_DIR/src" ]; then
    echo "에러: 워크스페이스의 src 디렉토리를 찾을 수 없습니다: $WORKSPACE_DIR/src"
    echo "먼저 workspace_build.sh를 실행하여 워크스페이스를 생성하세요."
    exit 1
fi

cd "$WORKSPACE_DIR"
rosdep install --from-paths src --ignore-src -y --rosdistro $ROS_DISTRO
echo "워크스페이스 의존성 설치 완료!"

echo "=========================================="
echo "ROS 의존성 설치 완료!"
echo "=========================================="

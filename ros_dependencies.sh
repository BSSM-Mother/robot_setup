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

ROS_DISTRO=$(detect_ros_distro)
echo "감지된 ROS 배포판: $ROS_DISTRO"
source /opt/ros/$ROS_DISTRO/setup.bash

echo "[1/2] rosdep 초기화 중..."
sudo rosdep init 2>/dev/null || echo "rosdep 이미 초기화됨"
rosdep update

echo "[2/2] 워크스페이스 의존성 설치 중..."
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../robot_workspace" && pwd)"

if [ -d "$WORKSPACE_DIR/src" ]; then
    cd "$WORKSPACE_DIR"
    rosdep install --from-paths src --ignore-src -y --rosdistro $ROS_DISTRO
    echo "워크스페이스 의존성 설치 완료!"
else
    echo "경고: 워크스페이스를 찾을 수 없습니다: $WORKSPACE_DIR"
fi

echo "=========================================="
echo "ROS 의존성 설치 완료!"
echo "=========================================="

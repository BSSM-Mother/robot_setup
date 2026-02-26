#!/bin/bash
# Python 의존성 설치 스크립트

set -e

echo "=========================================="
echo "Python 의존성 설치 시작"
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

ROS_DISTRO=$(detect_ros_distro)
source /opt/ros/$ROS_DISTRO/setup.bash

echo "[1/2] pip 업그레이드 중..."
pip3 install --break-system-packages --upgrade pip setuptools wheel

echo "[2/2] 프로젝트 Python 의존성 설치 중..."
# robot_perception 패키지의 requirements.txt가 있으면 설치
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../robot_workspace" && pwd)"

if [ -f "$WORKSPACE_DIR/src/robot_perception/requirements.txt" ]; then
    echo "robot_perception 의존성 설치 중..."
    pip3 install --break-system-packages -r "$WORKSPACE_DIR/src/robot_perception/requirements.txt"
fi

# 공통 Python 패키지
echo "공통 Python 패키지 설치 중..."
pip3 install --break-system-packages \
    "numpy<2" \
    scipy \
    matplotlib \
    opencv-python \
    torch \
    torchvision \
    ultralytics

echo "=========================================="
echo "Python 의존성 설치 완료!"
echo "=========================================="

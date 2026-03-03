#!/bin/bash
# 시스템 의존성 설치 스크립트 (최소설치)

set -e

echo "=========================================="
echo "시스템 의존성(apt) 설치 시작"
echo "=========================================="

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

# ROS 디스트로 감지
if [ -z "$ROS_DISTRO" ]; then
    ROS_DISTRO=$(detect_ros_distro)
    echo "감지된 ROS 배포판: $ROS_DISTRO"
else
    echo "명시적으로 지정된 ROS 배포판: $ROS_DISTRO"
fi

echo "[1/3] 기본 패키지 및 Git 설치 중..."
sudo apt-get update
sudo apt-get install -y \
    git \
    python3-pip \
    curl

echo "[2/3] ROS2 기본 패키지 설치 중..."
sudo apt-get install -y \
    ros-$ROS_DISTRO-std-msgs \
    ros-$ROS_DISTRO-sensor-msgs \
    ros-$ROS_DISTRO-geometry-msgs \
    ros-$ROS_DISTRO-tf2 \
    ros-$ROS_DISTRO-robot-state-publisher \
    ros-$ROS_DISTRO-ros-core \
    ros-$ROS_DISTRO-xacro \
    ros-$ROS_DISTRO-cv-bridge

echo "[3/3] rosdep 및 colcon 설치 중..."
sudo apt-get install -y \
    python3-rosdep \
    python3-colcon-common-extensions

echo "=========================================="
echo "시스템 의존성 설치 완료!"
echo "=========================================="

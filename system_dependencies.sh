#!/bin/bash
# 시스템 의존성 설치 스크립트 (최소설치)

set -e

echo "=========================================="
echo "시스템 의존성(apt) 설치 시작"
echo "=========================================="

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
    source /opt/ros/*/setup.bash 2>/dev/null
    ROS_DISTRO=$(echo $ROS_DISTRO_OVERRIDE 2>/dev/null || echo "humble")
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
    ros-$ROS_DISTRO-ros-core

echo "[3/3] rosdep 및 colcon 설치 중..."
sudo apt-get install -y \
    python3-rosdep \
    python3-colcon-common-extensions

echo "=========================================="
echo "시스템 의존성 설치 완료!"
echo "=========================================="

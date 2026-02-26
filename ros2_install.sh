#!/bin/bash
# ROS2 설치 스크립트 (우분투 버전 자동 감지)

set -e

echo "=========================================="
echo "ROS2 설치 시작"
echo "=========================================="

# 우분투 버전 감지
echo "[1/6] 우분투 버전 확인 중..."
source /etc/os-release
UBUNTU_VERSION=$VERSION_CODENAME
echo "감지된 버전: $UBUNTU_VERSION"

# 버전별 ROS2 매핑
case $UBUNTU_VERSION in
    focal)
        ROS_DISTRO="foxy"
        echo "Ubuntu 20.04 (Focal) -> ROS2 Foxy 설치"
        ;;
    jammy)
        ROS_DISTRO="humble"
        echo "Ubuntu 22.04 (Jammy) -> ROS2 Humble 설치"
        ;;
    noble)
        ROS_DISTRO="jazzy"
        echo "Ubuntu 24.04 (Noble) -> ROS2 Jazzy 설치"
        ;;
    *)
        echo "지원하지 않는 우분투 버전: $UBUNTU_VERSION"
        echo "지원 버전: focal, jammy, noble"
        exit 1
        ;;
esac

# 시스템 업데이트
echo "[2/6] 시스템 업데이트 중..."
sudo apt-get update
sudo apt-get upgrade -y

# 로케일 설정
echo "[3/6] 로케일 설정 중..."
sudo apt-get install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# 저장소 설정
echo "[4/6] ROS2 저장소 설정 중..."
sudo apt install -y curl gnupg lsb-release
sudo curl -sSL https://repo.ros2.org/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $UBUNTU_VERSION main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# ROS2 설치
echo "[5/6] ROS2 $ROS_DISTRO 설치 중..."
sudo apt-get update
sudo apt-get install -y ros-$ROS_DISTRO-ros-core

echo "[6/6] 환경 설정 중..."
echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> ~/.bashrc

echo "=========================================="
echo "ROS2 $ROS_DISTRO 설치 완료!"
echo "=========================================="

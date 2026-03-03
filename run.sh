#!/bin/bash
# 라즈베리파이 자동 설정 메인 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}라즈베리파이 로봇 시스템 자동 설정${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# 함수: 스크립트 실행 확인
run_script() {
    local script_name=$1
    local script_path="$SCRIPT_DIR/$script_name"
    shift
    
    if [ ! -f "$script_path" ]; then
        echo -e "${RED}오류: $script_path를 찾을 수 없습니다${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}실행: $script_name${NC}"
    chmod +x "$script_path"
    
    # 나머지 인자들 전달
    local exit_code=0
    if [ $# -gt 0 ]; then
        bash "$script_path" "$@" || exit_code=$?
    else
        bash "$script_path" || exit_code=$?
    fi

    if [ $exit_code -ne 0 ]; then
        return $exit_code
    fi
    echo ""
}

# 옵션 처리
SKIP_ROS2=false
SKIP_SYSTEM=false
SKIP_ROSDEP=false
SKIP_PYTHON=false
SKIP_BUILD=false
AUTO_LAUNCH=false
INSTALL_SERVICE=false
REPO_URL=""
ROS_DISTRO=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-ros2)
            SKIP_ROS2=true
            shift
            ;;
        --skip-system)
            SKIP_SYSTEM=true
            shift
            ;;
        --skip-rosdep)
            SKIP_ROSDEP=true
            shift
            ;;
        --skip-python)
            SKIP_PYTHON=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --distro)
            ROS_DISTRO="$2"
            shift 2
            ;;
        --launch)
            AUTO_LAUNCH=true
            shift
            ;;
        --repo)
            REPO_URL="$2"
            shift 2
            ;;
        --install-service)
            INSTALL_SERVICE=true
            shift
            ;;
        --help)
            echo "사용법: $0 [옵션]"
            echo ""
            echo "옵션:"
            echo "  --distro <name>   ROS2 배포판 명시적 지정 (jazzy, humble, foxy)"
            echo "  --skip-ros2       ROS2 설치 건너뛰기"
            echo "  --skip-system     시스템 의존성 설치 건너뛰기"
            echo "  --skip-rosdep     ROS 의존성 설치 건너뛰기"
            echo "  --skip-python     Python 의존성 설치 건너뛰기"
            echo "  --skip-build      워크스페이스 빌드 건너뛰기"
            echo "  --launch              빌드 후 시스템 자동 실행"
            echo "  --install-service     Systemd service로 등록 (부팅 시 자동 실행)"
            echo "  --repo <url>          레포지토리 URL 지정 (기본: bitbyte08/robot_workspace)"
            echo "  --help                이 도움말 표시"
            exit 0
            ;;
        *)
            echo -e "${RED}알 수 없는 옵션: $1${NC}"
            exit 1
            ;;
    esac
done

# 서로 다른 단계 실행
if [ "$SKIP_ROS2" = false ]; then
    if [ -n "$ROS_DISTRO" ]; then
        run_script "ros2_install.sh" --distro "$ROS_DISTRO" || { echo -e "${RED}ROS2 설치 실패${NC}"; exit 1; }
    else
        run_script "ros2_install.sh" || { echo -e "${RED}ROS2 설치 실패${NC}"; exit 1; }
    fi
else
    echo -e "${YELLOW}건너뜀: ROS2 설치${NC}"
fi

if [ "$SKIP_SYSTEM" = false ]; then
    if [ -n "$ROS_DISTRO" ]; then
        run_script "system_dependencies.sh" --distro "$ROS_DISTRO" || { echo -e "${RED}시스템 의존성 설치 실패${NC}"; exit 1; }
    else
        run_script "system_dependencies.sh" || { echo -e "${RED}시스템 의존성 설치 실패${NC}"; exit 1; }
    fi
else
    echo -e "${YELLOW}건너뜀: 시스템 의존성 설치${NC}"
fi

if [ "$SKIP_ROSDEP" = false ]; then
    if [ -n "$ROS_DISTRO" ]; then
        run_script "ros_dependencies.sh" --distro "$ROS_DISTRO" || { echo -e "${RED}ROS 의존성 설치 실패${NC}"; exit 1; }
    else
        run_script "ros_dependencies.sh" || { echo -e "${RED}ROS 의존성 설치 실패${NC}"; exit 1; }
    fi
else
    echo -e "${YELLOW}건너뜀: ROS 의존성 설치${NC}"
fi

if [ "$SKIP_PYTHON" = false ]; then
    if [ -n "$ROS_DISTRO" ]; then
        run_script "python_dependencies.sh" --distro "$ROS_DISTRO" || { echo -e "${RED}Python 의존성 설치 실패${NC}"; exit 1; }
    else
        run_script "python_dependencies.sh" || { echo -e "${RED}Python 의존성 설치 실패${NC}"; exit 1; }
    fi
else
    echo -e "${YELLOW}건너뜀: Python 의존성 설치${NC}"
fi

if [ "$SKIP_BUILD" = false ]; then
    if [ -n "$ROS_DISTRO" ]; then
        run_script "workspace_build.sh" --distro "$ROS_DISTRO" --repo "${REPO_URL:-https://github.com/bitbyte08/robot_workspace.git}" || { echo -e "${RED}워크스페이스 빌드 실패${NC}"; exit 1; }
    else
        run_script "workspace_build.sh" --repo "${REPO_URL:-https://github.com/bitbyte08/robot_workspace.git}" || { echo -e "${RED}워크스페이스 빌드 실패${NC}"; exit 1; }
    fi
else
    echo -e "${YELLOW}건너뜀: 워크스페이스 빌드${NC}"
fi

echo -e "${GREEN}=========================================${NC}"
if [ "$INSTALL_SERVICE" = true ]; then
    if [ -n "$ROS_DISTRO" ]; then
        run_script "install_service.sh" --distro "$ROS_DISTRO" || { echo -e "${RED}Service 설치 실패${NC}"; exit 1; }
    else
        run_script "install_service.sh" || { echo -e "${RED}Service 설치 실패${NC}"; exit 1; }
    fi
else
    echo -e "${YELLOW}건너뜀: Service 설치${NC}"
fi

echo -e "${GREEN}✓ 모든 설정 완료!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# 자동 실행 옵션
if [ "$AUTO_LAUNCH" = true ]; then
    if [ -z "$ROS_DISTRO" ]; then
        ROS_DISTRO=$(detect_ros_distro)
    fi

    echo -e "${YELLOW}시스템 실행 준비 중...${NC}"

    WORKSPACE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)/robot_workspace"
    if [ ! -f "/opt/ros/$ROS_DISTRO/setup.bash" ]; then
        echo -e "${RED}오류: /opt/ros/$ROS_DISTRO/setup.bash를 찾을 수 없습니다${NC}"
        exit 1
    fi
    if [ ! -f "$WORKSPACE_DIR/install/setup.bash" ]; then
        echo -e "${RED}오류: $WORKSPACE_DIR/install/setup.bash를 찾을 수 없습니다${NC}"
        exit 1
    fi

    source /opt/ros/$ROS_DISTRO/setup.bash
    source "$WORKSPACE_DIR/install/setup.bash"

    export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
    export ROS_DOMAIN_ID=0
    export ROS_LOCALHOST_ONLY=0

    echo -e "${GREEN}로봇 시스템 시작 중...${NC}"
    echo ""
    ros2 launch robot_launch system.launch.py
else
    echo "다음 단계:"
    echo "1. 터미널을 다시 열거나 다음 명령 실행:"
    echo "   source ~/.bashrc"
    echo ""
    echo "2. 로봇 시스템 시작:"
    echo "   source ~/robot_workspace/install/setup.bash"
    echo "   ros2 launch robot_launch system.launch.py"
    echo ""
    echo "또는 한 명령으로:"
    echo "   bash $SCRIPT_DIR/run.sh --launch"
    echo ""
fi

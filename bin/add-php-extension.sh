#!/bin/bash
# 快速添加 PHP 扩展脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 使用说明
usage() {
    echo "使用方法: $0 <php版本> <扩展名> [版本号]"
    echo ""
    echo "参数说明:"
    echo "  php版本    : 73, 74 或 83"
    echo "  扩展名     : 要安装的扩展名称"
    echo "  版本号     : 可选，指定扩展版本"
    echo ""
    echo "示例:"
    echo "  $0 83 mongodb 1.17.0    # 在 PHP 8.3 中安装 MongoDB 1.17.0"
    echo "  $0 74 swoole            # 在 PHP 7.4 中安装最新版 Swoole"
    echo ""
    echo "常用扩展:"
    echo "  mongodb, swoole, memcached, grpc, protobuf"
    exit 1
}

# 检查参数
if [ $# -lt 2 ]; then
    usage
fi

PHP_VERSION=$1
EXTENSION=$2
EXT_VERSION=${3:-""}

# 验证 PHP 版本
if [[ ! "$PHP_VERSION" =~ ^(73|74|83)$ ]]; then
    echo -e "${RED}错误: PHP 版本必须是 73, 74 或 83${NC}"
    exit 1
fi

DOCKERFILE="services/php/${PHP_VERSION}/Dockerfile"

if [ ! -f "$DOCKERFILE" ]; then
    echo -e "${RED}错误: Dockerfile 不存在: $DOCKERFILE${NC}"
    exit 1
fi

# 构建 PECL 安装命令
if [ -n "$EXT_VERSION" ]; then
    PECL_INSTALL="pecl install ${EXTENSION}-${EXT_VERSION}"
else
    PECL_INSTALL="pecl install ${EXTENSION}"
fi

# 检查是否已经安装
if grep -q "pecl install ${EXTENSION}" "$DOCKERFILE" || grep -q "docker-php-ext-enable ${EXTENSION}" "$DOCKERFILE"; then
    echo -e "${YELLOW}警告: 扩展 ${EXTENSION} 可能已经在 Dockerfile 中${NC}"
    read -p "是否继续添加? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# 添加扩展到 Dockerfile
echo -e "${GREEN}正在添加 ${EXTENSION} 扩展到 PHP ${PHP_VERSION}...${NC}"

# 在 WORKDIR 之前插入
sed -i "/^WORKDIR/i\\
# 安装 ${EXTENSION} 扩展\\
RUN ${PECL_INSTALL} \\\\\\
    && docker-php-ext-enable ${EXTENSION}\\
" "$DOCKERFILE"

echo -e "${GREEN}✓ 已添加扩展配置到 $DOCKERFILE${NC}"
echo ""
echo -e "${YELLOW}下一步操作:${NC}"
echo "1. 查看 Dockerfile 确认修改:"
echo "   cat $DOCKERFILE"
echo ""
echo "2. 重新构建镜像:"
echo "   docker-compose build --no-cache php${PHP_VERSION}"
echo ""
echo "3. 重启容器:"
echo "   make down && make up"
echo ""
echo "4. 验证扩展安装:"
echo "   make php${PHP_VERSION}"
echo "   php -m | grep ${EXTENSION}"

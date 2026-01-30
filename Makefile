# Docker LNMP Makefile
# 使用示例：make up, make php83, make composer83 p=myproject cmd="install"

# --- 颜色定义 ---
RED     := \033[0;31m
GREEN   := \033[0;32m
YELLOW  := \033[1;33m
BLUE    := \033[0;34m
MAGENTA := \033[0;35m
CYAN    := \033[0;36m
RESET   := \033[0m

# --- 变量定义 ---
UID := $(shell id -u)
GID := $(shell id -g)
DOCKER_COMPOSE := docker compose
PROJECT_NAME := lnmp

# 检测操作系统
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    OPEN_CMD := xdg-open
else ifeq ($(UNAME_S),Darwin)
    OPEN_CMD := open
else
    OPEN_CMD := start
endif

# --- 默认目标 ---
.DEFAULT_GOAL := help

# --- 服务控制 ---
.PHONY: init
init: ## 初始化项目（首次使用）
	@echo "$(CYAN)初始化 LNMP 开发平台...$(RESET)"
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)复制 .env.example 为 .env$(RESET)"; \
		cp .env.example .env; \
		echo "$(YELLOW)请编辑 .env 文件设置密码$(RESET)"; \
	fi
	@$(MAKE) cert
	@echo "$(CYAN)拉取 Docker 镜像...$(RESET)"
	@$(DOCKER_COMPOSE) pull
	@echo "$(CYAN)构建 PHP 镜像...$(RESET)"
	@$(DOCKER_COMPOSE) build
	@echo "$(CYAN)启动服务...$(RESET)"
	@$(MAKE) up
	@echo ""
	@echo "$(GREEN)初始化完成！$(RESET)"
	@$(MAKE) status

.PHONY: ps status
ps: status
status: ## 查看所有容器状态
	@$(DOCKER_COMPOSE) ps -a

.PHONY: up
up: ## 启动所有服务
	@echo "$(CYAN)启动服务...$(RESET)"
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)服务已启动$(RESET)"

.PHONY: stop
stop: ## 停止服务但不删除容器
	@echo "$(YELLOW)停止服务...$(RESET)"
	@$(DOCKER_COMPOSE) stop
	@echo "$(GREEN)服务已停止$(RESET)"

.PHONY: down
down: ## 停止并删除所有容器
	@echo "$(YELLOW)停止并删除容器...$(RESET)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)容器已删除$(RESET)"

.PHONY: restart
restart: ## 重启服务 (可选: s=服务名)
	@if [ -z "$(s)" ]; then \
		echo "$(CYAN)重启所有服务...$(RESET)"; \
		$(DOCKER_COMPOSE) restart; \
	else \
		echo "$(CYAN)重启服务: $(s)$(RESET)"; \
		$(DOCKER_COMPOSE) restart $(s); \
	fi
	@echo "$(GREEN)重启完成$(RESET)"

.PHONY: logs
logs: ## 查看日志 (可选: s=服务名)
	@if [ -z "$(s)" ]; then \
		$(DOCKER_COMPOSE) logs -f; \
	else \
		$(DOCKER_COMPOSE) logs -f $(s); \
	fi

.PHONY: pull
pull: ## 更新所有 Docker 镜像
	@echo "$(CYAN)拉取最新镜像...$(RESET)"
	@$(DOCKER_COMPOSE) pull
	@echo "$(GREEN)镜像更新完成$(RESET)"

# --- PHP 容器访问 ---
.PHONY: php73 php74 php83 shell
php73: ## 进入 PHP 7.3 容器
	@$(DOCKER_COMPOSE) exec php73 /bin/bash

php74: ## 进入 PHP 7.4 容器
	@$(DOCKER_COMPOSE) exec php74 /bin/bash

php83: ## 进入 PHP 8.3 容器
	@$(DOCKER_COMPOSE) exec php83 /bin/bash

shell: php83 ## 进入默认 PHP 容器 (php83)

# --- Composer ---
define run_composer
	@if [ -z "$(cmd)" ]; then \
		echo "$(RED)错误: 请指定 cmd 参数$(RESET)"; \
		echo "$(YELLOW)示例: make composer$(1) p=项目名 cmd=\"install\"$(RESET)"; \
		exit 1; \
	fi; \
	if [ -z "$(p)" ]; then \
		echo "$(CYAN)执行: composer $(cmd) (PHP $(1))$(RESET)"; \
		$(DOCKER_COMPOSE) exec php$(1) composer $(cmd); \
	else \
		echo "$(CYAN)在 $(p) 中执行: composer $(cmd) (PHP $(1))$(RESET)"; \
		$(DOCKER_COMPOSE) exec -w /var/www/html/$(p) php$(1) composer $(cmd); \
	fi
endef

.PHONY: composer73 composer74 composer83 composer
composer73: ## PHP 7.3 Composer (p=项目 cmd="命令")
	$(call run_composer,73)

composer74: ## PHP 7.4 Composer (p=项目 cmd="命令")
	$(call run_composer,74)

composer83: ## PHP 8.3 Composer (p=项目 cmd="命令")
	$(call run_composer,83)

composer: composer83 ## 默认使用 PHP 8.3 Composer

# --- PHP 命令执行 ---
.PHONY: php
php: ## 执行 PHP 命令 (ver=83 p=项目 cmd="命令")
	@if [ -z "$(cmd)" ]; then \
		echo "$(RED)错误: 请指定 cmd 参数$(RESET)"; \
		exit 1; \
	fi; \
	VER=$${ver:-83}; \
	if [ -z "$(p)" ]; then \
		$(DOCKER_COMPOSE) exec php$$VER php $(cmd); \
	else \
		$(DOCKER_COMPOSE) exec -w /var/www/html/$(p) php$$VER php $(cmd); \
	fi

# --- Nginx ---
.PHONY: nginx nginx-test nginx-reload
nginx: ## 执行 Nginx 命令 (cmd="命令")
	@if [ -z "$(cmd)" ]; then \
		echo "$(RED)请指定 cmd 参数$(RESET)"; \
		exit 1; \
	fi
	@$(DOCKER_COMPOSE) exec nginx nginx $(cmd)

nginx-test: ## 测试 Nginx 配置
	@echo "$(CYAN)测试 Nginx 配置...$(RESET)"
	@$(DOCKER_COMPOSE) exec nginx nginx -t && \
		echo "$(GREEN)配置文件语法正确$(RESET)" || \
		echo "$(RED)配置文件有错误$(RESET)"

nginx-reload: ## 重新加载 Nginx 配置
	@echo "$(CYAN)重新加载 Nginx 配置...$(RESET)"
	@$(DOCKER_COMPOSE) exec nginx nginx -s reload
	@echo "$(GREEN)配置已重新加载$(RESET)"

# --- 项目创建 ---
.PHONY: laravel
laravel: ## 创建 Laravel 项目 (name=项目名 php=版本)
	@if [ -z "$(name)" ]; then \
		echo "$(RED)错误: 请指定项目名称$(RESET)"; \
		echo "$(YELLOW)用法: make laravel name=myproject php=83$(RESET)"; \
		exit 1; \
	fi
	@VER=$${php:-83}; \
	echo "$(CYAN)创建 Laravel 项目: $(name) (PHP $$VER)$(RESET)"; \
	$(DOCKER_COMPOSE) exec -w /var/www/html php$$VER composer create-project laravel/laravel $(name) && \
	$(DOCKER_COMPOSE) exec -w /var/www/html/$(name) php$$VER chmod -R 775 storage bootstrap/cache && \
	echo "" && \
	echo "$(GREEN)Laravel 项目创建成功！$(RESET)" && \
	echo "$(YELLOW)下一步:$(RESET)" && \
	echo "   1. 在 services/nginx/conf/ 创建虚拟主机配置" && \
	echo "   2. 在 hosts 文件添加域名映射" && \
	echo "   3. 运行 make nginx-reload"

# --- 数据库 ---
.PHONY: mysql mysql-dump mysql-restore
mysql: ## 连接 MySQL 数据库
	@echo "$(CYAN)连接 MySQL...$(RESET)"
	@$(DOCKER_COMPOSE) exec mysql mysql -uroot -p$${MYSQL_ROOT_PASSWORD:-123456}

mysql-dump: ## 备份数据库 (db=数据库名 file=文件名)
	@if [ -z "$(db)" ]; then \
		echo "$(RED)请指定数据库: db=数据库名$(RESET)"; \
		exit 1; \
	fi; \
	FILE=$${file:-backup_$(db)_$$(date +%Y%m%d_%H%M%S).sql}; \
	echo "$(CYAN)备份数据库 $(db) 到 $$FILE...$(RESET)"; \
	$(DOCKER_COMPOSE) exec -T mysql mysqldump -uroot -p$${MYSQL_ROOT_PASSWORD:-123456} $(db) > $$FILE && \
	echo "$(GREEN)备份完成: $$FILE$(RESET)"

mysql-restore: ## 恢复数据库 (db=数据库名 file=文件名)
	@if [ -z "$(db)" ] || [ -z "$(file)" ]; then \
		echo "$(RED)请指定数据库和文件: db=数据库名 file=备份文件$(RESET)"; \
		exit 1; \
	fi; \
	if [ ! -f "$(file)" ]; then \
		echo "$(RED)文件不存在: $(file)$(RESET)"; \
		exit 1; \
	fi; \
	echo "$(CYAN)恢复数据库 $(db) 从 $(file)...$(RESET)"; \
	$(DOCKER_COMPOSE) exec -T mysql mysql -uroot -p$${MYSQL_ROOT_PASSWORD:-123456} $(db) < $(file) && \
	echo "$(GREEN)恢复完成$(RESET)"

# --- Redis ---
.PHONY: redis redis-cli
redis: redis-cli
redis-cli: ## 连接 Redis
	@echo "$(CYAN)连接 Redis...$(RESET)"
	@$(DOCKER_COMPOSE) exec redis redis-cli -a $${REDIS_PASSWORD:-123456}

# --- 镜像管理 ---
.PHONY: rebuild rebuild-all
rebuild: ## 重建 PHP 镜像 (php=版本)
	@if [ -z "$(php)" ]; then \
		echo "$(RED)请指定 PHP 版本$(RESET)"; \
		echo "$(YELLOW)用法: make rebuild php=83$(RESET)"; \
		exit 1; \
	fi
	@echo "$(CYAN)重建 PHP $(php) 镜像...$(RESET)"
	@$(DOCKER_COMPOSE) build --no-cache php$(php)
	@echo "$(GREEN)PHP $(php) 重建完成$(RESET)"
	@echo "$(YELLOW)提示: 运行 'make restart s=php$(php)' 重启容器$(RESET)"

rebuild-all: ## 重建所有镜像
	@echo "$(CYAN)重建所有镜像...$(RESET)"
	@$(DOCKER_COMPOSE) build --no-cache
	@echo "$(GREEN)所有镜像重建完成$(RESET)"

# --- SSL 证书 ---
.PHONY: cert clean-cert
cert: ## 生成 SSL 证书
	@mkdir -p certbot
	@if [ -f certbot/ssl.pem ] && [ -f certbot/ssl-key.pem ]; then \
		echo "$(GREEN)SSL证书已存在$(RESET)"; \
	else \
		echo "$(CYAN)生成 SSL 证书...$(RESET)"; \
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
			-keyout certbot/ssl-key.pem \
			-out certbot/ssl.pem \
			-subj "/C=CN/ST=Beijing/L=Beijing/O=Dev/CN=*.local" 2>/dev/null && \
		echo "$(GREEN)SSL证书生成完成$(RESET)"; \
	fi

clean-cert: ## 清理 SSL 证书
	@echo "$(YELLOW)清理 SSL 证书...$(RESET)"
	@rm -f certbot/ssl.pem certbot/ssl-key.pem
	@echo "$(GREEN)SSL证书已清理$(RESET)"

# --- 诊断 ---
.PHONY: doctor check
doctor: check
check: ## 系统诊断检查
	@echo "$(CYAN)系统诊断...$(RESET)"
	@echo ""
	@echo "$(MAGENTA)=== Docker 状态 ===$(RESET)"
	@docker --version
	@docker compose --version
	@echo ""
	@echo "$(MAGENTA)=== 容器状态 ===$(RESET)"
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "$(MAGENTA)=== 网络状态 ===$(RESET)"
	@docker network ls | grep $(PROJECT_NAME) || echo "$(YELLOW)网络未创建$(RESET)"
	@echo ""
	@echo "$(MAGENTA)=== 端口占用检查 ===$(RESET)"
	@for port in 80 443 3306 6379; do \
		if lsof -Pi :$$port -sTCP:LISTEN -t >/dev/null 2>&1; then \
			echo "$(GREEN)端口 $$port 已占用$(RESET)"; \
		else \
			echo "$(YELLOW)端口 $$port 未使用$(RESET)"; \
		fi; \
	done
	@echo ""
	@echo "$(MAGENTA)=== SSL 证书检查 ===$(RESET)"
	@if [ -f certbot/ssl.pem ]; then \
		echo "$(GREEN)SSL证书存在$(RESET)"; \
	else \
		echo "$(RED)SSL证书不存在，运行 'make cert' 生成$(RESET)"; \
	fi

# --- 清理 ---
.PHONY: clean clean-all
clean: ## 清理临时文件
	@echo "$(YELLOW)清理临时文件...$(RESET)"
	@find . -type f -name "*.log" -delete 2>/dev/null || true
	@echo "$(GREEN)清理完成$(RESET)"

clean-all: down ## 清理所有容器、卷和网络
	@echo "$(RED)警告: 这将删除所有数据！$(RESET)"
	@echo -n "$(YELLOW)确认继续? [y/N] $(RESET)" && read ans && [ $${ans:-N} = y ]
	@$(DOCKER_COMPOSE) down -v --remove-orphans
	@echo "$(GREEN)清理完成$(RESET)"

# --- 信息 ---
.PHONY: info services
info: services
services: ## 显示所有服务信息
	@echo "$(CYAN)服务信息$(RESET)"
	@echo ""
	@echo "$(MAGENTA)数据库服务:$(RESET)"
	@echo "  MySQL: localhost:3306"
	@echo "  Redis: localhost:6379"
	@echo ""
	@echo "$(MAGENTA)PHP 版本:$(RESET)"
	@echo "  PHP 7.3: make php73"
	@echo "  PHP 7.4: make php74"
	@echo "  PHP 8.3: make php83"

# --- 帮助 ---
.PHONY: help
help: ## 显示帮助信息
	@echo ""
	@echo "$(CYAN)Docker LNMP - 多版本 PHP 开发平台$(RESET)"
	@echo ""
	@echo "$(MAGENTA)服务管理:$(RESET)"
	@echo "  $(GREEN)make init$(RESET)          初始化项目"
	@echo "  $(GREEN)make up$(RESET)            启动服务"
	@echo "  $(GREEN)make down$(RESET)          停止并删除容器"
	@echo "  $(GREEN)make restart$(RESET)       重启服务 (s=服务名)"
	@echo "  $(GREEN)make status$(RESET)        查看状态"
	@echo "  $(GREEN)make logs$(RESET)          查看日志 (s=服务名)"
	@echo ""
	@echo "$(MAGENTA)PHP 容器:$(RESET)"
	@echo "  $(GREEN)make php73$(RESET)         进入 PHP 7.3"
	@echo "  $(GREEN)make php74$(RESET)         进入 PHP 7.4"
	@echo "  $(GREEN)make php83$(RESET)         进入 PHP 8.3"
	@echo ""
	@echo "$(MAGENTA)Composer:$(RESET)"
	@echo "  $(GREEN)make composer83 p=项目 cmd=\"install\"$(RESET)"
	@echo ""
	@echo "$(MAGENTA)数据库:$(RESET)"
	@echo "  $(GREEN)make mysql$(RESET)         连接 MySQL"
	@echo "  $(GREEN)make redis-cli$(RESET)     连接 Redis"
	@echo "  $(GREEN)make mysql-dump db=mydb$(RESET)"
	@echo ""
	@echo "$(MAGENTA)Nginx:$(RESET)"
	@echo "  $(GREEN)make nginx-test$(RESET)    测试配置"
	@echo "  $(GREEN)make nginx-reload$(RESET)  重载配置"
	@echo ""
	@echo "$(MAGENTA)其他:$(RESET)"
	@echo "  $(GREEN)make laravel name=项目$(RESET)  创建 Laravel 项目"
	@echo "  $(GREEN)make rebuild php=83$(RESET)     重建 PHP 镜像"
	@echo "  $(GREEN)make doctor$(RESET)             系统诊断"
	@echo ""

.PHONY: version
version: ## 显示版本信息
	@echo "$(CYAN)Docker LNMP v1.0$(RESET)"
	@$(DOCKER_COMPOSE) exec php73 php -v 2>/dev/null | head -1 | sed 's/^/  PHP 7.3: /' || echo "  PHP 7.3: 未运行"
	@$(DOCKER_COMPOSE) exec php74 php -v 2>/dev/null | head -1 | sed 's/^/  PHP 7.4: /' || echo "  PHP 7.4: 未运行"
	@$(DOCKER_COMPOSE) exec php83 php -v 2>/dev/null | head -1 | sed 's/^/  PHP 8.3: /' || echo "  PHP 8.3: 未运行"

# Docker LNMP

基于 Docker Compose 的多版本 PHP 开发平台，支持 PHP 7.3、7.4、8.3。

## 特性

- Nginx + PHP-FPM + MySQL 8.0 + Redis
- 多版本 PHP 支持 (7.3, 7.4, 8.3)
- 完整的 PHP 扩展预装 (GD, Redis, Xdebug, ImageMagick 等)
- Xdebug 调试支持
- Composer 预装
- 便捷的 Makefile 命令

## 首先安装 docker

[Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
[Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
[Docker Engine for Linux](https://docs.docker.com/engine/install/)

配置 daemon 配置文件：

```yaml
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "features": {
    "buildkit": true
  },
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.m.daocloud.io",
    "https://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://gst6rzl9.mirror.aliyuncs.com"
  ],
  "dns": [
    "8.8.8.8",
    "114.114.114.114"
  ]
}
```


## 快速开始

```bash
# 1. 克隆项目
git clone <repo-url> docker_lnmp
cd docker_lnmp

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 设置数据库密码

# 3. 初始化并启动
make init
```

## 目录结构

```
docker_lnmp/
├── docker-compose.yml
├── Makefile
├── .env.example
├── certbot/              # SSL 证书
├── logs/                 # 日志目录
├── mysql/                # MySQL 数据
│   ├── data/             # 数据文件 (gitignore)
│   └── conf/             # 自定义配置
└── services/
    ├── nginx/
    │   ├── nginx.conf
    │   └── conf/         # 虚拟主机配置
    └── php/
        ├── 73/
        ├── 74/
        └── 83/
```

## 代码目录

项目代码挂载自 `~/www`（宿主机家目录下的 www），映射到容器内 `/var/www/html`。

## 常用命令

### 服务管理

```bash
make up              # 启动服务
make down            # 停止并删除容器
make restart         # 重启所有服务
make restart s=nginx # 重启指定服务
make status          # 查看状态
make logs            # 查看日志
make logs s=php83    # 查看指定服务日志
```

### PHP 容器

```bash
make php73           # 进入 PHP 7.3
make php74           # 进入 PHP 7.4
make php83           # 进入 PHP 8.3
```

### Composer

```bash
make composer83 p=myproject cmd="install"
make composer83 p=myproject cmd="require guzzlehttp/guzzle"
make composer83 cmd="--version"
```

### 数据库

```bash
make mysql                              # 连接 MySQL
make mysql-dump db=mydb                 # 备份
make mysql-dump db=mydb file=backup.sql # 指定文件名
make mysql-restore db=mydb file=backup.sql
make redis-cli                          # 连接 Redis
```

### Nginx

```bash
make nginx-test      # 测试配置
make nginx-reload    # 重载配置
```

### 项目创建

```bash
make laravel name=myproject php=83
```

## 添加新项目

1. 在 `~/www/` 下创建或克隆项目

2. 在 `services/nginx/conf/` 创建虚拟主机配置：

```nginx
server {
    listen 80;
    server_name myproject.local;
    root /var/www/html/myproject/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php83:9000;  # 选择 PHP 版本
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

3. 修改 hosts 文件添加域名映射：
```
127.0.0.1 myproject.local
```

4. 重载 Nginx：
```bash
make nginx-reload
```

## 容器间通信

容器内使用服务名访问：

- MySQL: `mysql:3306`
- Redis: `redis:6379`

## PHP 扩展

预装扩展列表：

- 数据库: mysqli, pdo_mysql, pdo_pgsql, pdo_sqlite
- 缓存: redis, memcached, apcu
- 图像: gd, imagick
- 其他: xdebug, opcache, mbstring, zip, intl, bcmath, soap, xsl 等

### 添加扩展

使用脚本添加 PECL 扩展：

```bash
# 添加扩展到 Dockerfile
./bin/add-php-extension.sh <php版本> <扩展名> [版本号]

# 示例
./bin/add-php-extension.sh 83 mongodb 1.17.0
./bin/add-php-extension.sh 74 swoole

# 或使用 make 命令
make add-ext php=83 ext=mongodb ver=1.17.0
```

添加后需重建镜像：`make rebuild php=83`

## Xdebug 配置

默认配置支持 PHPStorm 调试：

- 模式: debug
- 端口: 9003
- IDE Key: PHPSTORM
- 触发方式: 需要 `XDEBUG_TRIGGER` cookie 或参数

## 更多命令

```bash
make help    # 查看所有命令
make doctor  # 系统诊断
make version # 查看版本
```

## License

MIT

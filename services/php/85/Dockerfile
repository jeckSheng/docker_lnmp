FROM php:8.5.12-fpm

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    unzip \
    zip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libxslt-dev \
    libzip-dev \
    libicu-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libmagickwand-dev \
    libmemcached-dev \
    libpq-dev \
    libsqlite3-dev \
    libwebp-dev \
    libxpm-dev \
    libbz2-dev \
    libreadline-dev \
    libgmp-dev \
    libtidy-dev \
    libldap2-dev \
    libsasl2-dev \
    libsnmp-dev \
    librabbitmq-dev \
    libssh2-1-dev \
    zlib1g-dev \
    libavif-dev \
    && rm -rf /var/lib/apt/lists/*

# 配置 GD 扩展（支持 AVIF）
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    --with-xpm \
    --with-avif

# 配置 LDAP 扩展
RUN docker-php-ext-configure ldap --with-libdir=lib/$(dpkg-architecture --query DEB_BUILD_MULTIARCH)

# 安装 PHP 核心扩展（PHP 8.5 起 opcache 内置，无需再装）
RUN docker-php-ext-install -j$(nproc) \
    mysqli \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl \
    sockets \
    soap \
    xsl \
    gettext \
    bz2 \
    calendar \
    dba \
    gmp \
    iconv \
    sysvmsg \
    sysvsem \
    sysvshm \
    tidy \
    ldap \
    ftp

# 安装 PECL 扩展
RUN pecl channel-update pecl.php.net \
    && rm -rf /tmp/pear/download/* \
    && pecl install \
        xdebug \
        imagick \
        memcached \
        apcu \
        igbinary \
        msgpack \
        && docker-php-ext-enable \
        xdebug \
        imagick \
        memcached \
        apcu \
        igbinary \
        msgpack

# 复制配置
COPY php.ini /usr/local/etc/php/
COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# 安装 Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 安装 Redis 扩展（phpredis 5.x 不支持 PHP 8.5，改用 pecl 6.x）
RUN pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /tmp/pear

# 清理
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /var/www/html


# ========== 修复 VSCode 权限问题 ==========
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

# 创建用户并设置家目录
RUN groupadd --gid $USER_GID $USERNAME 2>/dev/null || true && \
    useradd --uid $USER_UID --gid $USER_GID -m -d /home/vscode -s /bin/bash $USERNAME 2>/dev/null || true && \
    usermod -aG www-data $USERNAME && \
    chown -R $USERNAME:$USERNAME /home/vscode

# 设置环境变量（关键！）
ENV HOME=/home/vscode
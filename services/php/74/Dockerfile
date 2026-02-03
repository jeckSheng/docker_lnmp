FROM php:7.4-fpm

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
    libmcrypt-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# 配置 GD 扩展
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    --with-xpm

# 配置 LDAP 扩展
RUN docker-php-ext-configure ldap --with-libdir=lib/$(dpkg-architecture --query DEB_BUILD_MULTIARCH)

# 安装 PHP 核心扩展
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
    opcache \
    gd \
    zip \
    intl \
    sockets \
    soap \
    xmlrpc \
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
        xdebug-3.1.6 \
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

# 安装 Redis 扩展
COPY ./phpredis-5.3.7.tar.gz /tmp/phpredis-5.3.7.tar.gz

RUN cd /tmp/ && \
    tar zxvf phpredis-5.3.7.tar.gz \
    && cd phpredis-5.3.7 \
    && phpize \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && docker-php-ext-enable redis \
    && rm -rf /tmp/*

# 清理
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /var/www/html

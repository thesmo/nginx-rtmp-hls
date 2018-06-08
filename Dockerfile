#most of this from https://github.com/tiangolo/nginx-rtmp-docker/blob/master/Dockerfile

FROM buildpack-deps:stretch

LABEL maintainer="cosmo@eveny.net"
LABEL build="docker build -t ngrtmphls ."
LABEL run="docker run -d -p 1935:1935 -p 8000:8000 --name nginx-rtmp-hls ngrtmphls"

ENV NGINX_VERSION nginx-1.15.0
ENV NGINX_RTMP_MODULE_VERSION 1.2.1

RUN apt-get update && \
    apt-get install -y ca-certificates openssl libssl-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/build/nginx && \
    cd /tmp/build/nginx && \
    wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar xf ${NGINX_VERSION}.tar.gz

RUN mkdir -p /tmp/build/nginx-rtmp-module && \
    cd /tmp/build/nginx-rtmp-module && \
    wget -O nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz \
        https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    tar xf nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    cd nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}

RUN cd /tmp/build/nginx/${NGINX_VERSION} && \
    ./configure \
        --sbin-path=/usr/local/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/lock/nginx/nginx.lock \
        --http-log-path=/var/log/nginx/access.log \
        --http-client-body-temp-path=/tmp/nginx-client-body \
        --with-http_ssl_module \
        --with-threads \
        --with-ipv6 \
        --add-module=/tmp/build/nginx-rtmp-module/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} && \
    make -j $(getconf _NPROCESSORS_ONLN) && \
    make install && \
    mkdir /var/lock/nginx && \
    rm -rf /tmp/build

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx.conf /etc/nginx/nginx.conf

RUN mkdir /tmp/html

COPY live.html /tmp/html/live.html

EXPOSE 1935 8000
CMD ["nginx", "-g", "daemon off;"]

ARG redis_version
FROM redis:${redis_version}

RUN mkdir /home/redis
RUN chown -R redis:redis /home/redis

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

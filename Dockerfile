# Dockerfile
FROM docker.n8n.io/n8nio/n8n:latest

# 메타 정보
LABEL maintainer="wooxxo"
LABEL description="n8n 뉴스 크롤링 자동화 - 공식 이미지"
LABEL version="1.0"

# 작업 디렉토리
WORKDIR /home/node

# 워크플로우 JSON 복사
COPY news.json /home/node/naver_news.json

# entrypoint 스크립트 복사
COPY entrypoint.sh /home/node/entrypoint.sh

# 권한 설정
USER root
RUN chmod +x /home/node/entrypoint.sh && \
    chown -R node:node /home/node

USER node

# 포트 노출
EXPOSE 5678

ENTRYPOINT ["/home/node/entrypoint.sh"]
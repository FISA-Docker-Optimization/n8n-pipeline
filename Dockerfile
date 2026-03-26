FROM docker.n8n.io/n8nio/n8n:latest

LABEL maintainer="wooxxo"
LABEL description="n8n 뉴스 크롤링 자동화 - 공식 이미지"
LABEL version="1.0"

WORKDIR /home/node

COPY naver-news.json /home/node/naver-news.json

USER root
RUN chown -R node:node /home/node
USER node

EXPOSE 5678

CMD ["n8n", "start"]
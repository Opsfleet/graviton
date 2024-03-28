FROM public.ecr.aws/docker/library/node:lts-bookworm
WORKDIR /app
COPY main.js main.js
USER node
ENTRYPOINT [ "node", "main.js" ]
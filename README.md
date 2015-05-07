# docker-jekyll-site

watcherwebdub:
  build: ""https://github.com/fogies/docker-watcher.git""
  volumes:
    - "/var/run/docker.sock:/var/run/docker.sock"
    - "fig:/fig"
  environment:
    GIT_REPOSITORY: "https://github.com/uwdub/web-dub.git"
    CONTAINER: "webdub"

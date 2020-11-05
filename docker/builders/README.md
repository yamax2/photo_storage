# Builders for some production tools
* jqarmv7 - jq tool for my Zyxel NAS


## unzip 6 for my NAS

copy it from arm debian, host machine:
```bash
sudo apt-get install qemu binfmt-support qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker run -it --rm -v $PWD:/app arm32v7/debian bash
```

container:
```bash
apt update && apt install unzip
ldd /usr/bin/unzip
```

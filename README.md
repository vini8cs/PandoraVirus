# PandoraVirus
Netxflow pipeline to detect and identify RNA virus from public and private data

## Download Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
```

## Remove Docker

```bash
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
```
Para deletar volumes, containers, imagens, etc:

```bash
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

## Setup docker

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
docker login
```


# OpenClaw Pi Image

Builds a Raspberry Pi `linux/arm64` OpenClaw Gateway image from the published npm package and pushes it to GHCR.

The GitHub Action runs daily and publishes:

```text
ghcr.io/YOUR_GITHUB_USER/openclaw-pi:latest
ghcr.io/YOUR_GITHUB_USER/openclaw-pi:<openclaw-version>
```

## Network Binding

The container listens on internal port `18789`. That value is not your public IP; it is only the OpenClaw port inside Docker.

Set the host bind address in `.env` on the Pi:

```sh
OPENCLAW_BIND_ADDRESS=127.0.0.1
OPENCLAW_HOST_PORT=18089
```

Use `127.0.0.1` when Caddy runs on the same host. Use a LAN IP only if another machine on the LAN must connect directly.

## Create The Repo

```sh
gh auth login
cd ~/openclaw-pi-image
git init
git add .
git commit -m "Initial OpenClaw Pi image build"
gh repo create openclaw-pi-image --private --source=. --remote=origin --push
```

After the repo exists, edit `compose.pi.yml` and replace `YOUR_GITHUB_USER` with your GitHub username.

## Pi Deployment

On the Pi, replace the local-build service image with the GHCR image:

```yaml
image: ghcr.io/YOUR_GITHUB_USER/openclaw-pi:latest
```

Keep the existing state volumes:

```yaml
volumes:
  - ./state:/home/node/.openclaw
  - ./config:/home/node/.config/openclaw
```

Then pull and restart:

```sh
cd ~/docker/openclaw-docker
docker compose pull openclaw-gateway
docker compose up -d openclaw-gateway
docker exec openclaw-gateway openclaw --version
curl -IksS https://oc.server.johnnyli.cc/
```

## Daily Pi Pull

Copy `scripts/update-openclaw-pi.sh` to the Pi and run it from cron or a systemd timer after the GitHub Action normally finishes.

Example cron:

```cron
42 4 * * * /home/johnny/docker/openclaw-docker/update-openclaw-pi.sh >> /home/johnny/docker/openclaw-docker/update.log 2>&1
```

Do not delete old version-tagged images immediately. They are useful for rollback if a new OpenClaw release changes auth or config behavior.

# Section 04 — App Setup & Docker on Web Server

> **Goal:** Install Docker on web server, pull Flask app image from DockerHub, and run it with DB credentials passed as environment variables.

---

This project automates Section 04 during `terraform apply`.

## What Terraform Does Automatically

On `lamp-web-server` user data:

- Installs `docker.io`, `mysql-client`, and `curl`
- Enables and starts Docker
- Pulls image from `docker_image` variable
- Runs container with:
  - `--name lamp-app` (default, configurable)
  - `--restart unless-stopped`
  - `-p 5000:5000` (default, configurable)
  - env vars: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `FLASK_ENV`

## Apply

```bash
terraform apply \
  -var="my_ip_cidr=YOUR_PUBLIC_IP/32" \
  -var="mysql_app_password=YOUR_STRONG_PASSWORD" \
  -var="docker_image=yourdockerhubusername/lamp-demo:latest"
```

## Verify on Web Server

SSH to web server:

```bash
ssh -i ./lamp-key.pem ubuntu@<WEB_SERVER_PUBLIC_IP>
```

Check container status:

```bash
sudo docker ps
sudo docker logs lamp-app --tail 100
```

Health check:

```bash
curl http://localhost:5000/health
```

Expected: healthy response and database connectivity status.

## Troubleshooting

```bash
sudo docker ps -a
sudo docker logs -f lamp-app
mysql -h <DB_SERVER_PRIVATE_IP> -u lampuser -p lampdb
curl -v telnet://<DB_SERVER_PRIVATE_IP>:3306
```

If image pull fails, verify image/tag and DockerHub access:

```bash
sudo docker pull yourdockerhubusername/lamp-demo:latest
```

---

> ✅ App is running in Docker! Move on to **[Section 05 → NGINX Setup](./05-nginx-setup.md)**

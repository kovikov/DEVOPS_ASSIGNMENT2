# Section 05 — NGINX Reverse Proxy Setup

> **Goal:** Serve the Flask app on standard HTTP port 80 by placing NGINX in front of the Docker container running on port 5000.

---

This project automates Section 05 during `terraform apply`.

## What Terraform Configures

On `lamp-web-server` user data:

- Installs `nginx`
- Creates reverse-proxy site config at `/etc/nginx/sites-available/lamp-app`
- Enables site with symlink in `/etc/nginx/sites-enabled/lamp-app`
- Removes default site to avoid conflicts
- Validates config with `nginx -t`
- Enables and restarts NGINX service

Proxy flow:

- User -> `http://<WEB_SERVER_PUBLIC_IP>`
- NGINX on port `80`
- Flask container on `127.0.0.1:5000`

## Verify on Web Server

```bash
sudo systemctl status nginx --no-pager
sudo nginx -t
curl http://localhost/
curl http://localhost/health
```

## Verify From Your Machine

```bash
terraform output public_app_url
terraform output public_health_url
curl http://<WEB_SERVER_PUBLIC_IP>/health
```

Expected result:

- `/` returns your app page
- `/health` returns healthy JSON and DB connectivity info

## Common Issues

- If you still see the default NGINX page, the default site may still be enabled.
- If you see `502 Bad Gateway`, check container status:

```bash
sudo docker ps
sudo docker logs lamp-app --tail 100
```

---

> ✅ NGINX is configured! Move on to **[Section 06 → CI/CD Setup](./06-cicd-setup.md)**

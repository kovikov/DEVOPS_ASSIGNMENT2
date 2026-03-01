# DEVOPS_ASSIGNMENT2 — Sections 01, 02, 03, 04, 05, 06 & 07

This Terraform project creates the exact resources required for:

- Section 01: VPC and networking
- Section 02: Security groups, key pair, and EC2 web/db servers
- Section 03: MySQL installation, DB/user creation, and connectivity preparation
- Section 04: Docker install on web server and Flask app container runtime
- Section 05: NGINX reverse proxy from port 80 to Flask app on port 5000
- Section 06: CI/CD pipeline with GitHub Actions (test -> build -> deploy)
- Section 07: End-to-end testing and verification checklist

## Guide Sections

Follow in order:

| Section | File | What You Do |
|---|---|---|
| 01 | [01-vpc-setup.md](./01-vpc-setup.md) | Create VPC, subnets, route tables |
| 02 | [02-ec2-servers.md](./02-ec2-servers.md) | Launch web and DB EC2 servers |
| 03 | [03-mysql-setup.md](./03-mysql-setup.md) | Install and configure MySQL |
| 04 | [04-app-setup.md](./04-app-setup.md) | Run Flask app in Docker |
| 05 | [05-nginx-setup.md](./05-nginx-setup.md) | Configure NGINX reverse proxy |
| 06 | [06-cicd-setup.md](./06-cicd-setup.md) | Configure GitHub Actions CI/CD |
| 07 | [07-testing.md](./07-testing.md) | Validate full stack end-to-end |

## App Files

Repository now includes the expected app/runtime files:

- `app.py`
- `Dockerfile`
- `requirements.txt`
- `.env.example`

## Section 01 Resources

- VPC: `10.0.0.0/16` (`lamp-vpc`)
- Public subnet: `10.0.1.0/24` (`lamp-public-subnet`) with auto-assign public IP **ON**
- Private subnet: `10.0.2.0/24` (`lamp-private-subnet`) with auto-assign public IP **OFF**
- Internet Gateway: `lamp-igw` attached to `lamp-vpc`
- Public route table: `lamp-public-rt` with `0.0.0.0/0 -> lamp-igw`
- Private route table: `lamp-private-rt` with local route only

## Section 02 Resources

- Security group: `lamp-web-sg`
	- Inbound: `80/tcp` from `0.0.0.0/0`
	- Inbound: `443/tcp` from `0.0.0.0/0`
	- Inbound: `22/tcp` from `my_ip_cidr`
- Security group: `lamp-db-sg`
	- Inbound: `3306/tcp` from `lamp-web-sg`
	- Inbound: `22/tcp` from `my_ip_cidr`
- Key pair: `lamp-key` (private key saved as `lamp-key.pem` in project root)
- EC2: `lamp-web-server` in `lamp-public-subnet` with public IP
- EC2: `lamp-db-server` in `lamp-private-subnet` without public IP
- AMI: Ubuntu Server 24.04 LTS (resolved from AWS SSM Parameter Store)
- MySQL: Automatically installed and configured on `lamp-db-server` at first boot via `user_data`
- Database: `lampdb` (default, configurable)
- DB user: `lampuser` allowed from `10.0.1.%` (default, configurable)
- Sample table: `visitors` with one seed row

## Section 04 Resources

- Docker installed automatically on `lamp-web-server` via `user_data`
- Flask app image pulled from DockerHub (`docker_image` variable)
- Container runs as `lamp-app` by default with restart policy `unless-stopped`
- DB credentials passed as runtime environment variables (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `FLASK_ENV`)

## Section 05 Resources

- NGINX installed automatically on `lamp-web-server`
- Reverse proxy config at `/etc/nginx/sites-available/lamp-app`
- Requests to port `80` are proxied to Flask on `127.0.0.1:5000`

## Section 06 Resources

- GitHub Actions workflow at `.github/workflows/deploy.yml`
- Pipeline stages: `test` -> `build` -> `deploy`
- Smoke test script at `.github/scripts/smoke_test.py` for `/` and `/health`
- Docker image push to DockerHub `yourusername/lamp-demo:latest`
- SSH deployment to EC2 web server and container restart with env-file secrets

## Prerequisites

- Terraform `>= 1.5.0`
- AWS CLI configured (`aws configure`) with credentials that can create VPC resources

## Deploy

```bash
terraform init
terraform plan
terraform apply -var="my_ip_cidr=YOUR_PUBLIC_IP/32" -var="mysql_app_password=YOUR_STRONG_PASSWORD" -var="docker_image=yourdockerhubusername/lamp-demo:latest"
```

If you want a different region/AZ:

```bash
terraform apply -var="aws_region=us-east-1" -var="availability_zone=us-east-1a" -var="my_ip_cidr=YOUR_PUBLIC_IP/32" -var="mysql_app_password=YOUR_STRONG_PASSWORD" -var="docker_image=yourdockerhubusername/lamp-demo:latest"
```

Example:

```bash
terraform apply -var="my_ip_cidr=203.0.113.10/32" -var="mysql_app_password='StrongPasswordHere!123'" -var="docker_image=yourdockerhubusername/lamp-demo:latest"
```

## Verify Section 01 (AWS Console)

After apply, verify these resources in AWS Console:

| Resource | Name | Expected State |
|---|---|---|
| VPC | `lamp-vpc` | Available |
| Subnet | `lamp-public-subnet` | Available, auto-assign public IP ON |
| Subnet | `lamp-private-subnet` | Available, auto-assign public IP OFF |
| Internet Gateway | `lamp-igw` | Attached to `lamp-vpc` |
| Route Table | `lamp-public-rt` | Associated with public subnet, has `0.0.0.0/0 -> igw` |
| Route Table | `lamp-private-rt` | Associated with private subnet, local route only |

## Verify Section 02 (AWS Console)

| Server | Subnet | Has Public IP? | Reachable from internet? |
|---|---|---|---|
| `lamp-web-server` | Public | Yes | Yes (ports 80, 443, 22 from your IP) |
| `lamp-db-server` | Private | No | No (by design) |

## SSH Access Checks

Get IPs after apply:

```bash
terraform output web_server_public_ip
terraform output db_server_private_ip
```

SSH to web server:

```bash
ssh -i ./lamp-key.pem ubuntu@<WEB_SERVER_PUBLIC_IP>
```

From your machine, copy key to web server and SSH to DB through web server:

```bash
scp -i ./lamp-key.pem ./lamp-key.pem ubuntu@<WEB_SERVER_PUBLIC_IP>:~/.ssh/
ssh -i ./lamp-key.pem ubuntu@<WEB_SERVER_PUBLIC_IP>
ssh -i ~/.ssh/lamp-key.pem ubuntu@<DB_SERVER_PRIVATE_IP>
```

Verify MySQL on DB server:

```bash
sudo systemctl status mysql --no-pager
mysql --version
sudo ss -tulpn | grep 3306
```

Verify DB/user/table on DB server:

```bash
sudo mysql -e "SHOW DATABASES LIKE '${mysql_database:-lampdb}';"
sudo mysql -e "SELECT user, host FROM mysql.user WHERE user='${mysql_app_user:-lampuser}';"
sudo mysql -e "USE ${mysql_database:-lampdb}; SHOW TABLES; SELECT COUNT(*) AS visitor_rows FROM visitors;"
```

Test DB connection from web server:

```bash
sudo apt update && sudo apt install -y mysql-client
mysql -h <DB_SERVER_PRIVATE_IP> -u lampuser -p lampdb
```

Verify Docker app on web server:

```bash
docker --version
sudo docker ps
sudo docker logs lamp-app --tail 100
curl http://localhost:5000/health
```

Verify NGINX reverse proxy:

```bash
sudo systemctl status nginx --no-pager
sudo nginx -t
curl http://localhost/
curl http://localhost/health
```

Public checks from your machine:

```bash
terraform output public_app_url
terraform output public_health_url
curl http://<WEB_SERVER_PUBLIC_IP>/health
```

## Configure GitHub Secrets and Variable (Section 06)

Repository secrets to create:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `EC2_SSH_KEY` (full content of `lamp-key.pem`)
- `WEB_SERVER_IP` (public IP of web EC2)
- `DB_HOST` (private IP of DB EC2)
- `DB_NAME` (for example `lampdb`)
- `DB_USER` (for example `lampuser`)
- `DB_PASSWORD`

Repository variable to create:

- `EC2_USER=ubuntu`

Trigger pipeline:

```bash
git add .github/workflows/deploy.yml .github/scripts/smoke_test.py
git commit -m "Add CI/CD pipeline"
git push origin main
```

Watch run in GitHub: Actions tab -> `CI-CD Deploy`.

Important SSH note:

- Your current `lamp-web-sg` allows SSH only from `my_ip_cidr`.
- GitHub-hosted runners use dynamic IP ranges; deploy job may fail with SSH timeout/refused.
- For demo only, temporarily allow `0.0.0.0/0` on port 22, run deployment, then lock it down again.

## Section 07 Verification

Run the full test checklist in [07-testing.md](07-testing.md).

Quick helper (run on web server):

```bash
scp -i ./lamp-key.pem ./scripts/verify.sh ubuntu@<WEB_SERVER_PUBLIC_IP>:~/verify.sh
ssh -i ./lamp-key.pem ubuntu@<WEB_SERVER_PUBLIC_IP>
chmod +x ~/verify.sh
DB_HOST=<DB_SERVER_PRIVATE_IP> DB_PASSWORD=<DB_PASSWORD> ~/verify.sh
```

Useful Docker commands:

```bash
sudo docker ps
sudo docker ps -a
sudo docker logs lamp-app
sudo docker logs -f lamp-app
sudo docker stop lamp-app
sudo docker start lamp-app
sudo docker rm lamp-app
sudo docker images
```

If login fails due to host mismatch, recreate user on DB server:

```bash
sudo mysql
DROP USER IF EXISTS 'lampuser'@'localhost';
CREATE USER IF NOT EXISTS 'lampuser'@'10.0.1.%' IDENTIFIED BY 'YOUR_STRONG_PASSWORD';
GRANT ALL PRIVILEGES ON lampdb.* TO 'lampuser'@'10.0.1.%';
FLUSH PRIVILEGES;
EXIT;
```

## Cleanup

To avoid AWS charges:

```bash
terraform destroy
```

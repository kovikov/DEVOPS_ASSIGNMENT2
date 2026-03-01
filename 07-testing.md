# Section 07 — Testing & Verification

> **Goal:** Verify that every part of the stack works end-to-end, from browser to MySQL in private subnet.

---

## Optional Fast Check Script

Use the helper script to run web-server checks quickly before the full checklist:

```bash
# from your local machine
scp -i ./lamp-key.pem ./scripts/verify.sh ubuntu@<WEB_SERVER_PUBLIC_IP>:~/verify.sh

# on web server
chmod +x ~/verify.sh
DB_HOST=<DB_SERVER_PRIVATE_IP> DB_PASSWORD=<DB_PASSWORD> ~/verify.sh
```

The script validates Docker, NGINX, app health, ports, and DB connectivity.

---

## Test 1 — VPC & Subnet Setup

In AWS Console, verify:

- [ ] VPC `lamp-vpc` exists with CIDR `10.0.0.0/16`
- [ ] Public subnet `10.0.1.0/24` has auto-assign public IP enabled
- [ ] Private subnet `10.0.2.0/24` has auto-assign public IP disabled
- [ ] Internet Gateway `lamp-igw` is attached to VPC
- [ ] Public route table has route `0.0.0.0/0 -> lamp-igw`
- [ ] Private route table has no internet route

---

## Test 2 — Security Groups

`lamp-web-sg` should allow:

- Inbound TCP 80 from `0.0.0.0/0`
- Inbound TCP 443 from `0.0.0.0/0`
- Inbound TCP 22 from your IP only
- Outbound all traffic

`lamp-db-sg` should allow:

- Inbound TCP 3306 from `lamp-web-sg` only
- Inbound TCP 22 from your IP only
- Outbound all traffic

---

## Test 3 — SSH Access

```bash
# local machine -> web server
ssh -i ./lamp-key.pem ubuntu@<WEB_SERVER_PUBLIC_IP>

# on web server -> db server
ssh -i ~/.ssh/lamp-key.pem ubuntu@<DB_SERVER_PRIVATE_IP>
```

Expected: Ubuntu login banner on both hosts.

---

## Test 4 — Database Is Running

On DB server:

```bash
sudo systemctl status mysql --no-pager
sudo mysql -e "SHOW DATABASES;"
sudo mysql -e "SELECT user, host FROM mysql.user WHERE user='lampuser';"
```

Expected:

- MySQL service is `active (running)`
- `lampdb` appears in database list
- `lampuser` host is `10.0.1.%`

---

## Test 5 — Public/Private Subnet Communication

On web server:

```bash
mysql -h <DB_SERVER_PRIVATE_IP> -u lampuser -p lampdb
```

Inside mysql shell:

```sql
SHOW TABLES;
EXIT;
```

Expected: `visitors` table is listed.

---

## Test 6 — Docker Container Is Running

On web server:

```bash
sudo docker ps
sudo docker logs lamp-app --tail 100
curl http://localhost:5000/health
```

Expected:

- `lamp-app` is Up
- Logs show app startup (no fatal errors)
- `/health` returns healthy response with DB connectivity

---

## Test 7 — NGINX Is Forwarding Traffic

On web server:

```bash
sudo systemctl status nginx --no-pager
sudo nginx -t
curl http://localhost/health
```

Expected:

- NGINX service is running
- `nginx -t` passes
- `/health` via port 80 returns same response as port 5000

---

## Test 8 — App Is Live in Browser

From your machine:

```bash
terraform output public_app_url
terraform output public_health_url
```

Open the app URL in browser and verify app page loads.

Expected: app page shows running status and database connected state.

---

## Test 9 — CI/CD Pipeline Works

Make a small change in your app code, then push:

```bash
git add app.py
git commit -m "Test deployment via CI/CD"
git push origin main
```

In GitHub Actions, verify workflow `CI-CD Deploy` passes all jobs (`test`, `build`, `deploy`).

Expected: new app change becomes visible at the public URL without manual server changes.

---

## Test 10 — Private Subnet Security Proof

From local machine (not through web server), attempt:

```bash
mysql -h <DB_SERVER_PRIVATE_IP> -u lampuser -p lampdb
```

Expected: timeout/failure. This confirms DB is not internet reachable.

---

## Full Stack Summary

Traffic path should be:

- Internet -> NGINX on web server (port 80)
- NGINX -> Flask container (port 5000)
- Flask -> MySQL on private subnet (port 3306)

Deployment path should be:

- GitHub push -> GitHub Actions -> DockerHub -> EC2 deploy

---

## Cleanup (Avoid AWS Charges)

```bash
terraform destroy
```

If destroying manually in console, terminate both instances first, then delete VPC resources.

---

**Congratulations — you now have a production-style LAMP deployment on AWS with end-to-end verification.**

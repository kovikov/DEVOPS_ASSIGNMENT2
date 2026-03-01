# Section 02 — Launch EC2 Servers

> **Goal:** Launch two EC2 instances and secure traffic with security groups.

---

## Expected Instances

- `lamp-web-server` in `lamp-public-subnet` with public IP
- `lamp-db-server` in `lamp-private-subnet` without public IP

## Expected Security Groups

`lamp-web-sg`:
- Inbound TCP 80 from `0.0.0.0/0`
- Inbound TCP 443 from `0.0.0.0/0`
- Inbound TCP 22 from `my_ip_cidr`

`lamp-db-sg`:
- Inbound TCP 3306 from `lamp-web-sg`
- Inbound TCP 22 from `my_ip_cidr`

## Implemented in This Repo

Provisioned automatically with Terraform in `main.tf`.

## Useful Outputs

```bash
terraform output web_server_public_ip
terraform output db_server_private_ip
```

## SSH Checks

```bash
ssh -i ./lamp-key.pem ubuntu@<WEB_SERVER_PUBLIC_IP>
```

From local machine, copy key then jump to DB via web server:

```bash
scp -i ./lamp-key.pem ./lamp-key.pem ubuntu@<WEB_SERVER_PUBLIC_IP>:~/.ssh/
ssh -i ./lamp-key.pem ubuntu@<WEB_SERVER_PUBLIC_IP>
ssh -i ~/.ssh/lamp-key.pem ubuntu@<DB_SERVER_PRIVATE_IP>
```

## Verification Checklist

- [ ] Web server is in public subnet and reachable via SSH
- [ ] DB server is in private subnet and has no public IP
- [ ] DB server is reachable only via bastion/web server path

---

> ✅ Servers are up! Move on to **[Section 03 → MySQL Setup](./03-mysql-setup.md)**

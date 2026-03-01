# Section 03 — MySQL Setup (Private Subnet)

> **Goal:** Install MySQL on the database server, create database/user, and verify web-to-DB connectivity.

---

This project already automates Section 03 during `terraform apply` on `lamp-db-server`.

## Automated by Terraform

The DB server `user_data` performs:

- `mysql-server` install and service enable/start
- `bind-address = 0.0.0.0` in MySQL config
- basic hardening actions:
  - remove anonymous users
  - remove test database and test privileges
- create database (default: `lampdb`)
- create app user (default: `lampuser`@`10.0.1.%`)
- grant privileges on `lampdb.*`
- create sample table `visitors` and insert one row

## Apply

```bash
terraform apply -var="my_ip_cidr=YOUR_PUBLIC_IP/32" -var="mysql_app_password=YOUR_STRONG_PASSWORD"
```

## Verify on DB Server

SSH via bastion/web server, then run:

```bash
sudo systemctl status mysql --no-pager
mysql --version
sudo ss -tulpn | grep 3306
sudo mysql -e "SHOW DATABASES LIKE 'lampdb';"
sudo mysql -e "SELECT user, host FROM mysql.user WHERE user='lampuser';"
sudo mysql -e "USE lampdb; SHOW TABLES; SELECT COUNT(*) AS visitor_rows FROM visitors;"
```

## Verify from Web Server

On web server:

```bash
sudo apt update && sudo apt install -y mysql-client
mysql -h <DB_SERVER_PRIVATE_IP> -u lampuser -p lampdb
```

If successful, run:

```sql
SHOW TABLES;
SELECT * FROM visitors;
EXIT;
```

## Notes

- Keep `mysql_app_host` aligned with the web subnet CIDR range.
- Current default is `10.0.1.%`, matching `lamp-public-subnet` (`10.0.1.0/24`).

---

> ✅ Database ready! Move on to **[Section 04 → App Setup](./04-app-setup.md)**

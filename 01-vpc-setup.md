# Section 01 — VPC & Network Setup

> **Goal:** Create a private network on AWS with one public subnet (web) and one private subnet (database).

---

## Target Architecture

- VPC: `10.0.0.0/16` (`lamp-vpc`)
- Public subnet: `10.0.1.0/24` (`lamp-public-subnet`) with internet access
- Private subnet: `10.0.2.0/24` (`lamp-private-subnet`) without internet route
- Internet Gateway: `lamp-igw` attached to VPC
- Public route table: `lamp-public-rt` with `0.0.0.0/0 -> lamp-igw`
- Private route table: `lamp-private-rt` local route only

## Implemented in This Repo

Provisioned automatically with Terraform in:

- `main.tf`
- `variables.tf`
- `outputs.tf`

## Deploy

```bash
terraform init
terraform plan \
  -var="my_ip_cidr=YOUR_PUBLIC_IP/32" \
  -var="mysql_app_password=YOUR_STRONG_PASSWORD" \
  -var="docker_image=yourdockerhubusername/lamp-demo:latest"
terraform apply \
  -var="my_ip_cidr=YOUR_PUBLIC_IP/32" \
  -var="mysql_app_password=YOUR_STRONG_PASSWORD" \
  -var="docker_image=yourdockerhubusername/lamp-demo:latest"
```

## Verification Checklist

- [ ] VPC `lamp-vpc` exists with CIDR `10.0.0.0/16`
- [ ] Subnet `lamp-public-subnet` has auto-assign public IP ON
- [ ] Subnet `lamp-private-subnet` has auto-assign public IP OFF
- [ ] Internet Gateway `lamp-igw` is attached to `lamp-vpc`
- [ ] Route table `lamp-public-rt` has `0.0.0.0/0 -> lamp-igw`
- [ ] Route table `lamp-private-rt` has local route only

---

> ✅ Network ready! Move on to **[Section 02 → Launch EC2 Servers](./02-ec2-servers.md)**

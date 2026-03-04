# Section 06 — CI/CD with GitHub Actions

> **Goal:** On every push to `main`, run tests, build/push Docker image, and deploy automatically to web EC2.

---

## Workflow Files

- `.github/workflows/deploy.yml`
- `.github/scripts/smoke_test.py`

## Pipeline Stages

- `test`: Python setup + smoke test for `/` and `/health`
- `build`: DockerHub login + image build/push
- `deploy`: SSH into web server, pull image, recreate container, run health check

## Required GitHub Secrets

Create these in repository settings:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `EC2_SSH_KEY` (full PEM key contents)
- `WEB_SERVER_IP`
- `DB_HOST`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`

## Optional SSM Deploy Mode (No SSH Required)

If you want deployment without opening port 22 to GitHub runners, enable SSM mode.

Additional repository secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` (optional, only for temporary credentials)
- `WEB_SERVER_INSTANCE_ID` (EC2 instance ID, for example `i-0123456789abcdef0`)

Additional repository variables:

- `AWS_REGION` (for example `us-east-1`)
- `USE_SSM_DEPLOY=true`

Notes:

- The web EC2 instance must have IAM permission `AmazonSSMManagedInstanceCore`.
- The current Terraform config now creates/attaches this to the web instance profile.
- Manual workflow runs also expose `use_ssm_deploy` input to toggle SSM mode.

Create repository variable:

- `EC2_USER=ubuntu`

## Fast Setup with GitHub CLI (Optional)

Use the helper script in this repo:

```powershell
pwsh ./scripts/set-github-secrets.ps1 \
   -Repo "kovikov/DEVOPS_ASSIGNMENT2" \
   -DockerhubUsername "YOUR_DOCKERHUB_USERNAME" \
   -DockerhubToken "YOUR_DOCKERHUB_TOKEN" \
   -WebServerIp "YOUR_WEB_SERVER_PUBLIC_IP" \
   -DbHost "YOUR_DB_PRIVATE_IP" \
   -DbPassword "YOUR_DB_PASSWORD" \
   -KeyPath "./lamp-key.pem"
```

Prerequisites:

- Install GitHub CLI (`gh`)
- Authenticate once: `gh auth login`

## Trigger Deployment

```bash
git add .github/workflows/deploy.yml .github/scripts/smoke_test.py
git commit -m "Add CI/CD pipeline"
git push origin main
```

Then open GitHub Actions and inspect `CI-CD Deploy` run.

## What Deploy Job Executes on Web Server

- Docker login to DockerHub
- Pull latest image: `yourusername/lamp-demo:latest`
- Remove existing `lamp-app` container
- Create `/opt/lamp-app.env` from GitHub secrets
- Run container with restart policy
- Validate with `curl http://localhost/health`

## Common Issues

1. SSH connection failure:
   - `lamp-web-sg` currently allows SSH from your IP only.
   - GitHub Actions runners do not use a fixed IP.
   - Demo workaround: temporarily allow port 22 from `0.0.0.0/0`, then restrict again.

2. Deploy succeeds but health check fails:
   - Run on web server:

```bash
sudo docker ps
sudo docker logs lamp-app --tail 100
curl http://localhost/health
```

3. Smoke test fails in CI:
   - Ensure repo root contains `app.py` exporting Flask app as `app`.

---

> ✅ CI/CD is live! Move on to **[Section 07 → Testing Everything](./07-testing.md)**

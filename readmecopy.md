vim pre-commit.sh

#!bin/bash

echo " Running native pre-commit hook..."

if git diff --cached | grep -i "secret"; then 
  echo "Secret detected. Commit blocked"
  exit 1
fi

echo "Commit passed security checks."
exit 0
chmod +x pre-commit
delete script after that

we cannot create scripts for all secrets tokens etc., so we install pre-commit
-------------


pip install pre-commit - goto website and check
create .pre-commit-config.yaml  - vim .pre-commit-config.yaml

repos:
  - repo: https//github.com/gitleaks/gitleaks
    rev: v8.24.2
    hooks:
      - id: gitleaks

pre-commit install

gitleaks detect
pre-commit autodetect

in CICD

name: gitleaks
on:
  pull_request:
  push:
  workflow_dispatch:
  schedule:
    - cron: "0 4 * * *" # run once a day at 4 AM
jobs:
  scan:
    name: gitleaks
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v3
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }} # Only required for Organizations, not personal accounts.




pip install git-filter-repo
git filter-repo --replace-text passwords.txt
git push origin --force --all


CODEOWNERS file 
DEPENDABOT

pip install checkov
checkov --version

create insecure terraform directory

mkdir terraform-checkov-demo
cd terraform-checkov-demo

checkov -d .

install vault 

sudo apt update
sudo apt install -y unzip wget
wget https://releases.hashicorp.com/vault/1.15.5/vault_1.15.5_linux_amd64.zip
unzip vault_1.15.5_linux_amd64.zip
sudo mv vault /usr/local/bin/
vault version

vault server -dev -dev-root-token-id="root" -dev-listen-address="0.0.0.0:8200"



gcloud compute instances create devops-vm --zone=us-central1-a --machine-type=e2-medium --image-family=ubuntu-2404-lts-amd64 --image-project=ubuntu-os-cloud

gcloud init
gcloud auth list
gcloud --version


git add .
git commit -m "added"
git push origin main

gcloud compute ssh devops-vm --zone=me-central1-c
gcloud compute instances stop devops-vm --zone=us-central1-a
gcloud compute instances start devops-vm --zone=us-central1-a
gcloud compute instances delete devops-vm --zone=us-central1-a

gcloud compute ssh vault --zone=us-central1-a
gcloud compute instances stop vault --zone=us-central1-a
gcloud compute instances start vault --zone=us-central1-a
gcloud compute instances delete vault --zone=us-central1-a

gcloud compute ssh temp --zone=us-central1-a
gcloud compute instances stop temp --zone=us-central1-a
gcloud compute instances start temp --zone=us-central1-a
gcloud compute instances delete temp --zone=us-central1-a

gcloud compute ssh kind --zone=us-central1-a
gcloud compute instances stop kind --zone=us-central1-a
gcloud compute instances start kind --zone=us-central1-a
gcloud compute instances delete kind --zone=us-central1-a

gcloud compute instances create vault --zone=us-central1-a --machine-type=e2-standard-4 --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud --boot-disk-size=20GB --enable-nested-virtualization

gcloud compute instances set-machine-type devops-vm --machine-type=e2-standard-2 --zone=us-central1-a


gcloud compute ssh k8s-dev-vm --zone=us-central1-a
gcloud compute instances delete k8s-dev-vm --zone=us-central1-a
gcloud compute instances create k8s-dev-vm --zone=us-central1-a --machine-type=e2-standard-4 --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud --boot-disk-size=50GB --enable-nested-virtualization

gcloud container clusters create my-gke-cluster --zone=us-central1-a --machine-type=e2-medium --num-nodes=1
gcloud container clusters get-credentials my-gke-cluster --zone=us-central1-a


sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | \
sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | \
sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
kubectl version --client
sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
gke-gcloud-auth-plugin --version


gke-gcloud-auth-plugin --version
gcloud container node-pools list --cluster=my-gke-cluster --zone=us-central1-a
gcloud container clusters resize my-gke-cluster --node-pool=default-pool --num-nodes=3 --zone=us-central1-a

disk increase for vm 

gcloud compute instances describe devops-vm --zone=us-central1-a --format="value(disks[0].source)"

gcloud compute disks resize devops-vm --size=20GB --zone=us-central1-a


gcloud container clusters list

gcloud container clusters resize my-gke-cluster --node-pool=default-pool --num-nodes=0 --zone=us-central1-a
gcloud container clusters resize my-gke-cluster --node-pool=default-pool --num-nodes=1 --zone=us-central1-a

to delete
gcloud container clusters delete my-gke-cluster --zone=us-central1-a
gcloud container clusters describe my-gke-cluster--region us-central1-a --format="yaml(meshConfig, workloadIdentityConfig, oidcConfig)"

gcloud container clusters update my-gke-cluster --zone us-central1-a --enable-oidc-issuer
gcloud container clusters describe my-gke-cluster `
    --zone us-central1-a `
    --format="yaml(workloadIdentityConfig.workloadPool, oidcConfig.issuerUri)"

gcloud container clusters describe my-gke-cluster `
>>     --zone us-central1-a `
>>     --format="value(oidcConfig.issuerUri)"  



C:\Users\reddy\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin


gcloud container clusters update my-gke-cluster --location=us-central1-a --enable-oidc-issuer

gcloud container clusters update my-gke-cluster --location=us-central1-a --workload-pool=project-3c4def04-104d-4fe8-a95.svc.id.goog

gcloud container clusters describe my-gke-cluster --location=us-central1-a --format="value(workloadIdentityConfig.workloadPool)"




kubectl port-forward service/prometheus-operated -n monitoring 9090:9090
gcloud compute ssh devops-vm --zone=us-central1-a "--" -L 9090:localhost:9090

kubectl port-forward service/monitoring-grafana -n monitoring 8080:80
gcloud compute ssh devops-vm --zone=us-central1-a "--" -L 8080:localhost:8080

kubectl port-forward service/alertmanager-operated -n monitoring 9093:9093
gcloud compute ssh devops-vm --zone=us-central1-a "--" -L 9093:localhost:9093

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: monitoring-stack-ingress
  namespace: monitoring
  annotations:
    spec.ingressClassName: "gce"
spec:
  rules:
  - http:
      paths:
      # Grafana Access
      - path: /
        pathType: Prefix
        backend:
          service:
            name: monitoring-grafana
            port:
              number: 80
      # Prometheus Access
      - path: /prometheus
        pathType: ImplementationSpecific
        backend:
          service:
            name: monitoring-kube-prometheus-prometheus
            port:
              number: 9090
      # Alertmanager Access
      - path: /alertmanager
        pathType: ImplementationSpecific
        backend:
          service:
            name: monitoring-kube-prometheus-alertmanager
            port:
              number: 9093



helm upgrade monitoring prometheus-community/kube-prometheus-stack -n monitoring --reuse-values --set prometheus.prometheusSpec.routePrefix="/" --set prometheus.prometheusSpec.externalUrl="http://34.107.177.70/prometheus" --set alertmanager.alertmanagerSpec.routePrefix="/" --set alertmanager.alertmanagerSpec.externalUrl="http://34.107.177.70/alertmanager"











aws cli install 

sudo apt update
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install
aws --version


terraform install 

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform
terraform -help




aws eks describe-cluster --name my-eks-cluster --query "cluster.identity.oidc.issuer" --output text





cd ~/runner-repo-a

./config.sh \
  --url https://github.com/nikhil633/devsecops-demo \
  --token AO5DTZ3AGJDTGXS5VUCG75LKXE544

sudo ./svc.sh install
sudo ./svc.sh start




- name: Debug GitHub OIDC
  run: |
    echo "Repository: $GITHUB_REPOSITORY"
    echo "Ref: $GITHUB_REF"
    echo "Event: $GITHUB_EVENT_NAME"

    echo "Requesting OIDC token..."

    TOKEN=$(curl -sSf \
      -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
      "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=sts.amazonaws.com" \
      | python3 -c 'import sys,json; print(json.load(sys.stdin)["value"])')

    echo "$TOKEN" | cut -d '.' -f2 | base64 -d 2>/dev/null | python3 -m json.tool


- name: Debug GitHub OIDC token
  uses: actions/github-script@v7
  with:
    script: |
      const token = await core.getIDToken('sts.amazonaws.com');
      const payload = JSON.parse(
        Buffer.from(token.split('.')[1], 'base64url').toString()
      );
      console.log(JSON.stringify({
        iss: payload.iss,
        aud: payload.aud,
        sub: payload.sub,
        repository: payload.repository,
        ref: payload.ref
      }, null, 2));
















#############################################################################################################################

git branch -m main prod
git push origin prod
git push origin --delete main
git log --oneline
git branch 
git switch prod
git tag -a v1.0.0 -m "Initial tag"
git push origin v1.0.0
git switch -c ppd
git push -u origin ppd
git switch prod
git switch -c dev
git push -u origin dev

git switch feature/dev
git fetch origin
git merge origin/dev

git diff 

sudo apt update
sudo apt install cloud-guest-utils

sudo growpart /dev/sda 1

sudo resize2fs /dev/sda1

df -h /


Jenkins stages ->

1. Git Checkout
2. compile -> mvn compile
3. test -> mvn test -DskipTests=true
4. 









-----------------------------------------------------------------------
Ansible

ssh-copy-id -f "-0 IdentityFile ~/Downloads/ .pem" ubuntu@0.0.0.0
ssh -o ' IdentityFile ~/.pem' 'ubuntu@0.0.0.0'
ssh ubuntu@0.0.0.0

sudo vim /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

sudo passwd ubuntu

ssh-copy-id ubuntu@0.0.0.0

/etc/ansible/hosts

ansible -i inventory.ini -m ping all

ansible -i inventory.ini -m shell -a "apt install openjdk" "all"

installing oracle , packaging database , what type of packages do we install on kubernetes?

ansible -i inventory.ini -m shell -a "sudo ls /etc/" all

ansible builtin commands 
ansible adhoc commands


ansible galaxy login and search roles


ansible-galaxy -h

ls ~/.ansible/roles/

ansible-galaxy role init test

ansible all -i inventory.ini -m ansible.builtin.ping
ansible-playbook -i inventory.ini apache.yml --syntax-check
ansible-playbook -i inventory.ini apache.yml

---------------------------------------------------------------------------------------------------------------------

INTERVIEW

_____________________________________________________________________________________________________

DOCKERFILE .NET 

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

FROM --platform=${BUILDPLATFORM} mcr.microsoft.com/dotnet/sdk:8.0 AS builder
ARG TARGETARCH
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["/src/accounting/", "Accounting/"]
COPY ["/pb/demo.proto", "Accounting/proto/"]
RUN dotnet restore "./Accounting/Accounting.csproj" -r linux-$TARGETARCH
WORKDIR "/src/Accounting"

RUN dotnet build "./Accounting.csproj" -r linux-$TARGETARCH -c $BUILD_CONFIGURATION -o /app/build

# -----------------------------------------------------------------------------

FROM builder AS publish
ARG TARGETARCH
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./Accounting.csproj" -r linux-$TARGETARCH -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# -----------------------------------------------------------------------------

FROM mcr.microsoft.com/dotnet/aspnet:8.0
USER app
WORKDIR /app
COPY --from=publish /app/publish .

USER root
RUN mkdir -p "/var/log/opentelemetry/dotnet"
RUN chown app "/var/log/opentelemetry/dotnet"
RUN chown app "/app/instrument.sh"
USER app

ENTRYPOINT ["./instrument.sh", "dotnet", "Accounting.dll"]


--------------------


# syntax=docker/dockerfile:1

# --------------------------------------------------
# 1. Restore dependencies
# --------------------------------------------------
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS restore
WORKDIR /src

COPY src/Accounting/Accounting.csproj src/Accounting/
COPY pb/demo.proto src/Accounting/proto/

RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet restore src/Accounting/Accounting.csproj

# --------------------------------------------------
# 2. Build and test
# --------------------------------------------------
FROM restore AS test
COPY . .

RUN dotnet test tests/Accounting.Tests/Accounting.Tests.csproj \
    --configuration Release \
    --no-restore

# --------------------------------------------------
# 3. Publish optimized application
# --------------------------------------------------
FROM restore AS publish
COPY src/Accounting/ src/Accounting/
COPY pb/ pb/

RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet publish src/Accounting/Accounting.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish \
    /p:UseAppHost=false \
    /p:DebugType=None \
    /p:DebugSymbols=false

# --------------------------------------------------
# 4. Production runtime
# --------------------------------------------------
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS production
WORKDIR /app

ENV ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_EnableDiagnostics=0

COPY --from=publish --chown=$APP_UID:$APP_UID \
    /app/publish/ ./

USER $APP_UID

EXPOSE 8080

ENTRYPOINT ["dotnet", "Accounting.dll"]


--------------------------------


# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS development

USER root
WORKDIR /workspace

# Development-only diagnostic utilities.
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    wget \
    git \
    procps \
    iproute2 \
    iputils-ping \
    dnsutils \
    netcat-openbsd \
    tcpdump \
    strace \
    gdb \
    lsof \
    jq \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Restore dependencies separately for better caching.
COPY src/Accounting/Accounting.csproj src/Accounting/
COPY pb/demo.proto src/Accounting/proto/

RUN dotnet restore src/Accounting/Accounting.csproj

# Create a non-root development account.
RUN useradd --create-home --shell /bin/bash developer \
    && chown -R developer:developer /workspace

USER developer
WORKDIR /workspace/src/Accounting

EXPOSE 8080

ENV ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_USE_POLLING_FILE_WATCHER=1

# Source code will be mounted into this directory.
ENTRYPOINT ["dotnet", "watch", "run", \
    "--project", "Accounting.csproj", \
    "--urls", "http://0.0.0.0:8080"]



-------------------------------


JAVA GRADLE 

FROM eclipse-temurin:21-jdk AS builder

WORKDIR /usr/src/app/

COPY gradlew* settings.gradle* build.gradle .
COPY ./gradle ./gradle

RUN chmod +x ./gradlew
RUN ./gradlew
RUN ./gradlew downloadRepos

COPY . .
COPY ./pb ./proto
RUN chmod +x ./gradlew
RUN ./gradlew installDist -PprotoSourceDir=./proto

#####################################################

FROM eclipse-temurin:21-jre

WORKDIR /usr/src/app/

COPY --from=builder /usr/src/app/ ./

ENV AD_PORT 9099

ENTRYPOINT ["./build/install/opentelemetry-demo-ad/bin/Ad"]



----------------------


# syntax=docker/dockerfile:1

# ==========================================================
# 1. BUILDER: Compile and package the Java application
# ==========================================================
FROM eclipse-temurin:21-jdk AS builder

WORKDIR /usr/src/app

# Copy build configuration first for better cache reuse
COPY gradlew settings.gradle* build.gradle* ./
COPY gradle/ ./gradle/

RUN chmod +x ./gradlew

# Retain the project's existing Gradle setup tasks
RUN ./gradlew
RUN ./gradlew downloadRepos

# Copy application source and protocol definitions
COPY . .
COPY ./pb ./proto

# Build the installable application distribution
RUN ./gradlew installDist -PprotoSourceDir=./proto


# ==========================================================
# 2. DEV: JDK + application + debugging utilities
# ==========================================================
FROM eclipse-temurin:21-jdk AS dev

WORKDIR /opt/app

# Install common Linux debugging and troubleshooting tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        wget \
        procps \
        iproute2 \
        iputils-ping \
        dnsutils \
        netcat-openbsd \
        lsof \
        strace \
        less \
        vim-tiny \
    && rm -rf /var/lib/apt/lists/*

# Copy only the packaged application, not its source or Gradle cache
COPY --from=builder \
    /usr/src/app/build/install/opentelemetry-demo-ad/ \
    /opt/app/

ENV AD_PORT=9099

EXPOSE 9099

ENTRYPOINT ["/opt/app/bin/Ad"]


# ==========================================================
# 3. RUNTIME: Clean production image
# ==========================================================
FROM eclipse-temurin:21-jre AS runtime

WORKDIR /opt/app

# Copy only the application distribution
COPY --from=builder \
    /usr/src/app/build/install/opentelemetry-demo-ad/ \
    /opt/app/

# Run as a non-root user
USER 10001:10001

ENV AD_PORT=9099

EXPOSE 9099

ENTRYPOINT ["/opt/app/bin/Ad"]


--------------------------------------------------------------------------------


AWS        	                    Azure equivalent
AWS IAM	                        Microsoft Entra ID + Azure RBAC
IAM User	                      Entra ID User
IAM Role	                      Managed Identity or Service Principal, depending on scenario
IAM Policy	                    Azure RBAC Role
EC2 Instance Role	              VM Managed Identity
IRSA (EKS)	                    Microsoft Entra Workload ID (AKS)
GitHub Actions OIDC + IAM Role	GitHub Actions OIDC + Federated Identity Credential



-------------------------------------------------------------------------------------------------------
NODEJS

FROM node:26-bookworm-slim AS dependencies

RUN apt-get update &&\
    apt-get install -y --no-install-recommends curl tini && \
    rm -rf var/lib/apt/lists/*

WORKDIR /user/local/app

RUN npm install -g nodemon

COPY package*.json ./

RUN npm ci &&\
    npm cache clean --force && \
    mv /user/local/app/node_modules /node_modules

COPY . .

ENV PORT=80
EXPOSE 80

ENTRYPOINT["usr/bin/tini","--"]
CMD["node","server.js"]

----------------------------------------------------------------------

FROM node:26-bookworm-slim AS dependencies

WORKDIR /app

COPY package*.json ./

RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

FROM node:26-bookworm-slim AS production

ENV NODE_ENV=production \
    PORT=8000

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tini \
        curl && \
    rm -rf /var/lib/apt/lists/*

COPY --from=dependencies --chown=node:node \
    /app/node_modules ./node_modules

COPY --chown=node:node package.json ./
COPY --chown=node:node server.js ./
COPY --chown=node:node src ./src

USER node

EXPOSE 8000

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["node", "server.js"]

-------------------------------------------------------------------------------------

--------------------------------------------PYTHON SCRIPTS---------------------------


github pull requests basic script



----------------------------------------------------



AWS -> Elastic Beanstalk -> aws_elastic_beanstalk_application + aws_elastic_beanstalk_application_version +  aws_elastic_beanstalk_environment
Azure -> Azure App service -> azurerm_service_plan + azurerm_linux_web_app + azurerm_linux_web_app_slot + azurerm_web_app_active_slot

azure Function -> azurerm_storage_account + azurerm_log_analytics_workspace + azurerm_application_insights  + azurerm_service_plan + azurerm_linux_function_app

AWS lambda -> aws_caller_identity + aws_s3_bucket + aws_s3_bucket_versioning + aws_s3_bucket_server_side_encryption_configuration + aws_s3_bucket_public_access_block + archive_file + aws_s3_object + aws_cloudwatch_log_group + aws_lambda_function + aws_lambda_function_url 


AWS -> ECS Fargate -> aws_ecs_cluster + aws_ecs_task_defination + aws_ecs_service + aws_appautoscaling_target + aws_appautoscaling_policy 
Azure -> Azure container apps -> azurerm_container_app_environment + azurerm_container_app



Azure App service container apps -> azurerm_log_analytics_workspace +  azurerm_container_app_environment + azurerm_container_app
AWS -> AWS App runner -> aws_apprunner_service

-----------------------------------------------------------------------------------------------

Azure -> azuread_domains + azuread_user + azuread_group + azuread_group_member 
AWS -> aws_ssoadmin_instances + aws_identitystore_user + aws_identitystore_group + aws_identitystore_group_membership+ aws_ssoadmin_account_assignment + aws_ssoadmin_permission_set + aws_ssoadmin_managed_policy_attachment 






prometheus, grafana, jaeger, open telemetry, PagerDuty, ELS Stack, FLuentBit ,Node exporter, Kube state metrics , Alertmanager , slack, Elasticsearch, Kibana



AWS -> AWS CloudWatch , AWS X-Ray ,





Connect an Azure VNet to an AWS VPC.
Allow Azure VMs to communicate with AWS EC2 instances.
Connect Azure AKS to AWS EKS.
Allow applications in Azure to access databases in AWS.
Connect Azure and AWS through VPN or private network connectivity.
Synchronize identity and authentication between the two clouds.
Transfer files and data between Azure Storage and AWS S3.



resource "aws_vpc_endpoint" "secrets_manager" {

  vpc_id = aws_vpc.main.id

  service_name = "com.amazonaws.ap-south-1.secretsmanager"

  vpc_endpoint_type = "Interface"

  subnet_ids = aws_subnet.private[*].id

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  private_dns_enabled = true
}



resource "aws_vpc_security_group_ingress_rule" "secrets_https" {

  security_group_id = aws_security_group.vpc_endpoint.id

  referenced_security_group_id = aws_security_group.eks_nodes.id

  from_port = 443
  to_port   = 443

  ip_protocol = "tcp"
}




aws eks get-token --cluster-name YOUR_CLUSTER_NAME --region us-east-1

aws eks update-kubeconfig --region us-east-1 --name YOUR_CLUSTER_NAME

kubectl config get-contexts

kubectl config current-conetxts


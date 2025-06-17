# Looper AWS 3-Tier Infrastructure

이 Terraform 프로젝트는 AWS에서 Looper 애플리케이션을 위한 완전한 3-tier 인프라를 구축합니다.

## 🏗️ 아키텍처

```
Internet Gateway
    ↓
Application Load Balancer (Public Subnets)
    ↓
Auto Scaling Group (Private Subnets)
    ↓
RDS PostgreSQL (Private Subnets)
```

## 📦 포함된 리소스

### 네트워킹
- **VPC**: 192.168.0.0/16
- **서브넷**:
  - Public Subnets: 192.168.10.0/24, 192.168.20.0/24
  - NAT Subnets: 192.168.110.0/24, 192.168.120.0/24  
  - Private Subnets: 192.168.210.0/24, 192.168.220.0/24
- **NAT Gateways**: 고가용성을 위한 Multi-AZ 구성
- **라우팅 테이블**: 적절한 트래픽 라우팅

### 컴퓨팅
- **Auto Scaling Group**: 트래픽에 따른 자동 스케일링
- **Launch Template**: 표준화된 인스턴스 구성
- **Application Load Balancer**: SSL 종료 및 트래픽 분산

### 데이터베이스
- **RDS PostgreSQL**: Multi-AZ 구성 (prod)
- **DB Subnet Group**: 고가용성 데이터베이스 배치
- **백업**: 자동 백업 및 포인트 인 타임 복구

### 보안
- **Security Groups**: 최소 권한 원칙
- **WAF**: OWASP Top 10 보호
- **SSL/TLS**: Let's Encrypt via ACM
- **IAM Roles**: Session Manager 접근

### DNS & SSL
- **Route53**: DNS 관리
- **ACM**: 무료 SSL 인증서
- **HTTPS 리다이렉션**: 모든 HTTP → HTTPS

### 모니터링
- **CloudWatch**: 메트릭 및 로그
- **Auto Scaling Policies**: CPU 기반 스케일링
- **Health Checks**: 애플리케이션 상태 모니터링

## 🚀 사용 방법

### 1. 사전 준비

```bash
# AWS CLI 설정
aws configure

# Terraform 설치 확인
terraform --version
```

### 2. 초기화

```bash
cd web-3tier-terraform
terraform init
```

### 3. 배포

#### Option 1: 완전한 DNS 관리 (Google Domains → Route53 이전)

**Production 환경**
```bash
# 계획 확인
terraform plan -var-file="prod.tfvars"

# 배포 실행
terraform apply -var-file="prod.tfvars"

# 배포 완료 후 Google Domains에서 NS 레코드 변경 필요:
# Google Domains → Route53 NS 레코드로 변경
```

**Staging 환경**
```bash
# Production 배포 완료 후
terraform plan -var-file="stage.tfvars"
terraform apply -var-file="stage.tfvars"
```

#### Option 2: 인프라만 구축 (DNS 수동 관리)

```bash
# DNS 관리 없이 인프라만 구축
terraform plan -var-file="infra-only.tfvars"
terraform apply -var-file="infra-only.tfvars"

# 배포 완료 후 수동으로 DNS 설정:
# 1. ALB DNS 이름 확인: terraform output alb_dns_name
# 2. Google Domains에서 A 레코드 수정:
#    - looper.my → ALB DNS (또는 CNAME)
#    - dev.looper.my → ALB DNS (또는 CNAME)
```

### 4. 리소스 정리

```bash
# Staging 환경 삭제
terraform destroy -var-file="stage.tfvars"

# Production 환경 삭제
terraform destroy -var-file="prod.tfvars"
```

## 📋 환경별 구성

### Production (looper.my) - `prod.tfvars`
- **인스턴스**: t3.small
- **Auto Scaling**: 2-6대
- **RDS**: db.t3.small, Multi-AZ
- **DNS**: Route53 새 Hosted Zone 생성 + DNS 관리
- **SSL**: ACM 무료 인증서 + HTTPS 리다이렉션

### Staging (dev.looper.my) - `stage.tfvars`
- **인스턴스**: t3.micro
- **Auto Scaling**: 1-3대  
- **RDS**: db.t3.micro, Single-AZ
- **DNS**: 기존 Route53 Hosted Zone 사용
- **SSL**: ACM 무료 인증서 + HTTPS 리다이렉션

### Infrastructure Only - `infra-only.tfvars`
- **인스턴스**: t3.small
- **Auto Scaling**: 2-6대
- **RDS**: db.t3.small, Multi-AZ
- **DNS**: 관리 안함 (수동 설정 필요)
- **SSL**: 없음 (HTTP만 사용)

## 🔄 DNS 마이그레이션 가이드

### 현재 상황 (Google Domains)
```
looper.my A 레코드 → 34.54.115.33 (GCP)
dev.looper.my A 레코드 → 34.149.194.181 (GCP)
NS 레코드 → ns-cloud-a1.googledomains.com
MX 레코드 → improvmx (이메일)
```

### Route53 완전 이전 (권장)
1. **Terraform 배포**: `terraform apply -var-file="prod.tfvars"`
2. **NS 레코드 확인**: Route53 Hosted Zone의 NS 레코드 복사
3. **Google Domains 설정**: Name Servers를 Route53 NS로 변경
4. **검증**: `dig looper.my` 명령어로 확인
5. **이메일 테스트**: improvmx 이메일 정상 작동 확인

### 수동 DNS 관리 (간단)
1. **Terraform 배포**: `terraform apply -var-file="infra-only.tfvars"`
2. **ALB DNS 확인**: `terraform output alb_dns_name`
3. **Google Domains**: A 레코드만 ALB DNS로 변경
4. **기존 설정 유지**: MX, SPF 등 기존 레코드 그대로 유지

## 🔐 접속 방법

### Session Manager (권장)
```bash
# 인스턴스 목록 확인
aws ec2 describe-instances --region ap-northeast-2

# Session Manager로 접속
aws ssm start-session --target i-1234567890abcdef0 --region ap-northeast-2
```

### 직접 연결
1. AWS 콘솔 → EC2 → 인스턴스 선택
2. "연결" → "Session Manager" → "연결"

## 📊 모니터링

### CloudWatch 대시보드
- CPU 사용률
- 메모리 사용률
- 네트워크 트래픽
- 애플리케이션 로그

### 로그 위치
- **Nginx Access**: `/aws/ec2/looper/{env}/nginx/access`
- **Nginx Error**: `/aws/ec2/looper/{env}/nginx/error`
- **Startup Script**: `/aws/ec2/looper/{env}/startup`

## 🔧 일반적인 작업

### 애플리케이션 배포
```bash
# 인스턴스에 접속 후
cd /opt/looper
sudo /opt/looper/scripts/deploy.sh
```

### 서비스 상태 확인
```bash
sudo /opt/looper/scripts/status.sh
```

### 로그 확인
```bash
sudo /opt/looper/scripts/logs.sh [service-name]
```

## ⚠️ 주의사항

### 비용 최적화
- **NAT Gateway**: 월 ~$45/개 (Multi-AZ)
- **RDS**: Multi-AZ는 prod만 사용
- **불필요한 리소스**: 테스트 후 즉시 삭제

### 보안
- **DB 패스워드**: 프로덕션에서는 반드시 변경
- **Security Group**: 필요한 포트만 개방
- **WAF 룰**: 애플리케이션에 맞게 조정

### 백업
- **RDS**: 자동 백업 7일 보관
- **인프라**: Terraform state 백업 필요

## 🤝 문제 해결

### SSL 인증서 검증 실패
```bash
# DNS 레코드 확인
dig TXT _acme-challenge.looper.my

# Route53에서 수동 검증 레코드 추가
```

### Auto Scaling 동작 안함
```bash
# CloudWatch 알람 상태 확인
aws cloudwatch describe-alarms --region ap-northeast-2

# 인스턴스 헬스 체크 확인
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

### 데이터베이스 연결 실패
```bash
# Security Group 확인
aws ec2 describe-security-groups --group-ids <sg-id>

# RDS 상태 확인
aws rds describe-db-instances --region ap-northeast-2
```

## 📞 지원

문제가 발생하면 다음을 확인해주세요:
1. AWS CLI 권한
2. Terraform 버전 호환성
3. 변수 파일 설정
4. 리전 설정

## 📝 변수 커스터마이징

필요에 따라 `prod.tfvars` 또는 `stage.tfvars`를 수정하여 리소스 스펙을 조정할 수 있습니다.

**주요 변수:**
- `instance_type`: EC2 인스턴스 타입
- `min_size`, `max_size`: Auto Scaling 범위
- `db_instance_class`: RDS 인스턴스 클래스
- `domain_name`: 도메인 이름

# PIDS Option-3 Architecture - Microservices with Dedicated EC2 Instances

## Architecture Overview

This microservices architecture separates each application into its own dedicated EC2 instance while maintaining the existing RDS database setup, providing maximum isolation, scalability, and independent deployment capabilities.

## Dedicated Infrastructure Components

### Compute Resources (EC2 Instances)

| Server Name | Instance Type | CPU Cores | RAM (GB) | Operating System | Application Hosted | S3 Mount Point | EFS Mount Point |
|-------------|---------------|-----------|----------|------------------|-------------------|----------------|-----------------|
| EC2: PIDS-MAIN | t3a.xlarge | 4 | 16 | Ubuntu 24.04 | PIDS (Main) - YII Framework | /mnt/pids-files | /mnt/sessions |
| EC2: PIDS-PJD | t3a.medium | 2 | 4 | Ubuntu 24.04 | PJD (Subdomain) - YII Framework | /mnt/pjd-files | /mnt/sessions |
| EC2: PIDS-SERPP | t3a.small | 2 | 2 | Ubuntu 24.04 | SERPP (Subdomain) - YII Framework | /mnt/serpp-files | /mnt/sessions |
| EC2: PIDS-HEFP | t3a.small | 2 | 2 | Ubuntu 24.04 | HEFP (Subdomain) - YII Framework + Power BI | /mnt/hefp-files | /mnt/sessions |

### Database Resources (RDS) - Existing Setup

| Database Name | Instance Type | Engine Version | Storage (GB) | Monitoring | Backup |
|---------------|---------------|----------------|--------------|------------|---------|
| RDS: pids | db.m5.large | MySQL 8.0.33 | 200 | CloudWatch Alarms | RDS Automated Backup |
| RDS: serpp | db.m5.large | MySQL 8.0.42 | 200 | CloudWatch Alarms | RDS Automated Backup |

### Storage Architecture (S3 + EFS)

| Bucket Name | Purpose | Lifecycle Policy | Access Pattern |
|-------------|---------|------------------|----------------|
| pids-main-files | PIDS main PDF storage | Intelligent Tiering | High access |
| pids-pjd-files | PJD document storage | Intelligent Tiering | Medium access |
| pids-serpp-files | SERPP PDF archive | Intelligent Tiering | Mixed access |
| pids-hefp-files | HEFP visualization files | Intelligent Tiering | Low access |
| pids-database-exports | DB export storage (from EC2) | IA → Glacier → Deep Archive | Backup retention |
| pids-application-backups | App backup storage (from EC2) | IA → Glacier | Recovery purposes |

| EFS File System | Purpose | Performance Mode | Throughput Mode |
|-----------------|---------|------------------|-----------------|
| pids-sessions-efs | Shared session storage for ASG | General Purpose | Provisioned |

## Microservices Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet Users                            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                AWS Global Accelerator                           │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│              Application Load Balancer                          │
│                 (Host-based Routing)                            │
└─────┬─────────┬─────────┬─────────┬─────────────────────────────┘
      │         │         │         │
┌─────▼───┐ ┌───▼───┐ ┌───▼───┐ ┌───▼───┐
│TG:PIDS  │ │TG:PJD │ │TG:    │ │TG:    │
│MAIN     │ │       │ │SERPP  │ │HEFP   │
└─────┬───┘ └───┬───┘ └───┬───┘ └───┬───┘
      │         │         │         │
┌─────▼───┐ ┌───▼───┐ ┌───▼───┐ ┌───▼───┐
│EC2:PIDS │ │EC2:PJD│ │EC2:   │ │EC2:   │
│MAIN     │ │       │ │SERPP  │ │HEFP   │
│t3a.xlarge│ │t3a.med│ │t3a.sm │ │t3a.sm │
│         │ │       │ │       │ │       │
│PIDS Main│ │PJD    │ │SERPP  │ │HEFP   │
│YII      │ │YII    │ │YII    │ │YII+BI │
└─────┬───┘ └───┬───┘ └───┬───┘ └───┬───┘
      │         │         │         │
      │S3 Mount │S3 Mount │S3 Mount │S3 Mount
      │         │         │         │
┌─────▼───┐ ┌───▼───┐ ┌───▼───┐ ┌───▼───┐
│S3:pids- │ │S3:pids│ │S3:pids│ │S3:pids│
│main-    │ │-pjd-  │ │-serpp-│ │-hefp- │
│files    │ │files  │ │files  │ │files  │
└─────────┘ └───────┘ └───────┘ └───────┘
      │         │         │         │
      └─────────┼─────────┼─────────┘
                │         │
                │         │
        ┌───────▼───┐ ┌───▼───────┐
        │RDS: pids  │ │RDS: serpp │
        │db.m5.     │ │db.m5.     │
        │large      │ │large      │
        │MySQL 8.0.33│ │MySQL 8.0.42│
        │200GB      │ │200GB      │
        │+ Alarms   │ │+ Alarms   │
        └───────────┘ └───────────┘
                │         │
                │EC2 Export Cron Jobs
                │
        ┌───────▼─────────▼───────┐
        │S3: pids-database-exports│
        │S3: pids-application-    │
        │    backups              │
        └─────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    EFS: pids-sessions-efs                       │
│                   (Shared Session Storage)                      │
│    ┌─────────────┬─────────────┬─────────────┬─────────────┐    │
│    │/mnt/sessions│/mnt/sessions│/mnt/sessions│/mnt/sessions│    │
│    │PIDS-MAIN    │PJD          │SERPP        │HEFP         │    │
│    └─────────────┴─────────────┴─────────────┴─────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Application Load Balancer Configuration

### Host-Based Routing (Implemented)

```yaml
# Separate Target Groups per EC2 Instance
Target Groups:
  - pids-main-tg:
      targets: [EC2: PIDS-MAIN]
      health_check: /health
      
  - pids-pjd-tg:
      targets: [EC2: PIDS-PJD]
      health_check: /health
      
  - pids-serpp-tg:
      targets: [EC2: PIDS-SERPP]
      health_check: /health
      
  - pids-hefp-tg:
      targets: [EC2: PIDS-HEFP]
      health_check: /health

Host-Based Routing Rules:
  - Host Header: pids.gov.ph → pids-main-tg
  - Host Header: pjd.pids.gov.ph → pids-pjd-tg
  - Host Header: serpp.pids.gov.ph → pids-serpp-tg
  - Host Header: hefp.pids.gov.ph → pids-hefp-tg
```

### Application Configuration (Per Instance)

Each EC2 instance runs its dedicated application:

```apache
# PIDS-MAIN Instance (only PIDS Main)
<VirtualHost *:80>
    ServerName pids.gov.ph
    DocumentRoot /var/www/pids-main
</VirtualHost>

# PIDS-PJD Instance (only PJD)
<VirtualHost *:80>
    ServerName pjd.pids.gov.ph
    DocumentRoot /var/www/pids-pjd
</VirtualHost>

# PIDS-SERPP Instance (only SERPP)
<VirtualHost *:80>
    ServerName serpp.pids.gov.ph
    DocumentRoot /var/www/pids-serpp
</VirtualHost>

# PIDS-HEFP Instance (only HEFP)
<VirtualHost *:80>
    ServerName hefp.pids.gov.ph
    DocumentRoot /var/www/pids-hefp
</VirtualHost>
```

## Instance Sizing Strategy

### Resource Allocation by Application Load

| Application | Expected Load | Instance Type | Justification |
|-------------|---------------|---------------|---------------|
| PIDS Main | 40k-50k concurrent | t3a.xlarge | High traffic, primary application |
| PJD | 5k-10k concurrent | t3a.medium | Medium traffic, new application |
| SERPP | 150 concurrent | t3a.small | Low traffic, file-heavy operations |
| HEFP | Variable load | t3a.small | Low traffic, visualization focused |

### Database Connection Distribution

| Application | Database | Connection Pool | Notes |
|-------------|----------|----------------|-------|
| PIDS Main | RDS: pids | 80 connections | Primary data operations |
| PJD | RDS: pids | 20 connections | Shared database, lighter load |
| SERPP | RDS: serpp | 30 connections | Dedicated database |
| HEFP | RDS: serpp | 10 connections | Shared database, minimal operations |

## Auto Scaling Configuration

### Auto Scaling Groups

#### PIDS Main (High Priority)
```yaml
Auto Scaling Group: pids-main-asg
  Min Size: 1
  Max Size: 3
  Desired: 1
  Target Tracking:
    - CPU Utilization: 70%
    - Request Count: 1000 per target
  Scale Out: +1 instance when CPU > 70% for 5 minutes
  Scale In: -1 instance when CPU < 30% for 10 minutes
```

#### PJD (Medium Priority)
```yaml
Auto Scaling Group: pids-pjd-asg
  Min Size: 1
  Max Size: 2
  Desired: 1
  Target Tracking:
    - CPU Utilization: 75%
  Scale Out: +1 instance when CPU > 75% for 5 minutes
```

#### SERPP & HEFP (Low Priority)
```yaml
Auto Scaling Groups: pids-serpp-asg, pids-hefp-asg
  Min Size: 1
  Max Size: 1
  Desired: 1
  # No auto-scaling due to low traffic
```

## Database Monitoring and Alarms

### CloudWatch Alarms Configuration

#### PIDS Database (db.m5.large)
| Metric | Threshold | Action |
|--------|-----------|--------|
| CPU Utilization | > 75% for 5 minutes | SNS Alert + Scale consideration |
| Database Connections | > 75% of max | SNS Alert |
| Free Storage Space | < 20GB | SNS Alert + Storage expansion |
| Read/Write Latency | > 250ms | SNS Alert |

#### SERPP Database (db.m5.large)
| Metric | Threshold | Action |
|--------|-----------|--------|
| CPU Utilization | > 75% for 5 minutes | SNS Alert |
| Database Connections | > 75% of max | SNS Alert |
| Free Storage Space | < 20GB | SNS Alert |
| Read/Write Latency | > 250ms | SNS Alert |

## Backup Strategy

### RDS Automated Backups
- **Backup Retention**: 7 days (configurable up to 35 days)
- **Backup Window**: 2:00-3:00 AM (low traffic period)
- **Point-in-Time Recovery**: Available within retention period
- **Cross-Region Backup**: Optional for disaster recovery

### EC2-Based Backup Cron Jobs

#### Database Export Backups (Daily) - From PIDS-MAIN
```bash
# PIDS Database Export - 4:00 AM daily (after RDS backup)
0 4 * * * /usr/local/bin/mysql-export-pids.sh

# SERPP Database Export - 5:00 AM daily
0 5 * * * /usr/local/bin/mysql-export-serpp.sh
```

#### Application Backups (Weekly) - From Each Instance
```bash
# PIDS Main backup - Sunday 1:00 AM
0 1 * * 0 /usr/local/bin/app-backup-pids-main.sh

# PJD backup - Sunday 1:30 AM
30 1 * * 0 /usr/local/bin/app-backup-pjd.sh

# SERPP backup - Sunday 2:00 AM
0 2 * * 0 /usr/local/bin/app-backup-serpp.sh

# HEFP backup - Sunday 2:30 AM
30 2 * * 0 /usr/local/bin/app-backup-hefp.sh
```

#### S3 Sync for Files (Hourly) - From Each Instance
```bash
# PIDS Main files sync - Every hour
0 * * * * aws s3 sync /var/www/pids/uploads/ s3://pids-main-files/ --delete

# PJD files sync - Every hour at :15
15 * * * * aws s3 sync /var/www/pjd/uploads/ s3://pids-pjd-files/ --delete

# SERPP files sync - Every hour at :30
30 * * * * aws s3 sync /var/www/serpp/files/ s3://pids-serpp-files/ --delete

# HEFP files sync - Every hour at :45
45 * * * * aws s3 sync /var/www/hefp/files/ s3://pids-hefp-files/ --delete
```

## EFS Integration for Auto Scaling

### Shared Session Storage

#### EFS Configuration
```yaml
EFS File System: pids-sessions-efs
  Performance Mode: General Purpose
  Throughput Mode: Provisioned (100 MiB/s)
  Encryption: Enabled (at rest and in transit)
  Backup: Enabled (daily)
  
Mount Targets:
  - Availability Zone A: subnet-xxx
  - Availability Zone B: subnet-yyy
  - Availability Zone C: subnet-zzz
```

#### EFS Mount Points (All Instances)
```bash
# /etc/fstab entries for all EC2 instances
pids-sessions-efs.efs.region.amazonaws.com:/ /mnt/sessions efs defaults,_netdev,tls 0 0

# Mount commands for immediate mounting
sudo mkdir -p /mnt/sessions
sudo mount -t efs pids-sessions-efs.efs.region.amazonaws.com:/ /mnt/sessions

# Set proper permissions for web applications
sudo chown -R www-data:www-data /mnt/sessions
sudo chmod 755 /mnt/sessions
```

#### Installation Requirements (All EC2 Instances)
```bash
# Install EFS utilities on Ubuntu 24.04
sudo apt-get update
sudo apt-get install -y amazon-efs-utils

# Alternative using NFS client
sudo apt-get install -y nfs-common
```

#### YII Framework Session Configuration
```php
// config/web.php - Session configuration for all applications
'session' => [
    'class' => 'yii\web\Session',
    'savePath' => '/mnt/sessions',
    'cookieParams' => [
        'lifetime' => 3600,
        'httpOnly' => true,
        'secure' => true,
    ],
],
```

### Auto Scaling Benefits with EFS

#### Session Persistence
- **Shared Sessions**: Users maintain sessions across scaled instances
- **Load Balancer Flexibility**: No need for sticky sessions
- **Seamless Scaling**: New instances immediately access existing sessions
- **High Availability**: Sessions survive instance failures

#### Performance Considerations
- **Low Latency**: EFS General Purpose mode for session access
- **Concurrent Access**: Multiple instances can read/write sessions
- **Automatic Scaling**: EFS scales automatically with demand

## S3 Integration

### S3FS Mount Configuration

#### Per Instance Mount Points
```bash
# PIDS Main - /etc/fstab
s3fs#pids-main-files /mnt/pids-files fuse _netdev,allow_other,iam_role=auto 0 0

# PJD - /etc/fstab
s3fs#pids-pjd-files /mnt/pjd-files fuse _netdev,allow_other,iam_role=auto 0 0

# SERPP - /etc/fstab
s3fs#pids-serpp-files /mnt/serpp-files fuse _netdev,allow_other,iam_role=auto 0 0

# HEFP - /etc/fstab
s3fs#pids-hefp-files /mnt/hefp-files fuse _netdev,allow_other,iam_role=auto 0 0
```

## Cost Analysis

### Infrastructure Cost Comparison

| Component | Current (2 instances) | Option-3 (4 instances) | Change |
|-----------|----------------------|------------------------|--------|
| EC2 | 2x t3a.xlarge | 1x t3a.xlarge + 1x t3a.medium + 2x t3a.small | +15% |
| RDS | 2x db.m5.xlarge | 2x db.m5.large | -25% |
| Storage | 400GB total | 400GB distributed | 0% |
| EFS | None | 1x EFS (100 MiB/s provisioned) | +5% |
| Load Balancer | 1x ALB | 1x ALB (simple routing) | 0% |
| Auto Scaling | None | 4x ASG | +10% |

### Total Estimated Cost Change: +5-10%

## Microservices Benefits

### Advantages
- **Independent Scaling**: Each application scales based on its own demand
- **Fault Isolation**: Failure in one service doesn't affect others
- **Independent Deployments**: Deploy updates per application without downtime
- **Technology Flexibility**: Different configurations per service
- **Resource Optimization**: Right-sized instances per workload
- **Development Team Isolation**: Teams can work independently
- **Session Persistence**: EFS ensures sessions survive scaling events
- **Intelligent Routing**: Host-based routing directs traffic to correct service
- **Service Isolation**: Each subdomain routes to dedicated instance

### Operational Benefits
- **Monitoring Granularity**: Per-service metrics and alerts
- **Security Isolation**: Separate security groups per service
- **Maintenance Windows**: Independent maintenance schedules
- **Performance Tuning**: Service-specific optimizations
- **Traffic Analysis**: Per-subdomain traffic insights
- **Targeted Scaling**: Scale only the services that need it

## High Availability Features

### Multi-AZ Deployment
- **Auto Scaling Groups**: Distribute instances across AZs
- **RDS Multi-AZ**: Database high availability (existing)
- **Load Balancer**: Cross-AZ traffic distribution
- **S3**: Built-in 99.999999999% durability

### Disaster Recovery
- **Cross-Region Replication**: S3 buckets
- **RDS Snapshots**: Cross-region backup copies
- **AMI Backups**: Instance image backups
- **Infrastructure as Code**: Quick environment recreation

## Migration Strategy

### Phase 1: Infrastructure Setup (Week 1)
1. Launch 4 new EC2 instances with auto-scaling groups
2. Create EFS file system with mount targets in all AZs
3. Configure ALB with separate target groups
4. Set up S3 buckets with intelligent tiering
5. Configure CloudWatch monitoring and alarms

### Phase 2: Application Migration (Week 2-3)
1. Install EFS utilities on all EC2 instances
2. Mount EFS file system on all instances (/mnt/sessions)
3. Deploy PIDS Main to dedicated instance
4. Deploy PJD to dedicated instance
5. Deploy SERPP to dedicated instance
6. Deploy HEFP to dedicated instance
7. Configure database connections per service
8. Update YII Framework session configuration for EFS

### Phase 3: Data Migration (Week 4)
1. Migrate files to respective S3 buckets
2. Test S3FS mounts on all instances
3. Test EFS session sharing across instances
4. Configure backup cron jobs per instance
5. Validate data integrity across services

### Phase 4: Testing and Cutover (Week 5)
1. Load testing per service with auto-scaling
2. Session persistence testing during scaling events
3. End-to-end integration testing
4. Disaster recovery testing
5. DNS cutover with gradual traffic shift

## Monitoring and Alerting

### Service-Level Monitoring
- **Application Performance**: Response time per service
- **Resource Utilization**: CPU, memory, disk per instance
- **Database Performance**: Connection pools per service
- **Auto Scaling Events**: Scale-out/scale-in activities
- **Cost Optimization**: Right-sizing recommendations

### Unified Dashboard
- **Service Health**: Overall system status
- **Traffic Distribution**: Load per service
- **Cost Tracking**: Per-service cost allocation
- **Performance Trends**: Historical analysis

---

**Architecture Version**: Option-3  
**Focus**: Microservices with Dedicated EC2 Instances  
**Cost Impact**: +20-25% increase for enhanced scalability and isolation  
**Performance Impact**: Optimized per-service scaling and fault isolation

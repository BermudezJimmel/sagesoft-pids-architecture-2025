# PIDS Option-1 Architecture - S3 Integration with Intelligent Tiering

## Architecture Overview

This optimized architecture introduces S3 storage integration, automated backup systems, and intelligent cost management while maintaining the current application structure with performance improvements.

## Enhanced Infrastructure Components

### Compute Resources (EC2 Instances)

| Server Name | Instance Type | CPU Cores | RAM (GB) | Operating System | Applications Hosted | S3 Mount Point |
|-------------|---------------|-----------|----------|------------------|-------------------|----------------|
| EC2: PIDS   | t3a.xlarge    | 4         | 16       | Ubuntu 24.04     | PIDS (Main), PJD (Subdomain) | /mnt/pids-files |
| EC2: SERPP  | t3a.xlarge    | 4         | 16       | Ubuntu 24.04     | SERPP (Subdomain), HEFP (Subdomain) | /mnt/serpp-files |

### Database Resources (RDS) with Monitoring

| Database Name | Instance Type | Engine Version | Storage (GB) | Monitoring | Backup |
|---------------|---------------|----------------|--------------|------------|---------|
| RDS: pids     | db.m5.xlarge  | MySQL 8.0.33   | 200          | CloudWatch Alarms | RDS Automated Backup |
| RDS: serpp    | db.m5.xlarge  | MySQL 8.0.42   | 200          | CloudWatch Alarms | RDS Automated Backup |

### Storage Architecture (S3)

| Bucket Name | Purpose | Lifecycle Policy | Access Pattern |
|-------------|---------|------------------|----------------|
| pids-pdf-files | PIDS PDF storage | Intelligent Tiering | Frequent access |
| serpp-pdf-archive | SERPP PDF archive | Intelligent Tiering | Mixed access |
| pids-database-exports | DB export storage (from EC2) | IA → Glacier → Deep Archive | Backup retention |
| pids-application-backups | App backup storage (from EC2) | IA → Glacier | Recovery purposes |

## S3 Integration Architecture

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
│                 (Simple Default Routing)                        │
└─────────────────┬───────────────────┬───────────────────────────┘
                  │                   │
        ┌─────────▼─────────┐ ┌───────▼─────────┐
        │   TG: pids-tg     │ │  TG: serpp-tg   │
        └─────────┬─────────┘ └───────┬─────────┘
                  │                   │
        ┌─────────▼─────────┐ ┌───────▼─────────┐
        │   EC2: PIDS       │ │   EC2: SERPP    │
        │   t3a.xlarge      │ │   t3a.xlarge    │
        │   - PIDS Main     │ │   - SERPP       │
        │   - PJD           │ │   - HEFP        │
        └─────────┬─────────┘ └───────┬─────────┘
        │                           │
        │ S3 Mount                  │ S3 Mount
        │ /mnt/pids-files           │ /mnt/serpp-files
        │                           │
┌───────▼────────┐         ┌────────▼────────┐
│ S3: pids-pdf-  │         │ S3: serpp-pdf-  │
│     files      │         │     archive     │
│ Intelligent    │         │ Intelligent     │
│ Tiering        │         │ Tiering         │
└────────────────┘         └─────────────────┘
        │                           │
        │ Database Connection       │ Database Connection
        │                           │
┌───────▼────────┐         ┌────────▼────────┐
│  RDS: pids     │         │  RDS: serpp     │
│  db.m5.xlarge  │         │  db.m5.xlarge   │
│  MySQL 8.0.33  │         │  MySQL 8.0.42   │
│  200GB         │         │  200GB          │
│  + Alarms      │         │  + Alarms       │
└────────────────┘         └─────────────────┘
        │                           │
        │ EC2 Export Cron Jobs      │ EC2 Export Cron Jobs
        │                           │
┌───────▼────────┐         ┌────────▼────────┐
│ S3: pids-      │         │ S3: pids-       │
│ database-      │         │ application-    │
│ exports        │         │ backups         │
└────────────────┘         └─────────────────┘
```

## S3 Intelligent Tiering Configuration

### Lifecycle Policies

#### PDF Files Storage
```
Standard → Standard-IA (30 days) → Glacier Instant Retrieval (90 days) → Glacier Flexible Retrieval (180 days) → Glacier Deep Archive (365 days)
```

#### Database Backups
```
Standard → Standard-IA (7 days) → Glacier Flexible Retrieval (30 days) → Glacier Deep Archive (90 days)
```

#### Application Backups
```
Standard → Standard-IA (30 days) → Glacier Flexible Retrieval (90 days)
```

## Database Monitoring and Alarms

### CloudWatch Alarms Configuration

#### PIDS Database (db.m5.xlarge)
| Metric | Threshold | Action |
|--------|-----------|--------|
| CPU Utilization | > 80% for 5 minutes | SNS Alert + Auto-scaling consideration |
| Database Connections | > 80% of max | SNS Alert |
| Free Storage Space | < 20GB | SNS Alert + Storage expansion |
| Read/Write Latency | > 200ms | SNS Alert |

#### SERPP Database (db.m5.xlarge)
| Metric | Threshold | Action |
|--------|-----------|--------|
| CPU Utilization | > 80% for 5 minutes | SNS Alert |
| Database Connections | > 80% of max | SNS Alert |
| Free Storage Space | < 20GB | SNS Alert |
| Read/Write Latency | > 200ms | SNS Alert |

## Backup Strategy

### RDS Automated Backups
- **Backup Retention**: 7 days (configurable up to 35 days)
- **Backup Window**: 2:00-3:00 AM (low traffic period)
- **Point-in-Time Recovery**: Available within retention period
- **Cross-Region Backup**: Optional for disaster recovery

### EC2-Based Backup Cron Jobs

#### Database Export Backups (Daily) - From EC2
```bash
# PIDS Database Export - 4:00 AM daily (after RDS backup)
0 4 * * * /usr/local/bin/mysql-export-pids.sh

# SERPP Database Export - 5:00 AM daily
0 5 * * * /usr/local/bin/mysql-export-serpp.sh
```

#### Application Backups (Weekly) - From EC2
```bash
# Application files backup - Sunday 1:00 AM
0 1 * * 0 /usr/local/bin/app-backup-pids.sh
0 1 * * 0 /usr/local/bin/app-backup-serpp.sh
```

#### S3 Sync for PDF Files (Hourly) - From EC2
```bash
# Sync PDF files to S3 - Every hour
0 * * * * aws s3 sync /var/www/pids/uploads/ s3://pids-pdf-files/ --delete
0 * * * * aws s3 sync /var/www/serpp/files/ s3://serpp-pdf-archive/ --delete
```

## S3 Mount Configuration

### S3FS Mount Points

#### PIDS Server
```bash
# /etc/fstab entry
s3fs#pids-pdf-files /mnt/pids-files fuse _netdev,allow_other,iam_role=auto 0 0
```

#### SERPP Server
```bash
# /etc/fstab entry
s3fs#serpp-pdf-archive /mnt/serpp-files fuse _netdev,allow_other,iam_role=auto 0 0
```

## Cost Optimization Features

### Instance Configuration
- **EC2 Instances**: Both maintained as t3a.xlarge (current setup)
- **Database Instances**: Both maintained as db.m5.xlarge (current setup)

### Storage Cost Reduction
- **Intelligent Tiering**: Automatic cost optimization based on access patterns
- **Historical Archive**: 1999-2002 files moved to Deep Archive
- **Backup Retention**: Automated lifecycle management

### Performance Improvements
- **S3 Integration**: Offload file storage from EC2 instances
- **Backup Automation**: Reliable disaster recovery
- **Monitoring**: Proactive issue detection

## AWS Services Used

### Core Services
- **EC2**: 2 instances (optimized sizing)
- **RDS**: 2 MySQL databases (with monitoring)
- **S3**: 4 buckets with intelligent tiering
- **CloudWatch**: Database monitoring and alarms
- **SNS**: Alert notifications

### Networking
- **Global Accelerator**: Static IP and performance
- **Application Load Balancer**: Traffic distribution
- **VPC**: Network isolation

### Storage & Backup
- **S3 Intelligent Tiering**: Automated cost optimization
- **S3FS**: File system integration
- **Automated Backups**: Cron-based backup strategy

## Implementation Benefits

### Cost Savings
- S3 Intelligent storage tiering (30-50% storage cost reduction)
- Automated backup lifecycle management
- Optimized storage costs for 577k+ files

### Performance Improvements
- Offloaded file storage from EC2
- Better resource utilization
- Proactive monitoring and alerting

### Reliability Enhancements
- Automated backup strategy
- Database monitoring and alerting
- Disaster recovery capabilities

## Migration Considerations

### Phase 1: Infrastructure Setup
1. Create S3 buckets with intelligent tiering
2. Set up CloudWatch alarms
3. Configure SNS notifications

### Phase 2: Storage Migration
1. Install and configure S3FS on EC2 instances
2. Migrate existing PDF files to S3
3. Update application file paths

### Phase 3: Backup Implementation
1. Deploy backup scripts
2. Configure cron jobs
3. Test backup and restore procedures

### Phase 4: Monitoring & Optimization
1. Monitor performance metrics
2. Fine-tune alarm thresholds
3. Optimize S3 lifecycle policies

---

**Architecture Version**: Option-1  
**Focus**: S3 Integration with Intelligent Tiering  
**Cost Impact**: 40-60% reduction in storage costs  
**Performance Impact**: Improved file handling and backup reliability

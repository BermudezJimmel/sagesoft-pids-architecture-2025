# PIDS Option-2 Architecture - Monolith Consolidation

## Architecture Overview

This consolidated architecture combines all applications into a single EC2 instance with a unified database, optimizing for cost efficiency while maintaining functionality through proper resource allocation and monitoring.

## Consolidated Infrastructure Components

### Compute Resources (EC2 Instance)

| Server Name | Instance Type | CPU Cores | RAM (GB) | Operating System | Applications Hosted | S3 Mount Point |
|-------------|---------------|-----------|----------|------------------|-------------------|----------------|
| EC2: PIDS-ALL | c5.2xlarge   | 8         | 16       | Ubuntu 24.04     | PIDS, PJD, SERPP, HEFP | /mnt/pids-files |

### Database Resources (RDS) - Unified

| Database Name | Instance Type | Engine Version | Storage (GB) | Monitoring | Backup |
|---------------|---------------|----------------|--------------|------------|---------|
| RDS: pids-unified | db.m5.2xlarge | MySQL 8.0.42 | 400 | CloudWatch Alarms | RDS Automated Backup |

### Storage Architecture (S3)

| Bucket Name | Purpose | Lifecycle Policy | Access Pattern |
|-------------|---------|------------------|----------------|
| pids-unified-files | All PDF storage | Intelligent Tiering | Mixed access |
| pids-database-exports | DB export storage (from EC2) | IA → Glacier → Deep Archive | Backup retention |
| pids-application-backups | App backup storage (from EC2) | IA → Glacier | Recovery purposes |

## Monolith Architecture Diagram

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
└─────────────────────┬───────────────────────────────────────────┘
                      │
        ┌─────────────▼─────────────┐
        │   TG: pids-all-tg         │
        └─────────────┬─────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                EC2: PIDS-ALL                                    │
│                c5.2xlarge                                       │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  Virtual Hosts Configuration                           │   │
│   │  ┌─────────────┬─────────────┬─────────────┬─────────┐  │   │
│   │  │ PIDS Main   │ PJD         │ SERPP       │ HEFP    │  │   │
│   │  │ (Primary)   │ (Subdomain) │ (Subdomain) │ (YII +  │  │   │
│   │  │ YII         │ YII         │ YII         │ Power   │  │   │
│   │  │             │             │             │ BI)     │  │   │
│   │  └─────────────┴─────────────┴─────────────┴─────────┘  │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│   S3 Mount: /mnt/pids-files  │                                  │
└──────────────────────────────┼──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                    S3: pids-unified-files                       │
│                    Intelligent Tiering                          │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               │ Database Connection
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                  RDS: pids-unified                              │
│                  db.m5.2xlarge                                  │
│                  MySQL 8.0.42                                   │
│                  400GB Storage                                   │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  Database Schema Organization                           │   │
│   │  ┌─────────────┬─────────────┬─────────────┬─────────┐  │   │
│   │  │ pids_main   │ pids_pjd    │ pids_serpp  │pids_hefp│  │   │
│   │  │ (schema)    │ (schema)    │ (schema)    │(schema) │  │   │
│   │  └─────────────┴─────────────┴─────────────┴─────────┘  │   │
│   │  ┌─────────────────────────────────────────────────────┐  │   │
│   │  │ shared (schema) - Users, Sessions, Common Data     │  │   │
│   │  └─────────────────────────────────────────────────────┘  │   │
│   └─────────────────────────────────────────────────────────┘   │
│                  + CloudWatch Alarms                            │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               │ EC2 Export Cron Jobs
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                S3: pids-database-exports                        │
│                S3: pids-application-backups                     │
└─────────────────────────────────────────────────────────────────┘
```

## Application Consolidation Strategy

### Web Server Configuration (Apache/Nginx)

#### Virtual Hosts Setup
```apache
# PIDS Main - Primary Domain
<VirtualHost *:80>
    ServerName pids.gov.ph
    DocumentRoot /var/www/pids-main
    # YII Framework Configuration
</VirtualHost>

# PJD Subdomain
<VirtualHost *:80>
    ServerName pjd.pids.gov.ph
    DocumentRoot /var/www/pids-pjd
    # YII Framework Configuration
</VirtualHost>

# SERPP Subdomain
<VirtualHost *:80>
    ServerName serpp.pids.gov.ph
    DocumentRoot /var/www/pids-serpp
    # YII Framework Configuration
</VirtualHost>

# HEFP Subdomain
<VirtualHost *:80>
    ServerName hefp.pids.gov.ph
    DocumentRoot /var/www/pids-hefp
    # YII Framework Configuration + Power BI Integration
</VirtualHost>
```

### Database Schema Organization

#### Unified Database Structure
```sql
-- Separate schemas for each application
CREATE SCHEMA pids_main;    -- PIDS main application data
CREATE SCHEMA pids_pjd;     -- PJD application data  
CREATE SCHEMA pids_serpp;   -- SERPP application data
CREATE SCHEMA pids_hefp;    -- HEFP application data
CREATE SCHEMA shared;       -- Shared resources (users, sessions, etc.)
```

## Resource Allocation and Performance

### Traffic Distribution Handling
| Application | Expected Load | Resource Allocation | Performance Notes |
|-------------|---------------|-------------------|-------------------|
| PIDS Main | 40k-50k concurrent | 60% CPU/Memory | Primary resource consumer |
| SERPP | 150 concurrent | 15% CPU/Memory | Light load, file-heavy |
| PJD | 5k-10k concurrent | 20% CPU/Memory | New application growth |
| HEFP | Variable | 5% CPU/Memory | YII + Power BI integration |

### Instance Sizing Rationale
- **c5.2xlarge**: 8 vCPUs, 16GB RAM
- **CPU**: Handles 50k concurrent users with headroom
- **Memory**: Sufficient for YII Framework + MySQL connections
- **Network**: Enhanced networking for high throughput

## Database Monitoring and Alarms

### CloudWatch Alarms Configuration

#### Unified Database (db.m5.2xlarge)
| Metric | Threshold | Action |
|--------|-----------|--------|
| CPU Utilization | > 75% for 5 minutes | SNS Alert + Scale consideration |
| Database Connections | > 75% of max | SNS Alert |
| Free Storage Space | < 40GB | SNS Alert + Storage expansion |
| Read/Write Latency | > 250ms | SNS Alert |
| Memory Utilization | > 80% | SNS Alert |

### Application-Level Monitoring
| Metric | Threshold | Action |
|--------|-----------|--------|
| EC2 CPU Utilization | > 80% for 10 minutes | SNS Alert + Auto-scaling trigger |
| Memory Utilization | > 85% | SNS Alert |
| Disk I/O | > 80% utilization | SNS Alert |
| Network In/Out | > 80% baseline | SNS Alert |

## Backup Strategy

### RDS Automated Backups
- **Backup Retention**: 7 days (configurable up to 35 days)
- **Backup Window**: 2:00-3:00 AM (low traffic period)
- **Point-in-Time Recovery**: Available within retention period
- **Cross-Region Backup**: Optional for disaster recovery

### EC2-Based Backup Cron Jobs

#### Database Export Backups (Daily) - From EC2
```bash
# Unified Database Export - 4:00 AM daily (after RDS backup)
0 4 * * * /usr/local/bin/mysql-export-unified.sh

# Schema-specific exports - 5:00 AM daily
0 5 * * * /usr/local/bin/mysql-export-schemas.sh
```

#### Application Backups (Weekly) - From EC2
```bash
# All applications backup - Sunday 1:00 AM
0 1 * * 0 /usr/local/bin/app-backup-all.sh
```

#### S3 Sync for Files (Hourly) - From EC2
```bash
# Sync all PDF files to S3 - Every hour
0 * * * * aws s3 sync /var/www/*/uploads/ s3://pids-unified-files/ --delete
```

## S3 Integration

### S3FS Mount Configuration
```bash
# /etc/fstab entry
s3fs#pids-unified-files /mnt/pids-files fuse _netdev,allow_other,iam_role=auto 0 0
```

### Intelligent Tiering Policy
```
Standard → Standard-IA (30 days) → Glacier Instant Retrieval (90 days) → Glacier Flexible Retrieval (180 days) → Glacier Deep Archive (365 days)
```

## Cost Optimization Analysis

### Infrastructure Cost Comparison
| Component | Current (2 instances) | Option-2 (Monolith) | Savings |
|-----------|----------------------|---------------------|---------|
| EC2 | 2x t3a.xlarge | 1x c5.2xlarge | ~30% |
| RDS | 2x db.m5.xlarge | 1x db.m5.2xlarge | ~40% |
| Storage | 400GB total | 400GB unified | 0% |
| Data Transfer | Separate | Consolidated | ~20% |

### Total Estimated Savings: 35-45%

## Performance Considerations

### Advantages
- Reduced network latency between applications
- Shared resource utilization
- Simplified management and monitoring
- Lower data transfer costs
- Consolidated backup strategy

### Potential Challenges
- Single point of failure
- Resource contention during peak loads
- Application isolation concerns
- Scaling limitations

## High Availability Enhancements

### Recommended Additions
- **Auto Scaling Group**: Single instance with replacement capability
- **EBS Snapshots**: Automated daily snapshots
- **Multi-AZ RDS**: Database high availability
- **CloudWatch Dashboards**: Unified monitoring
- **Application Health Checks**: Load balancer health monitoring

## Migration Strategy

### Phase 1: Infrastructure Setup
1. Launch c5.2xlarge instance
2. Set up unified RDS database
3. Configure S3 buckets and intelligent tiering

### Phase 2: Application Migration
1. Install and configure web server with virtual hosts
2. Migrate application code to single instance
3. Consolidate database schemas

### Phase 3: Data Migration
1. Export data from existing databases
2. Import into unified database with proper schema separation
3. Migrate files to S3 with intelligent tiering

### Phase 4: Testing and Cutover
1. Performance testing with expected load
2. Backup and disaster recovery testing
3. DNS cutover and monitoring

## Monitoring and Alerting

### Unified Dashboard Metrics
- Application response times per virtual host
- Database performance per schema
- Resource utilization trends
- Cost optimization opportunities
- User traffic patterns

### Alert Escalation
1. **Warning**: 70% resource utilization
2. **Critical**: 85% resource utilization  
3. **Emergency**: 95% resource utilization + auto-scaling trigger

---

**Architecture Version**: Option-2  
**Focus**: Monolith Consolidation for Cost Optimization  
**Cost Impact**: 35-45% reduction in infrastructure costs  
**Performance Impact**: Optimized resource sharing with monitoring

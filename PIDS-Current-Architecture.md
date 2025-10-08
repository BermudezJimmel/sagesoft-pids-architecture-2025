# PIDS (Philippine Institute for Development Studies) - Current AWS Architecture

## Architecture Overview

This document outlines the current AWS infrastructure for PIDS, serving as a reference for Draw.IO architecture diagrams and AWS Calculator estimations.

## Current Infrastructure Components

### Compute Resources (EC2 Instances)

| Server Name | Instance Type | CPU Cores | RAM (GB) | Operating System | Applications Hosted |
|-------------|---------------|-----------|----------|------------------|-------------------|
| EC2: PIDS   | t3a.xlarge    | 4         | 16       | Ubuntu 24.04     | PIDS (Main), PJD (Subdomain) |
| EC2: SERPP  | t3a.xlarge    | 4         | 16       | Ubuntu 24.04     | SERPP (Subdomain), HEFP (Subdomain) |

### Database Resources (RDS)

| Database Name | Instance Type | Engine Version | Storage (GB) | Purpose |
|---------------|---------------|----------------|--------------|---------|
| RDS: pids     | db.m5.xlarge  | MySQL 8.0.33   | 200          | PIDS Main Database |
| RDS: serpp    | db.m5.xlarge  | MySQL 8.0.42   | 200          | SERPP Database |

### Network & Load Balancing

- **Global Accelerator**: Provides static IP addresses for improved performance
- **Application Load Balancer**: Distributes traffic across EC2 instances
- **VPC**: Default or custom VPC configuration (to be confirmed)

## Application Details

### PIDS Server Applications
- **PIDS (Main)**: Primary research platform for internal/external researchers (YII Framework)
- **PJD (Subdomain)**: New web application serving as landing page for PIDS, Journals, and NEDA compliance (YII Framework)

### SERPP Server Applications  
- **SERPP (Subdomain)**: Publication entry system for all platforms (YII Framework)
- **HEFP (Subdomain)**: YII Framework application with Power BI visualization integration

## Current Traffic Flow Architecture

```
Internet Users
    ↓
AWS Global Accelerator (Static IP)
    ↓
Application Load Balancer
    ↓
┌─────────────────┬─────────────────┐
│   EC2: PIDS     │   EC2: SERPP    │
│   - PIDS Main   │   - SERPP       │
│   - PJD         │   - HEFP        │
└─────────────────┴─────────────────┘
    ↓                   ↓
┌─────────────────┬─────────────────┐
│  RDS: pids      │  RDS: serpp     │
│  MySQL 8.0.33   │  MySQL 8.0.42   │
│  200GB          │  200GB          │
└─────────────────┴─────────────────┘
```

## Detailed Traffic Patterns

1. **PIDS Main Access**:
   - User → Global Accelerator → Load Balancer → EC2: PIDS → RDS: pids

2. **Database Administration**:
   - User → Global Accelerator → Load Balancer → EC2: PIDS (PHPMyAdmin) → RDS: pids

3. **SERPP Publication System**:
   - User → Global Accelerator → Load Balancer → EC2: SERPP → RDS: serpp

4. **SERPP Database Access**:
   - User → Global Accelerator → Load Balancer → EC2: SERPP → RDS: serpp

5. **HEFP Visualization**:
   - User → Global Accelerator → Load Balancer → EC2: SERPP (HEFP) → Power BI Integration

## Traffic and Performance Metrics

### PIDS Main Application
| Metric | Value | Notes |
|--------|-------|-------|
| Peak Concurrent Users | 40,000 | Maximum simultaneous users |
| Average Concurrent Users | 50,000 | Benchmark for testing |
| Daily Active Users | 5,000 | Normal daily load |
| Monthly Active Users | 150,000 | Total monthly reach |
| Network Requests per Session | 61 | Browser network analysis |
| Data Transfer per Session | 10 MB | Average session bandwidth |
| Critical Requests | 21/61 | Essential requests for functionality |

### SERPP Application
| Metric | Value | Notes |
|--------|-------|-------|
| Concurrent Users | 150 | Much lower than PIDS |
| Network Requests per Session | 60 | Similar to PIDS |
| Data Transfer per Session | 5 MB | Half of PIDS transfer |
| Total Files | 577,000 | Existing archive |
| File Growth Rate | 50 files/month | Steady growth |
| Archive Period | 1999-2002 | Historical data |

### Traffic Patterns
- **Normal Load**: 5,000 users daily
- **Peak Events**: September yearly broadcast event
- **Traffic Source**: Primarily organic search
- **Content Type**: PDF files, images, research publications

## Storage and Content Analysis

### Current Storage Usage
- **Available Storage**: 639 GB (from df -h command)
- **Content Types**: PDF files, images, research data
- **Archive Strategy**: Deep Archive for 1999-2002 files

### Content Optimization Opportunities
- **GZIP Compression**: Enable for program files
- **CloudFront CDN**: Recommended for SERPP (PDF distribution)
- **Caching Strategy**: No-cache headers currently implemented
- **File Management**: Historical files suitable for AWS Deep Archive

## User Access Patterns

| Application | User Type | Access Method | Traffic Source | Framework | Concurrent Users | Optimization Notes |
|-------------|-----------|---------------|----------------|-----------|------------------|-------------------|
| PIDS | Researchers (Internal/External) | Google/Social Media | Organic Search | YII Framework | 40k-50k peak | High traffic, needs scaling |
| SERPP | Publication Entry Users | Direct Access | All Systems | YII Framework | 150 users | Small instance candidate |
| PJD | General Public | Landing Page | PIDS, Journals, NEDA | YII Framework | TBD | New application |
| HEFP | Data Analysts | Iframe/Power BI | Visualization Requests | YII Framework | TBD | YII + Power BI integration |

## AWS Services Currently Used

- **EC2**: 2 instances (t3a.xlarge)
- **RDS**: 2 MySQL databases (db.m5.xlarge)
- **Global Accelerator**: 1 accelerator with static IPs
- **Application Load Balancer**: 1 ALB for traffic distribution
- **VPC**: Network isolation and security
- **Security Groups**: Instance-level firewall rules
- **Route 53**: DNS management (assumed)

## Architecture Considerations

### Current Strengths
- Global Accelerator provides improved performance and static IPs
- Load balancer enables high availability
- Separate databases for different applications
- Ubuntu 24.04 LTS provides long-term support
- YII Framework provides robust PHP-based web application structure
- Handles significant concurrent user load (40k-50k users)

### Areas for Optimization (Future Recommendations)
- Single points of failure (no redundancy)
- No auto-scaling capabilities for peak events (September broadcast)
- Limited disaster recovery setup
- Potential for resource optimization
- YII Framework caching optimization opportunities
- **SERPP Optimization**: Candidate for smaller instance (150 users vs 50k)
- **Content Delivery**: CloudFront CDN for PDF distribution
- **Storage Optimization**: Deep Archive for historical files (1999-2002)
- **Compression**: Enable GZIP for better performance
- **Caching Strategy**: Review no-cache headers for static content

### Performance Bottlenecks Identified
- High data transfer per session (10MB for PIDS, 5MB for SERPP)
- Large number of requests per session (60+ requests)
- No CDN for static content distribution
- Historical files consuming storage without archival strategy

## Next Steps

This architecture documentation will be used to:
1. Create detailed Draw.IO architecture diagrams
2. Generate AWS Calculator cost estimates
3. Develop optimization recommendations
4. Plan future scalability improvements

---

**Document Version**: 1.0  
**Last Updated**: October 8, 2025  
**Prepared for**: PIDS AWS Architecture Review

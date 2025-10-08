# PIDS AWS Architecture Options Dashboard

## Overview

This dashboard provides a comprehensive overview of all PIDS (Philippine Institute for Development Studies) AWS architecture options, from current state to optimized solutions.

---

## 📊 Current Architecture

### [Current Setup](./PIDS-Current-Architecture.md)
**Infrastructure**: 2x t3a.xlarge EC2 + 2x db.m5.xlarge RDS  
**Applications**: PIDS, PJD, SERPP, HEFP (All YII Framework)  
**Traffic**: 50k concurrent users, 150k monthly active users  
**Storage**: 577k files, 50 files/month growth  

**Key Metrics**:
- Peak Load: 40k-50k concurrent users
- Data Transfer: 10MB per session (PIDS), 5MB (SERPP)
- Network Requests: 60+ per session
- Available Storage: 639GB

---

## 🚀 Optimization Options

### [Option-1: S3 Integration with Intelligent Tiering](./PIDS-Option-1-Architecture.md)
**Focus**: Storage optimization and automated backup strategy  
**Infrastructure**: 2x t3a.xlarge EC2 + 2x db.m5.xlarge RDS + S3 Integration  
**Cost Impact**: 30-50% storage cost reduction  

**Key Features**:
- ✅ S3 mounted storage per server
- ✅ Intelligent tiering for cost optimization
- ✅ Automated backup cron jobs from EC2
- ✅ RDS automated backups
- ✅ CloudWatch database monitoring
- ✅ Maintains current infrastructure sizing

**Benefits**:
- Significant storage cost savings
- Automated lifecycle management
- Enhanced backup reliability
- Proactive database monitoring

---

### [Option-2: Monolith Consolidation](./PIDS-Option-2-Architecture.md)
**Focus**: Cost optimization through infrastructure consolidation  
**Infrastructure**: 1x c5.2xlarge EC2 + 1x db.m5.2xlarge RDS + S3 Integration  
**Cost Impact**: 35-45% total infrastructure cost reduction  

**Key Features**:
- ✅ Single EC2 instance (8 vCPUs, 16GB RAM)
- ✅ Unified database with separate schemas
- ✅ Virtual hosts for application separation
- ✅ S3 integration with intelligent tiering
- ✅ Consolidated backup strategy
- ✅ Resource sharing optimization

**Benefits**:
- Maximum cost savings
- Simplified management
- Shared resource utilization
- Reduced data transfer costs

**Considerations**:
- Single point of failure
- Resource contention during peak loads

---

### [Option-3: Microservices with Dedicated Instances](./PIDS-Option-3-Architecture.md)
**Focus**: Maximum scalability and fault isolation  
**Infrastructure**: 4x EC2 instances + 2x db.m5.xlarge RDS + S3 Integration + EFS  
**Cost Impact**: +20-25% increase for enhanced capabilities  

**Key Features**:
- ✅ Dedicated EC2 per application (PIDS, PJD, SERPP, HEFP)
- ✅ Right-sized instances per workload
- ✅ Independent auto-scaling groups
- ✅ Separate target groups per instance
- ✅ EFS for shared session storage (ASG support)
- ✅ Fault isolation and independent deployments
- ✅ Service-specific monitoring

**Instance Sizing**:
- PIDS Main: t3a.xlarge (high traffic)
- PJD: t3a.medium (medium traffic)
- SERPP: t3a.small (low traffic)
- HEFP: t3a.small (low traffic)

**Benefits**:
- Independent scaling per service
- Maximum fault isolation
- Session persistence across scaling events
- Independent deployment cycles
- Service-specific optimizations

---

## 📋 Architecture Comparison Matrix

| Feature | Current | Option-1 | Option-2 | Option-3 |
|---------|---------|----------|----------|----------|
| **EC2 Instances** | 2x t3a.xlarge | 2x t3a.xlarge | 1x c5.2xlarge | 4x mixed sizes |
| **RDS Databases** | 2x db.m5.xlarge | 2x db.m5.xlarge | 1x db.m5.2xlarge | 2x db.m5.xlarge |
| **S3 Integration** | ❌ | ✅ | ✅ | ✅ |
| **EFS Integration** | ❌ | ❌ | ❌ | ✅ |
| **Auto Scaling** | ❌ | ❌ | Limited | ✅ Full |
| **Session Persistence** | Limited | Limited | Limited | ✅ EFS |
| **Fault Isolation** | Medium | Medium | Low | High |
| **Cost Change** | Baseline | Storage -30% | Total -35% | Total +20% |
| **Complexity** | Low | Medium | Low | High |
| **Scalability** | Limited | Limited | Medium | High |

---

## 🎯 Recommendation Summary

### **For Cost Optimization**: Choose Option-2
- Best for budget-conscious approach
- 35-45% cost reduction
- Suitable for current traffic patterns
- Simplified management

### **For Balanced Approach**: Choose Option-1
- Maintains current infrastructure
- Significant storage cost savings
- Enhanced backup and monitoring
- Low migration risk

### **For Future Growth**: Choose Option-3
- Maximum scalability and flexibility
- Independent service scaling
- Best for growing traffic demands
- Supports microservices architecture

---

## 📈 Traffic and Performance Data

### Current Metrics
- **Peak Concurrent Users**: 40,000-50,000
- **Daily Active Users**: 5,000
- **Monthly Active Users**: 150,000
- **September Event**: Yearly broadcast (peak load)
- **File Archive**: 577,000 files (1999-2002 historical data)

### Application Load Distribution
| Application | Users | Framework | Database | Optimization Notes |
|-------------|-------|-----------|----------|-------------------|
| PIDS Main | 40k-50k | YII | RDS: pids | High traffic, primary focus |
| SERPP | 150 | YII | RDS: serpp | Low traffic, downsizing candidate |
| PJD | 5k-10k | YII | RDS: pids | New application, growth potential |
| HEFP | Variable | YII + Power BI | RDS: serpp | Visualization focused |

---

## 🔧 Implementation Roadmap

### Phase 1: Planning & Preparation (Week 1-2)
- Finalize architecture option selection
- Create detailed implementation plan
- Set up AWS Calculator cost estimates
- Prepare Draw.IO architecture diagrams

### Phase 2: Infrastructure Setup (Week 3-4)
- Deploy selected architecture components
- Configure S3 buckets and intelligent tiering
- Set up monitoring and alerting
- Configure backup strategies

### Phase 3: Migration & Testing (Week 5-6)
- Migrate applications and data
- Perform load testing
- Validate backup and recovery procedures
- End-to-end integration testing

### Phase 4: Go-Live & Optimization (Week 7-8)
- DNS cutover and traffic migration
- Monitor performance and costs
- Fine-tune configurations
- Document operational procedures

---

## 📞 Next Steps

1. **Review Architecture Options**: Click on the links above to explore detailed specifications
2. **Cost Analysis**: Use AWS Calculator with provided specifications
3. **Create Draw.IO Diagrams**: Use architecture details for visual representations
4. **Decision Making**: Select optimal architecture based on requirements and budget
5. **Implementation Planning**: Develop detailed migration strategy

---

**Dashboard Version**: 1.0  
**Last Updated**: October 8, 2025  
**Total Architecture Options**: 4 (Current + 3 Optimized)  
**Documentation Status**: Complete

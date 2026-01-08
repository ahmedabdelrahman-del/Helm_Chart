# E-Commerce Microservices Architecture

## System Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                            INTERNET                                 │
└─────────────────────────────┬──────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Load Balancer (ALB)                         │
│                     SSL Termination / WAF                           │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       API Gateway (Port 3000)                       │
│                         Node.js + Express                           │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ • Request Routing                                            │  │
│  │ • Authentication/Authorization (JWT Validation)              │  │
│  │ • Rate Limiting                                              │  │
│  │ • Request/Response Transformation                            │  │
│  │ • CORS Handling                                              │  │
│  │ • Logging & Monitoring                                       │  │
│  └──────────────────────────────────────────────────────────────┘  │
└───────────┬─────────────────┬─────────────────┬─────────────────────┘
            │                 │                 │
            ▼                 ▼                 ▼
┌───────────────────┐ ┌───────────────┐ ┌──────────────────┐
│   User Service    │ │Product Service│ │  Order Service   │
│   (Port 4001)     │ │ (Port 4002)   │ │  (Port 4003)     │
│   Go + Gin        │ │Python + Flask │ │ Node.js + Express│
├───────────────────┤ ├───────────────┤ ├──────────────────┤
│ • User Auth       │ │ • Catalog Mgmt│ │ • Order Creation │
│ • Registration    │ │ • Search      │ │ • Cart Mgmt      │
│ • JWT Generation  │ │ • Filtering   │ │ • Order Tracking │
│ • Profile Mgmt    │ │ • Inventory   │ │ • Status Updates │
│ • Password Hash   │ │ • Categories  │ │ • Payment Flow   │
└─────────┬─────────┘ └───────┬───────┘ └────────┬─────────┘
          │                   │                   │
          ▼                   ▼                   ▼
┌───────────────────┐ ┌───────────────┐ ┌──────────────────┐
│  PostgreSQL DB    │ │ PostgreSQL DB │ │  PostgreSQL DB   │
│   (users_db)      │ │ (products_db) │ │  (orders_db)     │
│   Port: 5433      │ │  Port: 5434   │ │   Port: 5435     │
└───────────────────┘ └───────────────┘ └──────────────────┘
```

## Service Communication

### Synchronous Communication (REST)

```
Client Request Flow:
1. Client → API Gateway (HTTPS)
2. API Gateway → Microservice (HTTP)
3. Microservice → Database (PostgreSQL)
4. Database → Microservice (Response)
5. Microservice → API Gateway (Response)
6. API Gateway → Client (Response)

Inter-Service Communication:
Order Service ──→ User Service (Validate User)
Order Service ──→ Product Service (Check Stock, Get Price)
```

### Request Path Examples

**User Registration:**
```
POST /api/users/register
├─ API Gateway (3000) validates request
└─ User Service (4001) creates user in users_db
```

**Product Search:**
```
GET /api/products/search?q=laptop
├─ API Gateway (3000) routes to Product Service
└─ Product Service (4002) queries products_db
```

**Order Creation:**
```
POST /api/orders
├─ API Gateway (3000) validates JWT token
├─ Order Service (4003) receives request
├─ Order Service → User Service: validate user exists
├─ Order Service → Product Service: check stock & get prices
├─ Order Service saves to orders_db
└─ Returns order confirmation
```

## Database Schema

### User Service Database (users_db)

```sql
users
├─ id (UUID, PK)
├─ email (VARCHAR, UNIQUE)
├─ password_hash (VARCHAR)
├─ first_name (VARCHAR)
├─ last_name (VARCHAR)
├─ created_at (TIMESTAMP)
└─ updated_at (TIMESTAMP)

Indexes:
- PRIMARY KEY (id)
- UNIQUE INDEX (email)
```

### Product Service Database (products_db)

```sql
products
├─ id (UUID, PK)
├─ name (VARCHAR)
├─ description (TEXT)
├─ price (DECIMAL)
├─ stock_quantity (INTEGER)
├─ category (VARCHAR)
├─ image_url (VARCHAR)
├─ created_at (TIMESTAMP)
└─ updated_at (TIMESTAMP)

Indexes:
- PRIMARY KEY (id)
- INDEX (category)
- INDEX (name)
```

### Order Service Database (orders_db)

```sql
orders
├─ id (UUID, PK)
├─ user_id (UUID)
├─ total_amount (DECIMAL)
├─ status (VARCHAR)
├─ created_at (TIMESTAMP)
└─ updated_at (TIMESTAMP)

order_items
├─ id (UUID, PK)
├─ order_id (UUID, FK → orders.id)
├─ product_id (UUID)
├─ quantity (INTEGER)
├─ price (DECIMAL)
└─ subtotal (DECIMAL)

cart
├─ id (UUID, PK)
├─ user_id (UUID)
├─ product_id (UUID)
├─ quantity (INTEGER)
├─ created_at (TIMESTAMP)
└─ updated_at (TIMESTAMP)

Indexes:
- PRIMARY KEY on all id fields
- FOREIGN KEY (order_items.order_id → orders.id)
- INDEX (orders.user_id)
- INDEX (orders.status)
- UNIQUE INDEX (cart.user_id, cart.product_id)
```

## Deployment Architecture (Cloud - AWS Example)

```
┌──────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                 │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                      VPC (10.0.0.0/16)                     │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │              Public Subnets (Multi-AZ)               │  │  │
│  │  │  ┌──────────────────────────────────────────────┐    │  │  │
│  │  │  │   Application Load Balancer (ALB)            │    │  │  │
│  │  │  │   - SSL/TLS Termination                      │    │  │  │
│  │  │  │   - Health Checks                            │    │  │  │
│  │  │  │   - Auto-scaling Target                      │    │  │  │
│  │  │  └──────────────────────────────────────────────┘    │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │              Private Subnets (Multi-AZ)              │  │  │
│  │  │  ┌────────────────────────────────────────────┐      │  │  │
│  │  │  │   ECS Fargate / EKS Cluster                │      │  │  │
│  │  │  │   ┌──────────────────────────────────┐     │      │  │  │
│  │  │  │   │ API Gateway (3 tasks)            │     │      │  │  │
│  │  │  │   │ User Service (2-5 tasks)         │     │      │  │  │
│  │  │  │   │ Product Service (2-5 tasks)      │     │      │  │  │
│  │  │  │   │ Order Service (2-5 tasks)        │     │      │  │  │
│  │  │  │   └──────────────────────────────────┘     │      │  │  │
│  │  │  └────────────────────────────────────────────┘      │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │           Database Subnets (Multi-AZ)                │  │  │
│  │  │  ┌────────────────────────────────────────────┐      │  │  │
│  │  │  │ RDS PostgreSQL (Multi-AZ)                  │      │  │  │
│  │  │  │ - users_db                                 │      │  │  │
│  │  │  │ - products_db                              │      │  │  │
│  │  │  │ - orders_db                                │      │  │  │
│  │  │  │ - Automated Backups                        │      │  │  │
│  │  │  │ - Read Replicas                            │      │  │  │
│  │  │  └────────────────────────────────────────────┘      │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  Supporting Services:                                             │
│  ├─ ECR (Container Registry)                                     │
│  ├─ CloudWatch (Monitoring & Logs)                               │
│  ├─ AWS Secrets Manager                                          │
│  ├─ KMS (Encryption Keys)                                        │
│  ├─ Route 53 (DNS)                                               │
│  └─ CloudFront (CDN)                                             │
└──────────────────────────────────────────────────────────────────┘
```

## Kubernetes Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                             │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                    Ingress Controller                       │  │
│  │              (NGINX / Traefik / Istio Gateway)              │  │
│  └──────────────────────────┬─────────────────────────────────┘  │
│                             │                                     │
│  ┌──────────────────────────▼─────────────────────────────────┐  │
│  │                    Namespace: prod                          │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │  API Gateway Deployment                              │  │  │
│  │  │  - Replicas: 3                                       │  │  │
│  │  │  - HPA: 2-10 pods                                    │  │  │
│  │  │  - Service: ClusterIP                                │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │  User Service Deployment                             │  │  │
│  │  │  - Replicas: 2                                       │  │  │
│  │  │  - HPA: 2-5 pods                                     │  │  │
│  │  │  - Service: ClusterIP                                │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │  Product Service Deployment                          │  │  │
│  │  │  - Replicas: 2                                       │  │  │
│  │  │  - HPA: 2-5 pods                                     │  │  │
│  │  │  - Service: ClusterIP                                │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │  Order Service Deployment                            │  │  │
│  │  │  - Replicas: 2                                       │  │  │
│  │  │  - HPA: 2-5 pods                                     │  │  │
│  │  │  - Service: ClusterIP                                │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │  ConfigMaps & Secrets                                │  │  │
│  │  │  - Database URLs                                     │  │  │
│  │  │  - API Keys                                          │  │  │
│  │  │  - JWT Secrets                                       │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Technology Stack Summary

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **API Gateway** | Node.js, Express | Request routing, auth validation |
| **User Service** | Go, Gin Framework | User management, JWT auth |
| **Product Service** | Python, Flask | Product catalog, search |
| **Order Service** | Node.js, Express | Order processing, cart |
| **Databases** | PostgreSQL 15 | Data persistence |
| **Container Runtime** | Docker | Application packaging |
| **Orchestration** | Docker Compose (local) | Local development |
| **Orchestration** | Kubernetes/ECS (prod) | Production deployment |
| **Load Balancer** | NGINX/ALB | Traffic distribution |
| **Monitoring** | Prometheus, Grafana | Metrics & dashboards |
| **Logging** | ELK/EFK Stack | Log aggregation |
| **Tracing** | Jaeger/Zipkin | Distributed tracing |
| **CI/CD** | Jenkins/GitHub Actions | Automation |
| **IaC** | Terraform | Infrastructure provisioning |

## Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Security Layers                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Network Layer                                           │
│     ├─ WAF (Web Application Firewall)                       │
│     ├─ DDoS Protection                                      │
│     ├─ Security Groups / Network Policies                   │
│     └─ Private Subnets for Services                         │
│                                                              │
│  2. Transport Layer                                         │
│     ├─ TLS 1.3                                             │
│     ├─ Certificate Management (Let's Encrypt/ACM)           │
│     └─ mTLS between services (optional)                     │
│                                                              │
│  3. Application Layer                                       │
│     ├─ JWT Authentication                                   │
│     ├─ API Rate Limiting                                    │
│     ├─ Input Validation                                     │
│     ├─ CORS Configuration                                   │
│     └─ Security Headers (HSTS, CSP, etc.)                   │
│                                                              │
│  4. Data Layer                                              │
│     ├─ Database Encryption at Rest (KMS)                    │
│     ├─ Encrypted Connections                                │
│     ├─ Password Hashing (bcrypt)                            │
│     └─ Secrets Management (Vault/AWS Secrets Manager)       │
│                                                              │
│  5. Container Layer                                         │
│     ├─ Image Scanning (Trivy, Snyk)                        │
│     ├─ Non-root User                                        │
│     ├─ Read-only Filesystem                                 │
│     └─ Resource Limits                                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Monitoring & Observability

```
┌──────────────────────────────────────────────────────────────┐
│                   Observability Stack                         │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Metrics (Prometheus)                                        │
│  ├─ Service metrics (requests, latency, errors)              │
│  ├─ System metrics (CPU, memory, disk)                       │
│  ├─ Database metrics (connections, queries)                  │
│  └─ Business metrics (orders, revenue)                       │
│                                                               │
│  Logs (ELK/EFK)                                              │
│  ├─ Application logs                                         │
│  ├─ Access logs                                              │
│  ├─ Error logs                                               │
│  └─ Audit logs                                               │
│                                                               │
│  Traces (Jaeger/Zipkin)                                      │
│  ├─ Request flow across services                             │
│  ├─ Latency breakdown                                        │
│  └─ Error root cause analysis                                │
│                                                               │
│  Dashboards (Grafana)                                        │
│  ├─ Service health overview                                  │
│  ├─ Performance metrics                                      │
│  ├─ Business KPIs                                            │
│  └─ Cost tracking                                            │
│                                                               │
│  Alerting (AlertManager / PagerDuty)                         │
│  ├─ SLO violations                                           │
│  ├─ Error rate spikes                                        │
│  ├─ Performance degradation                                  │
│  └─ Infrastructure issues                                    │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

This architecture provides a solid foundation for a production-ready microservices platform with room for growth and optimization!

# E-Commerce Microservices Platform

A production-ready microservices architecture for an e-commerce platform with 4 independent services.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Client/Frontend                      │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────┐
│                      API Gateway                            │
│                    (Node.js/Express)                        │
│              Port: 3000                                     │
│  - Request routing                                          │
│  - Authentication/Authorization                             │
│  - Rate limiting                                            │
│  - Request/Response transformation                          │
└─────┬───────────────┬───────────────┬──────────────────────┘
      │               │               │
      ▼               ▼               ▼
┌───────────┐   ┌───────────┐   ┌───────────┐
│  User     │   │  Product  │   │  Order    │
│  Service  │   │  Service  │   │  Service  │
│  (Go)     │   │  (Python) │   │  (Node.js)│
│  Port:    │   │  Port:    │   │  Port:    │
│  4001     │   │  4002     │   │  4003     │
│           │   │           │   │           │
│  - Auth   │   │  - Catalog│   │  - Orders │
│  - Users  │   │  - Search │   │  - Cart   │
│  - JWT    │   │  - Prices │   │  - Payment│
└─────┬─────┘   └─────┬─────┘   └─────┬─────┘
      │               │               │
      └───────────────┴───────────────┘
                      │
                      ▼
              ┌───────────────┐
              │   PostgreSQL  │
              │   (Database)  │
              │   Port: 5432  │
              └───────────────┘
```

## Services

### 1. API Gateway (Port 3000)
- **Technology**: Node.js + Express
- **Purpose**: Single entry point for all client requests
- **Features**:
  - Request routing to appropriate microservices
  - JWT authentication validation
  - Rate limiting
  - Request logging
  - CORS handling
  
**Endpoints**:
- `GET /health` - Health check
- `/api/users/*` - Routes to User Service
- `/api/products/*` - Routes to Product Service
- `/api/orders/*` - Routes to Order Service

### 2. User Service (Port 4001)
- **Technology**: Go + Gin Framework
- **Purpose**: User management and authentication
- **Features**:
  - User registration and login
  - JWT token generation
  - Password hashing (bcrypt)
  - User profile management

**Endpoints**:
- `POST /register` - Register new user
- `POST /login` - User login (returns JWT)
- `GET /users/:id` - Get user profile
- `PUT /users/:id` - Update user profile
- `GET /health` - Health check

### 3. Product Service (Port 4002)
- **Technology**: Python + Flask
- **Purpose**: Product catalog management
- **Features**:
  - Product CRUD operations
  - Product search and filtering
  - Category management
  - Inventory tracking

**Endpoints**:
- `GET /products` - List all products
- `GET /products/:id` - Get product details
- `POST /products` - Create product (admin)
- `PUT /products/:id` - Update product (admin)
- `DELETE /products/:id` - Delete product (admin)
- `GET /products/search?q=query` - Search products
- `GET /health` - Health check

### 4. Order Service (Port 4003)
- **Technology**: Node.js + Express
- **Purpose**: Order processing and management
- **Features**:
  - Shopping cart management
  - Order creation and tracking
  - Order history
  - Integration with User and Product services

**Endpoints**:
- `POST /orders` - Create new order
- `GET /orders/:id` - Get order details
- `GET /orders/user/:userId` - Get user's orders
- `PUT /orders/:id/status` - Update order status
- `GET /cart/:userId` - Get user's cart
- `POST /cart/:userId/items` - Add item to cart
- `DELETE /cart/:userId/items/:itemId` - Remove from cart
- `GET /health` - Health check

## Database Schema

Each service has its own database (database-per-service pattern):

**User Service DB**:
```sql
users:
  - id (uuid)
  - email (string, unique)
  - password_hash (string)
  - first_name (string)
  - last_name (string)
  - created_at (timestamp)
  - updated_at (timestamp)
```

**Product Service DB**:
```sql
products:
  - id (uuid)
  - name (string)
  - description (text)
  - price (decimal)
  - stock_quantity (integer)
  - category (string)
  - image_url (string)
  - created_at (timestamp)
  - updated_at (timestamp)
```

**Order Service DB**:
```sql
orders:
  - id (uuid)
  - user_id (uuid)
  - total_amount (decimal)
  - status (enum: pending, processing, shipped, delivered, cancelled)
  - created_at (timestamp)
  - updated_at (timestamp)

order_items:
  - id (uuid)
  - order_id (uuid)
  - product_id (uuid)
  - quantity (integer)
  - price (decimal)
  - subtotal (decimal)
```

## Running Locally

### Prerequisites
- Docker and Docker Compose
- Node.js 18+ (for local development)
- Go 1.21+ (for local development)
- Python 3.11+ (for local development)

### Quick Start with Docker Compose

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Service URLs
- API Gateway: http://localhost:3000
- User Service: http://localhost:4001
- Product Service: http://localhost:4002
- Order Service: http://localhost:4003
- PostgreSQL: localhost:5432

### Testing the System

```bash
# 1. Register a user
curl -X POST http://localhost:3000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "first_name": "John",
    "last_name": "Doe"
  }'

# 2. Login and get JWT token
curl -X POST http://localhost:3000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# 3. Get all products
curl http://localhost:3000/api/products

# 4. Create an order
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "user_id": "user-uuid",
    "items": [
      {"product_id": "product-uuid", "quantity": 2}
    ]
  }'
```

## DevOps Tasks (For You to Implement)

### 1. CI/CD Pipeline
- [ ] Set up Jenkins/GitHub Actions
- [ ] Automated testing for each service
- [ ] Build Docker images
- [ ] Push to container registry (ECR/DockerHub)
- [ ] Deploy to staging/production

### 2. Infrastructure as Code (Terraform)
- [ ] VPC and networking setup
- [ ] ECS/EKS cluster configuration
- [ ] RDS for databases
- [ ] Load balancers (ALB)
- [ ] Auto-scaling groups
- [ ] Security groups and IAM roles

### 3. Kubernetes Deployment (Optional)
- [ ] Create Kubernetes manifests
- [ ] Deployments for each service
- [ ] Services and Ingress
- [ ] ConfigMaps and Secrets
- [ ] HPA (Horizontal Pod Autoscaler)
- [ ] Network policies

### 4. Monitoring & Observability
- [ ] Prometheus for metrics
- [ ] Grafana dashboards
- [ ] ELK/EFK stack for logging
- [ ] Distributed tracing (Jaeger/Zipkin)
- [ ] APM (Application Performance Monitoring)

### 5. Service Mesh (Advanced)
- [ ] Istio/Linkerd setup
- [ ] Traffic management
- [ ] Circuit breaking
- [ ] Retry policies
- [ ] mTLS between services

### 6. Security
- [ ] HTTPS/TLS certificates
- [ ] Secrets management (Vault/AWS Secrets Manager)
- [ ] Container scanning
- [ ] Network security policies
- [ ] API rate limiting
- [ ] DDoS protection

### 7. High Availability & Disaster Recovery
- [ ] Multi-AZ deployment
- [ ] Database replication
- [ ] Backup strategies
- [ ] Failover automation
- [ ] Load testing

## Project Structure

```
.
├── api-gateway/           # Node.js API Gateway
│   ├── src/
│   ├── package.json
│   ├── Dockerfile
│   └── .dockerignore
│
├── user-service/          # Go User Service
│   ├── main.go
│   ├── handlers/
│   ├── models/
│   ├── go.mod
│   ├── Dockerfile
│   └── .dockerignore
│
├── product-service/       # Python Product Service
│   ├── app.py
│   ├── models/
│   ├── routes/
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .dockerignore
│
├── order-service/         # Node.js Order Service
│   ├── src/
│   ├── package.json
│   ├── Dockerfile
│   └── .dockerignore
│
├── docker-compose.yml     # Local development setup
├── .env.example          # Environment variables template
└── README.md             # This file
```

## Communication Patterns

### Synchronous (REST)
- API Gateway → Services: HTTP REST calls
- Order Service → User/Product Services: REST calls for validation

### Asynchronous (Future Enhancement)
- Message Queue (RabbitMQ/Kafka) for:
  - Order creation events
  - Inventory updates
  - Email notifications
  - Audit logs

## Design Patterns Used

1. **API Gateway Pattern**: Single entry point
2. **Database per Service**: Each service owns its data
3. **Service Discovery**: Environment-based configuration
4. **Circuit Breaker**: Graceful failure handling (to implement)
5. **Health Check Pattern**: All services expose /health endpoints

## Technology Choices

| Service | Language | Framework | Database | Port |
|---------|----------|-----------|----------|------|
| API Gateway | Node.js | Express | - | 3000 |
| User Service | Go | Gin | PostgreSQL | 4001 |
| Product Service | Python | Flask | PostgreSQL | 4002 |
| Order Service | Node.js | Express | PostgreSQL | 4003 |

## Next Steps

1. Run the services locally with Docker Compose
2. Test the APIs using Postman/curl
3. Implement the DevOps tasks listed above
4. Set up your CI/CD pipeline
5. Deploy to cloud (AWS/GCP/Azure)

## License

MIT

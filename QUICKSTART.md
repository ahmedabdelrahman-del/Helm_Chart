# Quick Start Guide

## 🚀 Running the Services

### Option 1: Docker Compose (Recommended)

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

### Option 2: Manual Setup

1. Start PostgreSQL databases (3 separate instances)
2. Install dependencies for each service
3. Run each service individually

## 🧪 Testing the APIs

### 1. Register a User

```bash
curl -X POST http://localhost:3000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123",
    "first_name": "John",
    "last_name": "Doe"
  }'
```

### 2. Login

```bash
curl -X POST http://localhost:3000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": "user-uuid",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe"
}
```

Save the token for authenticated requests!

### 3. Create a Product

```bash
TOKEN="your-jwt-token-here"

curl -X POST http://localhost:3000/api/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Laptop",
    "description": "High-performance laptop",
    "price": 999.99,
    "stock_quantity": 50,
    "category": "Electronics",
    "image_url": "https://example.com/laptop.jpg"
  }'
```

### 4. Get All Products

```bash
curl http://localhost:3000/api/products
```

### 5. Search Products

```bash
curl "http://localhost:3000/api/products/search?q=laptop"
```

### 6. Add to Cart

```bash
curl -X POST http://localhost:3000/api/orders/cart/USER_ID/items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "product_id": "PRODUCT_ID",
    "quantity": 2
  }'
```

### 7. View Cart

```bash
curl http://localhost:3000/api/orders/cart/USER_ID \
  -H "Authorization: Bearer $TOKEN"
```

### 8. Create Order

```bash
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "user_id": "USER_ID",
    "items": [
      {
        "product_id": "PRODUCT_ID",
        "quantity": 2
      }
    ]
  }'
```

### 9. Get Order Details

```bash
curl http://localhost:3000/api/orders/ORDER_ID \
  -H "Authorization: Bearer $TOKEN"
```

### 10. Get User's Orders

```bash
curl http://localhost:3000/api/orders/user/USER_ID \
  -H "Authorization: Bearer $TOKEN"
```

## 📊 Service Health Checks

```bash
# API Gateway
curl http://localhost:3000/health

# User Service
curl http://localhost:4001/health

# Product Service
curl http://localhost:4002/health

# Order Service
curl http://localhost:4003/health
```

## 🔍 Monitoring Logs

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f api-gateway
docker-compose logs -f user-service
docker-compose logs -f product-service
docker-compose logs -f order-service
```

## 🛠️ Troubleshooting

### Services won't start?

```bash
# Check Docker containers
docker-compose ps

# Check logs
docker-compose logs

# Restart services
docker-compose restart

# Rebuild images
docker-compose build --no-cache
docker-compose up -d
```

### Database connection issues?

```bash
# Connect to database container
docker exec -it postgres-users psql -U postgres -d users_db

# Check database tables
\dt

# Exit psql
\q
```

### Port conflicts?

Edit `docker-compose.yml` and change the external port mappings:

```yaml
ports:
  - "3001:3000"  # Change 3000 to 3001
```

## 🎯 Next Steps

Now that your microservices are running, you can:

1. **Implement CI/CD**: Set up Jenkins, GitHub Actions, or GitLab CI
2. **Deploy to Kubernetes**: Create K8s manifests and Helm charts
3. **Add Monitoring**: Integrate Prometheus and Grafana
4. **Set up Logging**: Configure ELK/EFK stack
5. **Implement Service Mesh**: Add Istio or Linkerd
6. **Create Terraform**: Infrastructure as Code for cloud deployment
7. **Add Message Queue**: Integrate RabbitMQ or Kafka
8. **Implement Caching**: Add Redis for performance
9. **Security Hardening**: Add OAuth2, rate limiting, WAF
10. **Load Testing**: Use k6, JMeter, or Gatling

Have fun applying DevOps practices! 🚀

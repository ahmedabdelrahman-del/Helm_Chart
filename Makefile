.PHONY: help build up down logs clean test

help:
	@echo "E-Commerce Microservices - Available Commands:"
	@echo ""
	@echo "  make build          - Build all Docker images"
	@echo "  make up             - Start all services"
	@echo "  make down           - Stop all services"
	@echo "  make logs           - View logs from all services"
	@echo "  make logs-gateway   - View API Gateway logs"
	@echo "  make logs-user      - View User Service logs"
	@echo "  make logs-product   - View Product Service logs"
	@echo "  make logs-order     - View Order Service logs"
	@echo "  make ps             - Show running containers"
	@echo "  make clean          - Remove all containers and volumes"
	@echo "  make restart        - Restart all services"
	@echo "  make health         - Check health of all services"
	@echo ""

build:
	@echo "Building all Docker images..."
	docker-compose build

up:
	@echo "Starting all services..."
	docker-compose up -d
	@echo ""
	@echo "Services starting..."
	@echo "API Gateway: http://localhost:3000"
	@echo "User Service: http://localhost:4001"
	@echo "Product Service: http://localhost:4002"
	@echo "Order Service: http://localhost:4003"
	@echo ""
	@echo "Run 'make logs' to view logs"
	@echo "Run 'make health' to check service health"

down:
	@echo "Stopping all services..."
	docker-compose down

logs:
	docker-compose logs -f

logs-gateway:
	docker-compose logs -f api-gateway

logs-user:
	docker-compose logs -f user-service

logs-product:
	docker-compose logs -f product-service

logs-order:
	docker-compose logs -f order-service

ps:
	docker-compose ps

clean:
	@echo "Removing all containers, volumes, and networks..."
	docker-compose down -v
	@echo "Cleaned up!"

restart:
	@echo "Restarting all services..."
	docker-compose restart

health:
	@echo "Checking service health..."
	@echo ""
	@echo "API Gateway:"
	@curl -s http://localhost:3000/health | jq || echo "Not available"
	@echo ""
	@echo "User Service:"
	@curl -s http://localhost:4001/health | jq || echo "Not available"
	@echo ""
	@echo "Product Service:"
	@curl -s http://localhost:4002/health | jq || echo "Not available"
	@echo ""
	@echo "Order Service:"
	@curl -s http://localhost:4003/health | jq || echo "Not available"

rebuild:
	@echo "Rebuilding and restarting all services..."
	docker-compose down
	docker-compose build --no-cache
	docker-compose up -d
	@echo "Services rebuilt and started!"

test-api:
	@echo "Testing API endpoints..."
	@echo ""
	@echo "1. Registering a test user..."
	@curl -s -X POST http://localhost:3000/api/users/register \
		-H "Content-Type: application/json" \
		-d '{"email":"test@example.com","password":"test123","first_name":"Test","last_name":"User"}' | jq
	@echo ""
	@echo "2. Logging in..."
	@curl -s -X POST http://localhost:3000/api/users/login \
		-H "Content-Type: application/json" \
		-d '{"email":"test@example.com","password":"test123"}' | jq

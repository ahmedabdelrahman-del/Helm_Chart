package main

import (
	"log"
	"os"

	"github.com/ahmedabdelrahman-del/user-service/handlers"
	"github.com/ahmedabdelrahman-del/user-service/models"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	godotenv.Load()

	// Initialize database
	models.InitDB()
	defer models.DB.Close()

	// Create Gin router
	router := gin.Default()

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":    "healthy",
			"service":   "user-service",
			"timestamp": "now",
		})
	})

	// Auth routes
	router.POST("/register", handlers.Register)
	router.POST("/login", handlers.Login)

	// User routes (protected)
	router.GET("/users/:id", handlers.AuthMiddleware(), handlers.GetUser)
	router.PUT("/users/:id", handlers.AuthMiddleware(), handlers.UpdateUser)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "4001"
	}

	log.Printf("User Service starting on port %s", port)
	router.Run(":" + port)
}

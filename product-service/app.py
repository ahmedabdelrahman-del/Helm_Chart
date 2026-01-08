from flask import Flask, jsonify, request
from flask_cors import CORS
import os
from dotenv import load_dotenv
from models.database import init_db
from routes.product_routes import product_bp

load_dotenv()

app = Flask(__name__)
CORS(app)

# Initialize database
init_db()

# Register blueprints
app.register_blueprint(product_bp)

# Health check
@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'service': 'product-service'
    }), 200

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 4002))
    app.run(host='0.0.0.0', port=port, debug=os.getenv('DEBUG', 'False') == 'True')

from flask import Blueprint, jsonify, request
from models.database import get_db_connection
from psycopg2.extras import RealDictCursor
import uuid
from decimal import Decimal

product_bp = Blueprint('products', __name__)

@product_bp.route('/products', methods=['GET'])
def get_products():
    """Get all products with optional filtering"""
    category = request.args.get('category')
    
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    if category:
        cursor.execute(
            "SELECT * FROM products WHERE category = %s ORDER BY created_at DESC",
            (category,)
        )
    else:
        cursor.execute("SELECT * FROM products ORDER BY created_at DESC")
    
    products = cursor.fetchall()
    cursor.close()
    conn.close()
    
    # Convert Decimal to float for JSON serialization
    for product in products:
        product['price'] = float(product['price'])
    
    return jsonify(products), 200

@product_bp.route('/products/<product_id>', methods=['GET'])
def get_product(product_id):
    """Get a single product by ID"""
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    cursor.execute("SELECT * FROM products WHERE id = %s", (product_id,))
    product = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    if not product:
        return jsonify({'error': 'Product not found'}), 404
    
    product['price'] = float(product['price'])
    return jsonify(product), 200

@product_bp.route('/products/search', methods=['GET'])
def search_products():
    """Search products by name or description"""
    query = request.args.get('q', '')
    
    if not query:
        return jsonify({'error': 'Query parameter is required'}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    search_pattern = f'%{query}%'
    cursor.execute(
        """
        SELECT * FROM products 
        WHERE name ILIKE %s OR description ILIKE %s 
        ORDER BY created_at DESC
        """,
        (search_pattern, search_pattern)
    )
    
    products = cursor.fetchall()
    cursor.close()
    conn.close()
    
    for product in products:
        product['price'] = float(product['price'])
    
    return jsonify(products), 200

@product_bp.route('/products', methods=['POST'])
def create_product():
    """Create a new product (admin only)"""
    data = request.get_json()
    
    # Validate required fields
    required_fields = ['name', 'price', 'stock_quantity']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    
    product_id = str(uuid.uuid4())
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        INSERT INTO products (id, name, description, price, stock_quantity, category, image_url)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        """,
        (
            product_id,
            data['name'],
            data.get('description', ''),
            data['price'],
            data['stock_quantity'],
            data.get('category', 'General'),
            data.get('image_url', '')
        )
    )
    
    conn.commit()
    cursor.close()
    conn.close()
    
    return jsonify({
        'id': product_id,
        'message': 'Product created successfully'
    }), 201

@product_bp.route('/products/<product_id>', methods=['PUT'])
def update_product(product_id):
    """Update a product (admin only)"""
    data = request.get_json()
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Check if product exists
    cursor.execute("SELECT id FROM products WHERE id = %s", (product_id,))
    if not cursor.fetchone():
        cursor.close()
        conn.close()
        return jsonify({'error': 'Product not found'}), 404
    
    # Update product
    cursor.execute(
        """
        UPDATE products 
        SET name = %s, description = %s, price = %s, stock_quantity = %s, 
            category = %s, image_url = %s, updated_at = CURRENT_TIMESTAMP
        WHERE id = %s
        """,
        (
            data.get('name'),
            data.get('description'),
            data.get('price'),
            data.get('stock_quantity'),
            data.get('category'),
            data.get('image_url'),
            product_id
        )
    )
    
    conn.commit()
    cursor.close()
    conn.close()
    
    return jsonify({'message': 'Product updated successfully'}), 200

@product_bp.route('/products/<product_id>', methods=['DELETE'])
def delete_product(product_id):
    """Delete a product (admin only)"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("DELETE FROM products WHERE id = %s", (product_id,))
    
    if cursor.rowcount == 0:
        cursor.close()
        conn.close()
        return jsonify({'error': 'Product not found'}), 404
    
    conn.commit()
    cursor.close()
    conn.close()
    
    return jsonify({'message': 'Product deleted successfully'}), 200

from flask import Flask, render_template, request, jsonify, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime, timedelta
from collections import defaultdict
import calendar
import locale
import os
from werkzeug.utils import secure_filename

app = Flask(__name__)
# Enable CORS for all routes (allows Flutter Web to talk to Python)
CORS(app)

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///ana_mercado_v6.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = 'your-secret-key-here'
app.config['UPLOAD_FOLDER'] = os.path.join('static', 'uploads')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Ensure upload directory exists
os.makedirs(os.path.join(app.root_path, app.config['UPLOAD_FOLDER']), exist_ok=True)

db = SQLAlchemy(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'
login_manager.login_message = "Por favor, faça login para acessar esta página."
login_manager.login_message_category = "warning"

# Models
import uuid
from functools import wraps

# ... (imports)

# Security Decorator
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header.split(" ")[1]
        
        if not token:
            return jsonify({'error': 'Token de autenticação ausente'}), 401
        
        try:
            current_api_user = User.query.filter_by(api_token=token).first()
            if not current_api_user:
                raise Exception('Token inválido')
        except:
            return jsonify({'error': 'Token inválido ou expirado'}), 401
            
        return f(current_api_user, *args, **kwargs)
    return decorated

# ... (app config)

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(120), nullable=False)
    profile_pic = db.Column(db.String(255), nullable=True)
    display_name = db.Column(db.String(100), nullable=True)
    api_token = db.Column(db.String(100), unique=True, nullable=True)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
        # Generate token on password set/change if not exists
        if not self.api_token:
            self.api_token = str(uuid.uuid4())

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

# ... (User methods)


class UserSettings(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    dark_mode = db.Column(db.Boolean, default=False)
    notifications_enabled = db.Column(db.Boolean, default=True)

class ShoppingList(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_completed = db.Column(db.Boolean, default=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True) # Nullable for backward compatibility/admin
    items = db.relationship('Item', backref='shopping_list', lazy=True, cascade="all, delete-orphan")
    
    @property
    def total_value(self):
        return sum(item.total for item in self.items)

class Item(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    quantity = db.Column(db.Integer, default=1)
    price = db.Column(db.Float, default=0.0)
    total = db.Column(db.Float, default=0.0)
    is_checked = db.Column(db.Boolean, default=False)
    category = db.Column(db.String(50), default='Outros')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    list_id = db.Column(db.Integer, db.ForeignKey('shopping_list.id'), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'quantity': self.quantity,
            'price': self.price,
            'total': self.total,
            'is_checked': self.is_checked,
            'category': self.category
        }

class Category(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)
    color = db.Column(db.String(20), default='#9E9E9E') # Hex Code
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True) # Nullable = System Default

class Notification(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    message = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_read = db.Column(db.Boolean, default=False) # For future use per user
    
    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'message': self.message,
            'created_at': self.created_at.isoformat()
        }

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

# API Routes
@app.route('/api/login', methods=['POST'])
def api_login_endpoint():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    
    user = User.query.filter_by(username=username).first()
    
    if user and user.check_password(password):
        # Ensure token exists
        if not user.api_token:
            user.api_token = str(uuid.uuid4())
            db.session.commit()
            
        return jsonify({
            'message': 'Login successful', 
            'user_id': user.id,
            'username': user.username,
            'profile_pic': user.profile_pic,
            'display_name': user.display_name,
            'token': user.api_token
        }), 200
    
    return jsonify({'error': 'Credenciais inválidas'}), 401

@app.route('/api/register', methods=['POST'])
def api_register():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({'error': 'Dados incompletos'}), 400
    
    if User.query.filter_by(username=username).first():
        return jsonify({'error': 'Usuário já existe'}), 409

    new_user = User(username=username)
    new_user.set_password(password)
    new_user.api_token = str(uuid.uuid4())
    db.session.add(new_user)
    db.session.commit()
    
    return jsonify({'message': 'Usuário criado com sucesso', 'user_id': new_user.id, 'token': new_user.api_token}), 201

@app.route('/api/lists', methods=['GET'])
@token_required
def api_get_lists(current_api_user):
    completed_str = request.args.get('completed', 'false')
    is_completed = completed_str.lower() == 'true'

    # Filter strictly by current_api_user
    lists = ShoppingList.query.filter_by(is_completed=is_completed, user_id=current_api_user.id).order_by(ShoppingList.created_at.desc()).all()
    return jsonify([{
        'id': l.id, 
        'name': l.name, 
        'total_value': l.total_value,
        'created_at': l.created_at.isoformat(),
        'is_completed': l.is_completed
    } for l in lists])

@app.route('/api/lists', methods=['POST'])
@token_required
def api_create_list(current_api_user):
    data = request.get_json()
    name = data.get('name', '').strip()
    
    if name:
        shopping_list = ShoppingList(name=name, user_id=current_api_user.id)
        db.session.add(shopping_list)
        db.session.commit()
        return jsonify({'message': 'Lista criada', 'id': shopping_list.id}), 201
    return jsonify({'error': 'Dados inválidos'}), 400

@app.route('/api/lists/<int:list_id>', methods=['GET'])
@token_required
def api_get_list_details(current_api_user, list_id):
    shopping_list = ShoppingList.query.get_or_404(list_id)
    
    # IDOR Check
    if shopping_list.user_id != current_api_user.id:
        return jsonify({'error': 'Acesso negado'}), 403
        
    return jsonify({
        'id': shopping_list.id,
        'name': shopping_list.name,
        'is_completed': shopping_list.is_completed,
        'items': [item.to_dict() for item in shopping_list.items]
    })

@app.route('/api/items', methods=['POST'])
@token_required
def api_add_item(current_api_user):
    data = request.get_json()
    list_id = data.get('list_id')
    name = data.get('name', '').strip()
    quantity = int(data.get('quantity', 1))
    price = float(data.get('price', 0))
    category = data.get('category', 'Outros')

    if not list_id:
        return jsonify({'error': 'ID da lista obrigatório'}), 400
        
    # Verify List Ownership
    shopping_list = ShoppingList.query.get(list_id)
    if not shopping_list or shopping_list.user_id != current_api_user.id:
        return jsonify({'error': 'Lista não encontrada ou acesso negado'}), 403

    if not name or price <= 0 or quantity <= 0:
        return jsonify({'error': 'Dados inválidos'}), 400

    item = Item(name=name, quantity=quantity, price=price, total=quantity*price, list_id=list_id, category=category)
    db.session.add(item)
    db.session.commit()
    return jsonify(item.to_dict()), 201

@app.route('/api/dashboard', methods=['GET'])
@token_required
def api_dashboard(current_api_user):
    month = request.args.get('month') # Optional: YYYY-MM
    
    # Base query for all items (for history) owned by user
    query = db.session.query(Item).join(ShoppingList).filter(
        (ShoppingList.user_id == current_api_user.id)
    )
    all_items = query.all()

    # Get user categories for colors
    user_categories = Category.query.filter(
        (Category.user_id == current_api_user.id) | (Category.user_id == None)
    ).all()
    
    category_colors = {cat.name: cat.color for cat in user_categories}
    default_colors = {
        'Alimentos': '#FF9800', # Orange
        'Limpeza': '#009688',   # Teal
        'Higiene': '#9C27B0',   # Purple
        'Feira Básica': '#795548', # Brown
        'Lanche/Petisco': '#E91E63', # Pink
        'Frutas': '#4CAF50',    # Green
        'Carne': '#F44336',     # Red
        'Bebida': '#2196F3',    # Blue
        'Outros': '#9E9E9E'     # Gray
    }

    # 1. Calculate Monthly History (Always All Time)
    monthly_spend = defaultdict(float)
    for item in all_items:
        month_key = item.created_at.strftime('%Y-%m')
        monthly_spend[month_key] += item.total

    # 2. Filter for Category Spend
    if month:
        # Filter items in python for simplicity or could do DB query
        cat_items = [i for i in all_items if i.created_at.strftime('%Y-%m') == month]
    else:
        cat_items = all_items

    category_spend = defaultdict(float)
    for item in cat_items:
        category_spend[item.category] += item.total

    # Format category data
    cat_data = []
    for cat, total in category_spend.items():
        # Prioritize default vibrant colors for system categories
        # Fallback to DB color (custom categories) or generic gray
        color = default_colors.get(cat, category_colors.get(cat, '#9E9E9E'))
        cat_data.append({
            'category': cat,
            'total': total,
            'color': color
        })

    return jsonify({
        'category_spend': cat_data,
        'monthly_spend': [{'month': k, 'total': v} for k, v in sorted(monthly_spend.items())]
    })

@app.route('/api/items/<int:item_id>', methods=['DELETE'])
@token_required
def api_delete_item(current_api_user, item_id):
    item = Item.query.get_or_404(item_id)
    
    # Security check: Ensure item belongs to a list owned by the current user
    if item.shopping_list.user_id != current_api_user.id:
        return jsonify({'error': 'Acesso negado'}), 403
    
    db.session.delete(item)
    db.session.commit()
    return '', 204

@app.route('/api/items/<int:item_id>/toggle', methods=['POST'])
@token_required
def api_toggle_item(current_api_user, item_id):
    item = Item.query.get_or_404(item_id)
    
    # Security check
    if item.shopping_list.user_id != current_api_user.id:
         return jsonify({'error': 'Acesso negado'}), 403

    item.is_checked = not item.is_checked
    db.session.commit()
    return jsonify(item.to_dict())

@app.route('/api/lists/<int:list_id>/complete', methods=['POST'])
@token_required
def api_complete_list(current_api_user, list_id):
    shopping_list = ShoppingList.query.get_or_404(list_id)
    
    if shopping_list.user_id != current_api_user.id:
        return jsonify({'error': 'Acesso negado'}), 403
        
    shopping_list.is_completed = True
    db.session.commit()
    return jsonify({'message': 'Lista finalizada'})

# Notification Routes (Public/Global for now, or Admin Only in future)
@app.route('/api/notifications', methods=['GET'])
@token_required
def api_get_notifications(current_api_user):
    # Optional: Filter notifications by user if needed
    notifications = Notification.query.order_by(Notification.created_at.desc()).all()
    return jsonify([n.to_dict() for n in notifications])

@app.route('/api/notifications', methods=['POST'])
def api_create_notification(): # Keep public or add Admin Check later
    data = request.get_json()
    title = data.get('title')
    message = data.get('message')
    
    if not title or not message:
        return jsonify({'error': 'Título e mensagem obrigatórios'}), 400
        
    notification = Notification(title=title, message=message)
    db.session.add(notification)
    db.session.commit()
    return jsonify(notification.to_dict()), 201

# Category Routes
@app.route('/api/categories', methods=['GET'])
@token_required
def api_get_categories(current_api_user):
    user_categories = Category.query.filter(
        (Category.user_id == current_api_user.id) | (Category.user_id == None)
    ).all()
    return jsonify([{
        'id': c.id, 
        'name': c.name, 
        'color': c.color,
        'is_custom': c.user_id is not None
    } for c in user_categories])

@app.route('/api/categories', methods=['POST'])
@token_required
def api_create_category(current_api_user):
    data = request.get_json()
    name = data.get('name')
    color = data.get('color', '#9E9E9E') # Default Gray

    if not name:
        return jsonify({'error': 'Nome obrigatório'}), 400
        
    category = Category(name=name, color=color, user_id=current_api_user.id)
    db.session.add(category)
    db.session.commit()
    return jsonify({'message': 'Categoria criada', 'id': category.id}), 201

@app.route('/api/categories/<int:cat_id>', methods=['PUT'])
@token_required
def api_update_category(current_api_user, cat_id):
    category = Category.query.get_or_404(cat_id)
    
    # Ownership Check (Can't edit system categories)
    if category.user_id != current_api_user.id:
        return jsonify({'error': 'Acesso negado (Categoria do Sistema)'}), 403
        
    data = request.get_json()
    if 'name' in data: category.name = data['name']
    if 'color' in data: category.color = data['color']
    
    db.session.commit()
    return jsonify({'message': 'Categoria atualizada'})

@app.route('/api/categories/<int:cat_id>', methods=['DELETE'])
@token_required
def api_delete_category(current_api_user, cat_id):
    category = Category.query.get_or_404(cat_id)
    
    if category.user_id != current_api_user.id:
        return jsonify({'error': 'Acesso negado'}), 403
        
    # Check usage? For now, allow delete (items might need fallback)
    # Ideally set items to 'Outros' or restrict delete
    items = Item.query.filter_by(category=category.name).all() # This logic depends on name matching
    for item in items:
        item.category = 'Outros' # Fallback
        
    db.session.delete(category)
    db.session.commit()
    return '', 204

# User Management Routes
@app.route('/api/users/<int:user_id>', methods=['PUT'])
@token_required
def api_update_user(current_api_user, user_id):
    if current_api_user.id != user_id:
        return jsonify({'error': 'Acesso negado'}), 403
    
    data = request.get_json()
    display_name = data.get('display_name')
    
    if display_name is not None:
        current_api_user.display_name = display_name
        db.session.commit()
        return jsonify({'message': 'Perfil atualizado', 'display_name': display_name})
    
    return jsonify({'error': 'Dados inválidos'}), 400

@app.route('/api/users/<int:user_id>/avatar', methods=['POST'])
@token_required
def api_upload_avatar(current_api_user, user_id):
    if current_api_user.id != user_id:
        return jsonify({'error': 'Acesso negado'}), 403
        
    if 'file' not in request.files:
        return jsonify({'error': 'Nenhum arquivo enviado'}), 400
        
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'Nenhum arquivo selecionado'}), 400
        
    if file:
        filename = secure_filename(f"user_{user_id}_{int(datetime.now().timestamp())}_{file.filename}")
        file.save(os.path.join(app.root_path, app.config['UPLOAD_FOLDER'], filename))
        
        # Save relative path
        relative_path = f"static/uploads/{filename}"
        current_api_user.profile_pic = relative_path
        db.session.commit()
        
        return jsonify({'message': 'Avatar atualizado', 'profile_pic': relative_path})

@app.route('/api/users/<int:user_id>/change_credentials', methods=['POST'])
@token_required
def api_change_credentials(current_api_user, user_id):
    if current_api_user.id != user_id:
        return jsonify({'error': 'Acesso negado'}), 403
    
    data = request.get_json()
    current_password = data.get('current_password')
    new_username = data.get('new_username')
    new_password = data.get('new_password')
    
    if not current_api_user.check_password(current_password):
        return jsonify({'error': 'Senha atual incorreta'}), 401
        
    if new_username:
        if User.query.filter(User.username == new_username, User.id != user_id).first():
             return jsonify({'error': 'Nome de usuário já existe'}), 409
        current_api_user.username = new_username
        
    if new_password:
        current_api_user.set_password(new_password)
        
    db.session.commit()
    return jsonify({'message': 'Credenciais atualizadas', 'username': current_api_user.username})

# New Route for Mobile Preview
@app.route('/preview')
@login_required
def preview():
    return render_template('preview.html')

def init_db():
    with app.app_context():
        # Create all tables only if they don't exist
        db.create_all()
        # Initialize settings if needed
        if not UserSettings.query.first():
            settings = UserSettings()
            db.session.add(settings)
        
        # Initialize Admin User (keep for legacy)
        if not User.query.filter_by(username='admin').first():
            admin = User(username='admin')
            admin.set_password('admin')
            admin.api_token = str(uuid.uuid4())
            db.session.add(admin)

        # Initialize Specific User
        specific_user = User.query.filter_by(username='bismakgustavo3@gmail.com').first()
        if not specific_user:
            specific_user = User(username='bismakgustavo3@gmail.com')
            specific_user.set_password('Bismak2006@')
            specific_user.api_token = str(uuid.uuid4())
            db.session.add(specific_user)
        else:
            # Ensure existing user has token
            if not specific_user.api_token:
                specific_user.api_token = str(uuid.uuid4())
            
        db.session.commit()

if __name__ == '__main__':
    init_db()  # Initialize database
    app.run(debug=True, host='0.0.0.0', port=5000)
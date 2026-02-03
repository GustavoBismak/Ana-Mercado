from flask import Flask, render_template, request, jsonify, redirect, url_for, flash, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime, timedelta, timezone
from collections import defaultdict
import calendar
import locale
import os
import random
from werkzeug.utils import secure_filename

basedir = os.path.abspath(os.path.dirname(__file__))
app = Flask(__name__, 
            static_folder=os.path.join(basedir, 'mobile_app', 'build', 'web'), 
            template_folder=os.path.join(basedir, 'templates'))
# Enable CORS for all routes (allows Flutter Web to talk to Python)
CORS(app)

def get_brasilia_time():
    return datetime.now(timezone(timedelta(hours=-3)))

@app.route('/')
def serve_flutter_app():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/<path:path>')
def catch_all(path):
    print(f"DEBUG: Requesting path -> {path}")
    if path.startswith('api'):
        return jsonify({'error': 'Not found'}), 404
    
    # Check if file exists in static folder (build/web)
    full_path = os.path.join(app.static_folder, path)
    if os.path.exists(full_path) and os.path.isfile(full_path):
        print(f"DEBUG: Serving file -> {full_path}")
        return send_from_directory(app.static_folder, path)

    # Otherwise return index.html for Flutter routing
    print(f"DEBUG: Serving index.html for -> {path}")
    return send_from_directory(app.static_folder, 'index.html')

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///ana_mercado_v6.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', os.urandom(24).hex())
app.config['UPLOAD_FOLDER'] = os.path.join('static', 'uploads')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Ensure upload directory exists
os.makedirs(os.path.join(app.root_path, app.config['UPLOAD_FOLDER']), exist_ok=True)

@app.route('/static/uploads/<path:filename>')
def serve_uploads(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

db = SQLAlchemy(app)
login_manager = LoginManager(app)
login_manager.login_view = 'admin_login'
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
    created_at = db.Column(db.DateTime, default=get_brasilia_time)
    is_completed = db.Column(db.Boolean, default=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True) # Nullable for backward compatibility/admin
    items = db.relationship('Item', backref='shopping_list', lazy=True, cascade="all, delete-orphan")
    
    @property
    def total_value(self):
        # Only sum items that are marked as bought (checked)
        return sum(item.total for item in self.items if item.is_checked)

    @property
    def total_unchecked(self):
        # Sum items that are NOT marked as bought
        return sum(item.total for item in self.items if not item.is_checked)

    @property
    def total_full(self):
        # Total sum of everything
        return sum(item.total for item in self.items)

class Item(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    quantity = db.Column(db.Integer, default=1)
    price = db.Column(db.Float, default=0.0)
    total = db.Column(db.Float, default=0.0)
    is_checked = db.Column(db.Boolean, default=False)
    category = db.Column(db.String(50), default='Outros')
    created_at = db.Column(db.DateTime, default=get_brasilia_time)
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
    created_at = db.Column(db.DateTime, default=get_brasilia_time)
    is_read = db.Column(db.Boolean, default=False) # For future use per user
    
    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'message': self.message,
            'created_at': self.created_at.isoformat()
        }

class Suggestion(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    content = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=get_brasilia_time)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True)
    
    user = db.relationship('User', backref=db.backref('suggestions', lazy=True))

    def to_dict(self):
        return {
            'id': self.id,
            'content': self.content,
            'created_at': self.created_at.isoformat(),
            'username': self.user.username if self.user else 'Anônimo'
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
    
    print(f"\n--- DEBUG LOGIN ---")
    print(f"Attempting login for: {username}")
    
    user = User.query.filter_by(username=username).first()
    
    if user:
        if user.check_password(password):
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
        else:
            return jsonify({'error': 'Senha incorreta'}), 401
    else:
        return jsonify({'error': 'Usuário não encontrado'}), 401

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
        'total_unchecked': l.total_unchecked,
        'total_full': l.total_full,
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
    # FILTER: Only show bought items in dashboard
    query = db.session.query(Item).join(ShoppingList).filter(
        (ShoppingList.user_id == current_api_user.id) & (Item.is_checked == True)
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
        # Use color from DB (system or custom), fallback to gray
        color = category_colors.get(cat, '#9E9E9E')
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

@app.route('/api/items/<int:item_id>', methods=['PUT'])
@token_required
def api_update_item(current_api_user, item_id):
    item = Item.query.get_or_404(item_id)
    
    # Security check
    if item.shopping_list.user_id != current_api_user.id:
        return jsonify({'error': 'Acesso negado'}), 403
        
    data = request.get_json()
    
    if 'name' in data: item.name = data['name'].strip()
    if 'quantity' in data: item.quantity = int(data['quantity'])
    if 'price' in data: item.price = float(data['price'])
    if 'category' in data: item.category = data['category']
    
    # Recalculate total
    item.total = item.quantity * item.price
    
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
    notifications = Notification.query.order_by(Notification.created_at.desc()).all()
    return jsonify([n.to_dict() for n in notifications])

@app.route('/admin/notifications')
@login_required
def admin_notifications_page():
    # Security: Only allow specific admins
    allowed_users = ['admin', 'bismakgustavo3@gmail.com']
    
    if current_user.username not in allowed_users:
        return "Acesso Negado: Você não tem permissão para acessar esta página.", 403
        
    if current_user.username not in allowed_users:
        return "Acesso Negado: Você não tem permissão para acessar esta página.", 403
        
    return render_template('admin_notifications.html')

@app.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    if current_user.is_authenticated:
        return redirect(url_for('admin_notifications_page'))
        
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        user = User.query.filter_by(username=username).first()
        
        if user and user.check_password(password):
            login_user(user)
            # Security check for admin page access (optional but good UI)
            allowed_users = ['admin', 'bismakgustavo3@gmail.com']
            if user.username in allowed_users:
                 return redirect(url_for('admin_notifications_page'))
            else:
                 flash("Login realizado, mas você não é admin.", "warning")
        else:
            flash("Credenciais inválidas. Tente novamente.", "danger")
            
    return render_template('admin_login.html')

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

@app.route('/api/suggestions', methods=['POST'])
@token_required
def api_create_suggestion(current_api_user):
    data = request.get_json()
    content = data.get('content')
    
    if not content:
        return jsonify({'error': 'Conteúdo da sugestão é obrigatório'}), 400
        
    suggestion = Suggestion(content=content, user_id=current_api_user.id)
    db.session.add(suggestion)
    db.session.commit()
    
    return jsonify({'message': 'Sugestão enviada com sucesso!'}), 201

@app.route('/admin/suggestions')
@login_required
def admin_suggestions_page():
    # Security: Only allow specific admins
    allowed_users = ['admin', 'bismakgustavo3@gmail.com']
    
    if current_user.username not in allowed_users:
        return "Acesso Negado: Você não tem permissão para acessar esta página.", 403
        
    suggestions = Suggestion.query.order_by(Suggestion.created_at.desc()).all()
    return render_template('admin_suggestions.html', suggestions=suggestions)

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
    
    # curated list of vibrant/pastel colors excluding gray
    nice_colors = [
        '#EF5350', '#EC407A', '#AB47BC', '#7E57C2', '#5C6BC0', 
        '#42A5F5', '#29B6F6', '#26C6DA', '#26A69A', '#66BB6A', 
        '#9CCC65', '#D4E157', '#FFEE58', '#FFCA28', '#FFA726', 
        '#FF7043', '#8D6E63', '#78909C'
    ]
    
    # If color not provided or is default gray, pick random
    provided_color = data.get('color')
    if not provided_color or provided_color == '#9E9E9E':
        color = random.choice(nice_colors)
    else:
        color = provided_color

    if not name:
        return jsonify({'error': 'Nome obrigatório'}), 400
        
    category = Category(name=name, color=color, user_id=current_api_user.id)
    db.session.add(category)
    db.session.commit()
    return jsonify({'message': 'Categoria criada', 'id': category.id, 'color': color}), 201

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
        
        # Initialize Default Categories
        default_categories = [
            {'name': 'Alimentos', 'color': '#FF9800'}, # Orange
            {'name': 'Limpeza', 'color': '#009688'},   # Teal
            {'name': 'Higiene', 'color': '#9C27B0'},   # Purple
            {'name': 'Feira Básica', 'color': '#795548'}, # Brown
            {'name': 'Lanche/Petisco', 'color': '#E91E63'}, # Pink
            {'name': 'Frutas', 'color': '#4CAF50'},    # Green
            {'name': 'Carne', 'color': '#F44336'},     # Red
            {'name': 'Bebida', 'color': '#2196F3'},    # Blue
            {'name': 'Outros', 'color': '#9E9E9E'}     # Gray
        ]
        
        for cat_data in default_categories:
            if not Category.query.filter_by(name=cat_data['name'], user_id=None).first():
                cat = Category(name=cat_data['name'], color=cat_data['color'], user_id=None)
                db.session.add(cat)
            
        db.session.commit()

# Initialize DB immediately (so Gunicorn creates tables)
try:
    init_db()
except Exception as e:
    print(f"Error initializing DB: {e}")

if __name__ == '__main__':
    # SSL Configuration
    cert_path = '/etc/letsencrypt/live/anamercado.duckdns.org/fullchain.pem'
    key_path = '/etc/letsencrypt/live/anamercado.duckdns.org/privkey.pem'
    
    context = None
    default_port = 5000

    if os.path.exists(cert_path) and os.path.exists(key_path):
        context = (cert_path, key_path)
        default_port = 443
        print("Running in HTTPS mode!")
    
    port = int(os.environ.get('PORT', default_port))
    app.run(debug=False, host='0.0.0.0', port=port, ssl_context=context)
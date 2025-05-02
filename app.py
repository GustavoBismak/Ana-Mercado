from flask import Flask, render_template, request, jsonify, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime, timedelta
from collections import defaultdict
import calendar
import locale
import os
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///ana_mercado.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = 'your-secret-key-here'
app.config['UPLOAD_FOLDER'] = os.path.join('static', 'uploads')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Ensure upload directory exists
os.makedirs(os.path.join(app.root_path, app.config['UPLOAD_FOLDER']), exist_ok=True)

db = SQLAlchemy(app)

# Models
class ShoppingList(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_completed = db.Column(db.Boolean, default=False)
    items = db.relationship('Item', backref='shopping_list', lazy=True, cascade='all, delete-orphan')

    @property
    def total_value(self):
        return sum(item.total for item in self.items)

class Item(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    quantity = db.Column(db.Integer, nullable=False, default=1)
    price = db.Column(db.Float, nullable=False)
    total = db.Column(db.Float, nullable=False)
    is_checked = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    list_id = db.Column(db.Integer, db.ForeignKey('shopping_list.id', ondelete='CASCADE'), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'quantity': self.quantity,
            'price': self.price,
            'total': self.total,
            'is_checked': self.is_checked
        }

class UserSettings(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    profile_pic = db.Column(db.String(255))
    theme_color = db.Column(db.String(7), default='#0d6efd')
    font_family = db.Column(db.String(50), default='Poppins')
    font_size = db.Column(db.Integer, default=14)

# Routes
@app.route('/')
def index():
    lists = ShoppingList.query.filter_by(is_completed=False).order_by(ShoppingList.created_at.desc()).all()
    settings = UserSettings.query.first()
    if not settings:
        settings = UserSettings()
        db.session.add(settings)
        db.session.commit()
    return render_template('index.html', lists=lists, settings=settings)

@app.route('/create_list', methods=['POST'])
def create_list():
    name = request.form.get('name', '').strip()
    if name:
        shopping_list = ShoppingList(name=name)
        db.session.add(shopping_list)
        db.session.commit()
        flash('Lista criada com sucesso!', 'success')
    return redirect(url_for('index'))

@app.route('/list/<int:list_id>')
def view_list(list_id):
    shopping_list = ShoppingList.query.get_or_404(list_id)
    settings = UserSettings.query.first()
    return render_template('list.html', shopping_list=shopping_list, settings=settings)

@app.route('/add_item/<int:list_id>', methods=['POST'])
def add_item(list_id):
    try:
        shopping_list = ShoppingList.query.get_or_404(list_id)
        name = request.form.get('name').strip()
        quantity = int(request.form.get('quantity', 1))
        price = float(request.form.get('price'))
        
        if not name or price <= 0 or quantity <= 0:
            flash('Por favor, preencha todos os campos corretamente.', 'error')
            return redirect(url_for('view_list', list_id=list_id))
        
        total = quantity * price
        
        item = Item(
            name=name,
            quantity=quantity,
            price=price,
            total=total,
            list_id=list_id
        )
        
        db.session.add(item)
        db.session.commit()
        flash('Item adicionado com sucesso!', 'success')
        
    except Exception as e:
        flash('Erro ao adicionar item.', 'error')
        
    return redirect(url_for('view_list', list_id=list_id))

@app.route('/toggle_item/<int:item_id>', methods=['POST'])
def toggle_item(item_id):
    try:
        item = Item.query.get_or_404(item_id)
        item.is_checked = not item.is_checked
        db.session.commit()
        return redirect(url_for('view_list', list_id=item.list_id))
    except Exception as e:
        return redirect(url_for('index'))

@app.route('/complete_list/<int:list_id>', methods=['POST'])
def complete_list(list_id):
    try:
        shopping_list = ShoppingList.query.get_or_404(list_id)
        shopping_list.is_completed = True
        db.session.commit()
        flash('Compra finalizada com sucesso!', 'success')
    except Exception as e:
        flash('Erro ao finalizar compra.', 'error')
    return redirect(url_for('index'))

@app.route('/history')
def history():
    try:
        locale.setlocale(locale.LC_ALL, 'pt_BR.UTF-8')
    except:
        pass
    
    selected_month = request.args.get('month', datetime.now().strftime('%Y-%m'))
    year, month = map(int, selected_month.split('-'))
    
    start_date = datetime(year, month, 1)
    if month == 12:
        end_date = datetime(year + 1, 1, 1)
    else:
        end_date = datetime(year, month + 1, 1)
    
    completed_lists = ShoppingList.query.filter(
        ShoppingList.is_completed == True,
        ShoppingList.created_at >= start_date,
        ShoppingList.created_at < end_date
    ).order_by(ShoppingList.created_at.desc()).all()
    
    month_total = sum(lst.total_value for lst in completed_lists)
    
    months = []
    current_date = datetime.now()
    for i in range(12):
        date = current_date - timedelta(days=30*i)
        try:
            month_name = date.strftime('%B').capitalize()
        except:
            month_name = calendar.month_name[date.month].capitalize()
        
        months.append({
            'value': date.strftime('%Y-%m'),
            'label': f'{month_name} {date.year}'
        })
    
    settings = UserSettings.query.first()
    return render_template(
        'history.html',
        lists=completed_lists,
        month_total=month_total,
        months=months,
        current_month=selected_month,
        settings=settings
    )

@app.route('/update_settings', methods=['POST'])
def update_settings():
    try:
        settings = UserSettings.query.first()
        if not settings:
            settings = UserSettings()
            db.session.add(settings)

        if 'profile_pic' in request.files:
            file = request.files['profile_pic']
            if file and file.filename:
                filename = secure_filename(file.filename)
                filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                file.save(os.path.join(app.root_path, filepath))
                # Salvar apenas o caminho relativo a 'static' e garantir barra '/'
                settings.profile_pic = 'uploads/' + filename.replace('\\', '/').replace('\\', '/')

        if 'theme_color' in request.form:
            settings.theme_color = request.form['theme_color']
        if 'font_family' in request.form:
            settings.font_family = request.form['font_family']
        if 'font_size' in request.form:
            settings.font_size = int(request.form['font_size'])

        db.session.commit()
        flash('Configurações atualizadas com sucesso!', 'success')
    except Exception as e:
        flash('Erro ao atualizar configurações.', 'error')

    return redirect(request.referrer or url_for('index'))

def init_db():
    with app.app_context():
        # Drop all tables
        db.drop_all()
        # Create all tables
        db.create_all()
        # Create default settings
        settings = UserSettings()
        db.session.add(settings)
        db.session.commit()

if __name__ == '__main__':
    init_db()  # Initialize database
    app.run(debug=True, host='0.0.0.0', port=5000) 
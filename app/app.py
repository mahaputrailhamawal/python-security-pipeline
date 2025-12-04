from flask import Flask, render_template, request, redirect, url_for, session
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)
app.secret_key = 'supersecretkey'

MYSQL_USER = os.environ.get('DB_USER')
MYSQL_PASSWORD = os.environ.get('DB_PASSWORD')
MYSQL_DB = os.environ.get('DB_NAME')
MYSQL_HOST = os.environ.get('DB_HOST')
MYSQL_PORT = os.environ.get('DB_PORT')

# Konfigurasi database
app.config['SQLALCHEMY_DATABASE_URI'] = f"mysql+mysqlconnector://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}/{MYSQL_DB}"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Model pengguna
class users(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password = db.Column(db.String(50), nullable=False)


@app.route('/')
def index():
    if 'username' in session:
        return f"Hello, {session['username']}!"
    return redirect(url_for('login'))

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        user = users(username=username, password=password)
        try:
            db.session.add(user)
            db.session.commit()
        except:
            db.session.rollback()
            return "Error: Username already exists"
        return redirect(url_for('login'))
    return render_template('signup.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        user = users.query.filter_by(username=username).first()
        
        if user and user.password == password:
            session['username'] = username
            return redirect(url_for('index'))
        else:
            return "Invalid credentials"
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('username', None)
    return redirect(url_for('login'))

if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
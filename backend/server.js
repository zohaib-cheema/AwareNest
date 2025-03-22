const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

// SQLite database connection setup
const db = new sqlite3.Database('./my_database.db', (err) => {
    if (err) {
        console.error('Database connection error:', err.message);
    } else {
        console.log('Connected to the SQLite database.');
    }
});

// Create users table if not exists
db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY,
    username TEXT UNIQUE,
    password TEXT,
    email TEXT,
    phone TEXT
)`, (err) => {
    if (err) {
        console.error('Table creation error:', err.message);
    } else {
        console.log('Table created successfully.');
    }
});

// Middleware to verify token
const verifyToken = (req, res, next) => {
    const token = req.headers.authorization;
    if (!token) {
        return res.status(403).json({ message: 'Token required' });
    }
    jwt.verify(token, 'secret_key', (err, decoded) => {
        if (err) {
            return res.status(401).json({ message: 'Invalid token' });
        }
        req.userId = decoded.userId;
        req.username = decoded.username;
        next();
    });
};

// Signup endpoint
app.post('/signup', (req, res) => {
    const { username, password, email, phone } = req.body;
    // Check if username or email already exists
    db.get('SELECT * FROM users WHERE username = ? OR email = ?', [username, email], (err, existingUser) => {
        if (err) {
            return res.status(500).json({ message: 'Internal server error' });
        }
        if (existingUser) {
            return res.status(400).json({ message: 'Username or email already exists' });
        }
        // Hash the password
        const hashedPassword = bcrypt.hashSync(password, 10);
        // Insert new user into database
        db.run('INSERT INTO users (username, password, email, phone) VALUES (?, ?, ?, ?)', [username, hashedPassword, email, phone], (err) => {
            if (err) {
                return res.status(500).json({ message: 'Internal server error' });
            }
            res.status(201).json({ message: 'User created successfully' });
        });
    });
});

// Login endpoint
app.post('/login', (req, res) => {
    const { username, password } = req.body;
    db.get('SELECT * FROM users WHERE username = ?', [username], (err, user) => {
        if (err) {
            return res.status(500).json({ message: 'Internal server error' });
        }
        if (!user || !bcrypt.compareSync(password, user.password)) {
            return res.status(401).json({ message: 'Invalid username or password' });
        }
        const token = jwt.sign({ userId: user.id, username: user.username }, 'secret_key', { expiresIn: '1h' });
        res.json({ token });
    });
});

// Protected endpoint
app.get('/protected', verifyToken, (req, res) => {
    res.json({ message: 'You are authorized' });
});

// Start server
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

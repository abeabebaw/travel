const express = require('express');
const mysql = require('mysql2');
const multer = require('multer');
const cors = require('cors');
const path = require('path');
const app = express();
const port = 3000;

// CORS configuration
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));
app.options('*', cors());

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static('Uploads'));

// MySQL Database Connection
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'travel_app_db'
});

db.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL:', err.message);
    return;
  }
  console.log('Connected to MySQL database.');
});

// Multer for file uploads
const storage = multer.diskStorage({
  destination: './Uploads/',
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});
const upload = multer({ storage });

// Signup Endpoint
app.post('/signup', (req, res) => {
  const { username, email, password, role } = req.body;
  const validRoles = ['user', 'admin'];
  if (!validRoles.includes(role)) {
    return res.status(400).json({ error: 'Invalid role' });
  }
  const query = 'INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, ?)';
  db.query(query, [username, email, password, role], (err, results) => {
    if (err) {
      console.error('Signup error:', err);
      return res.status(400).json({ error: 'Signup failed', details: err.message });
    }
    res.status(200).json({ message: 'User created' });
  });
});

// Login Endpoint
app.post('/login', (req, res) => {
  const { email, password } = req.body;
  console.log(`Login attempt: email=${email}`);
  const query = 'SELECT * FROM users WHERE email = ? AND password = ?';
  db.query(query, [email, password], (err, results) => {
    if (err) {
      console.error('Login error:', err);
      return res.status(500).json({ error: 'Server error', details: err.message });
    }
    if (results.length === 0) {
      console.log('Login failed: Invalid credentials');
      return res.status(400).json({ error: 'Invalid credentials' });
    }
    console.log('Login successful:', results[0]);
    res.status(200).json({ message: 'Login successful', user: results[0] });
  });
});

// Add Place Endpoint (Admin Only)
app.post('/add-place', upload.single('image'), (req, res) => {
  const { title, description, location, userId, rating } = req.body;
  const imagePath = req.file ? `uploads/${req.file.filename}` : null;

  if (!imagePath) {
    return res.status(400).json({ error: 'No image uploaded' });
  }

  db.query('SELECT role FROM users WHERE id = ?', [userId], (err, results) => {
    if (err || results.length === 0 || results[0].role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can add places' });
    }

    const query = 'INSERT INTO places (title, description, location, image, user_id, rating) VALUES (?, ?, ?, ?, ?, ?)';
    db.query(query, [title, description, location, imagePath, userId, rating || 0.0], (err, results) => {
      if (err) {
        console.error('Add place error:', err);
        return res.status(400).json({ error: 'Failed to add place', details: err.message });
      }
      res.status(200).json({ message: 'Place added successfully' });
    });
  });
});

// Delete Place Endpoint (Admin Only)
app.delete('/delete-place/:placeId', (req, res) => {
  const { placeId } = req.params;
  const { userId } = req.body;

  db.query('SELECT role FROM users WHERE id = ?', [userId], (err, results) => {
    if (err || results.length === 0 || results[0].role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can delete places' });
    }

    const query = 'DELETE FROM places WHERE id = ?';
    db.query(query, [placeId], (err, results) => {
      if (err) {
        console.error('Delete place error:', err);
        return res.status(400).json({ error: 'Failed to delete place', details: err.message });
      }
      if (results.affectedRows === 0) {
        return res.status(404).json({ error: 'Place not found' });
      }
      res.status(200).json({ message: 'Place deleted successfully' });
    });
  });
});

// Add Agency Endpoint (Admin Only)
app.post('/add-agency', upload.single('image'), (req, res) => {
  const { name, description, contact, userId } = req.body;
  const imagePath = req.file ? `uploads/${req.file.filename}` : null;

  db.query('SELECT role FROM users WHERE id = ?', [userId], (err, results) => {
    if (err || results.length === 0 || results[0].role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can add agencies' });
    }

    const query = 'INSERT INTO agencies (name, description, contact, image) VALUES (?, ?, ?, ?)';
    db.query(query, [name, description, contact, imagePath], (err, results) => {
      if (err) {
        console.error('Add agency error:', err);
        return res.status(400).json({ error: 'Failed to add agency', details: err.message });
      }
      res.status(200).json({ message: 'Agency added successfully' });
    });
  });
});

// Add Tour Schedule Endpoint (Admin Only)
app.post('/add-tour-schedule', (req, res) => {
  const { agencyId, placeId, tourDate, price, description, userId } = req.body;

  db.query('SELECT role FROM users WHERE id = ?', [userId], (err, results) => {
    if (err || results.length === 0 || results[0].role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can add tour schedules' });
    }

    const query = 'INSERT INTO tour_schedules (agency_id, place_id, tour_date, price, description) VALUES (?, ?, ?, ?, ?)';
    db.query(query, [agencyId, placeId, tourDate, price, description], (err, results) => {
      if (err) {
        console.error('Add tour schedule error:', err);
        return res.status(400).json({ error: 'Failed to add tour schedule', details: err.message });
      }
      res.status(200).json({ message: 'Tour schedule added successfully' });
    });
  });
});

// Fetch Places Endpoint
app.get('/places', (req, res) => {
  const query = `
    SELECT p.*, COUNT(l.id) as like_count
    FROM places p
    LEFT JOIN likes l ON p.id = l.place_id
    GROUP BY p.id
    ORDER BY p.created_at DESC
  `;
  db.query(query, (err, results) => {
    if (err) {
      console.error('Fetch places error:', err);
      return res.status(400).json({ error: 'Failed to fetch places', details: err.message });
    }
    res.status(200).json(results);
  });
});

// Fetch Top Places Endpoint (Likes > 3 or Rating >= 4.0)
app.get('/top-places', (req, res) => {
  const query = `
    SELECT p.*, COUNT(l.id) as like_count
    FROM places p
    LEFT JOIN likes l ON p.id = l.place_id
    GROUP BY p.id
    HAVING COUNT(l.id) > 3 OR p.rating >= 4.0
    ORDER BY p.rating DESC, COUNT(l.id) DESC
  `;
  db.query(query, (err, results) => {
    if (err) {
      console.error('Fetch top places error:', err);
      return res.status(400).json({ error: 'Failed to fetch top places', details: err.message });
    }
    res.status(200).json(results);
  });
});

// Fetch Agencies Endpoint
app.get('/agencies', (req, res) => {
  const query = 'SELECT * FROM agencies ORDER BY created_at DESC';
  db.query(query, (err, results) => {
    if (err) {
      console.error('Fetch agencies error:', err);
      return res.status(400).json({ error: 'Failed to fetch agencies', details: err.message });
    }
    res.status(200).json(results);
  });
});

// Fetch Tour Schedules Endpoint
app.get('/tour-schedules/:agencyId', (req, res) => {
  const { agencyId } = req.params;
  const query = `
    SELECT ts.*, p.title as place_title
    FROM tour_schedules ts
    JOIN places p ON ts.place_id = p.id
    WHERE ts.agency_id = ?
    ORDER BY ts.tour_date ASC
  `;
  db.query(query, [agencyId], (err, results) => {
    if (err) {
      console.error('Fetch tour schedules error:', err);
      return res.status(400).json({ error: 'Failed to fetch tour schedules', details: err.message });
    }
    res.status(200).json(results);
  });
});

// Like Place Endpoint
app.post('/like-place', (req, res) => {
  const { placeId, userId } = req.body;
  const query = 'INSERT INTO likes (place_id, user_id) VALUES (?, ?)';
  db.query(query, [placeId, userId], (err, results) => {
    if (err) {
      if (err.code === 'ER_DUP_ENTRY') {
        const deleteQuery = 'DELETE FROM likes WHERE place_id = ? AND user_id = ?';
        db.query(deleteQuery, [placeId, userId], (deleteErr, deleteResults) => {
          if (deleteErr) {
            console.error('Unlike error:', deleteErr);
            return res.status(400).json({ error: 'Failed to unlike place', details: deleteErr.message });
          }
          res.status(200).json({ message: 'Place unliked successfully' });
        });
      } else {
        console.error('Like error:', err);
        return res.status(400).json({ error: 'Failed to like place', details: err.message });
      }
    } else {
      res.status(200).json({ message: 'Place liked successfully' });
    }
  });
});

// Check Like Status Endpoint
app.get('/like-status/:placeId/:userId', (req, res) => {
  const { placeId, userId } = req.params;
  const query = 'SELECT * FROM likes WHERE place_id = ? AND user_id = ?';
  db.query(query, [placeId, userId], (err, results) => {
    if (err) {
      console.error('Check like status error:', err);
      return res.status(400).json({ error: 'Failed to check like status', details: err.message });
    }
    res.status(200).json({ isLiked: results.length > 0 });
  });
});

// Add Comment Endpoint
app.post('/add-comment', (req, res) => {
  const { placeId, comment, userId } = req.body;
  const query = 'INSERT INTO comments (place_id, comment, user_id) VALUES (?, ?, ?)';
  db.query(query, [placeId, comment, userId], (err, results) => {
    if (err) {
      console.error('Add comment error:', err);
      return res.status(400).json({ error: 'Failed to add comment', details: err.message });
    }
    res.status(200).json({ message: 'Comment added successfully' });
  });
});

// Add Comment Reply Endpoint (Admin Only)
app.post('/add-comment-reply', (req, res) => {
  const { commentId, reply, userId } = req.body;

  db.query('SELECT role FROM users WHERE id = ?', [userId], (err, results) => {
    if (err || results.length === 0 || results[0].role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can reply to comments' });
    }

    const query = 'INSERT INTO comment_replies (comment_id, reply, user_id) VALUES (?, ?, ?)';
    db.query(query, [commentId, reply, userId], (err, results) => {
      if (err) {
        console.error('Add reply error:', err);
        return res.status(400).json({ error: 'Failed to add reply', details: err.message });
      }
      res.status(200).json({ message: 'Reply added successfully' });
    });
  });
});

// Fetch Comments with Replies Endpoint
app.get('/comments/:placeId', (req, res) => {
  const { placeId } = req.params;
  const query = `
    SELECT c.id, c.comment, c.user_id, u.username, c.created_at,
           cr.id as reply_id, cr.reply, cr.user_id as reply_user_id, ru.username as reply_username
    FROM comments c
    LEFT JOIN users u ON c.user_id = u.id
    LEFT JOIN comment_replies cr ON c.id = cr.comment_id
    LEFT JOIN users ru ON cr.user_id = ru.id
    WHERE c.place_id = ?
    ORDER BY c.created_at DESC, cr.created_at ASC
  `;
  db.query(query, [placeId], (err, results) => {
    if (err) {
      console.error('Fetch comments error:', err);
      return res.status(400).json({ error: 'Failed to fetch comments', details: err.message });
    }
    res.status(200).json(results);
  });
});

// Start Server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
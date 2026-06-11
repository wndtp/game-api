const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

const db = mysql.createPool({
    host: '192.168.50.105',
    user: 'game_user',
    password: 'GamePASSword123!',
    database: 'game_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

db.on('error', (err) => {
    console.error('🚨 DB 에러 발생:', err);
});
//testtest
//
// 🏥 자동 복구(Auto-Healing) 헬스체크용 라우터 추가
app.get('/health', (req, res) => res.status(200).send('OK'));
// 랭킹 저장 API
app.post('/api/ranking', (req, res) => {
    const { nickname, score, game_type } = req.body;
    const query = 'INSERT INTO rankings (nickname, score, game_type) VALUES (?, ?, ?)';
    db.query(query, [nickname, score, game_type], (err, result) => {
        if (err) return res.status(500).send('DB 저장 에러');
        res.status(201).send('저장 완료');
    });
});

// 랭킹 조회 API
app.get('/api/ranking', (req, res) => {
    const gameType = req.query.game_type || 'clicker';
    const query = 'SELECT nickname, score FROM rankings WHERE game_type = ? ORDER BY score DESC LIMIT 10';
    db.query(query, [gameType], (err, results) => {
        if (err) return res.status(500).send('DB 조회 에러');
        res.json(results);
    });
});

app.listen(port, () => console.log(`🚀 백엔드 API 서버 포트 ${port}`));

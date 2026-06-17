const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const BASE_DIR = path.resolve(__dirname);

const server = http.createServer((req, res) => {
    // Set CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }
    
    // Default to web-demo.html for root
    let filePath = req.url === '/' ? '/web-demo.html' : req.url;
    filePath = path.resolve(path.join(BASE_DIR, filePath));
    
    // Security: prevent directory traversal
    const normalizedBase = path.normalize(BASE_DIR);
    const normalizedFile = path.normalize(filePath);
    
    if (!normalizedFile.startsWith(normalizedBase)) {
        res.writeHead(403);
        res.end('Forbidden');
        return;
    }
    
    fs.readFile(filePath, (err, data) => {
        if (err) {
            // Try with .html extension
            if (!filePath.endsWith('.html')) {
                filePath += '.html';
                fs.readFile(filePath, (err, data) => {
                    if (err) {
                        res.writeHead(404);
                        res.end('Not Found');
                        return;
                    }
                    
                    res.setHeader('Content-Type', 'text/html');
                    res.writeHead(200);
                    res.end(data);
                });
                return;
            }
            
            res.writeHead(404);
            res.end('Not Found');
            return;
        }
        
        // Set content type based on file extension
        let contentType = 'text/plain';
        if (filePath.endsWith('.html')) contentType = 'text/html';
        else if (filePath.endsWith('.css')) contentType = 'text/css';
        else if (filePath.endsWith('.js')) contentType = 'text/javascript';
        else if (filePath.endsWith('.json')) contentType = 'application/json';
        
        res.setHeader('Content-Type', contentType);
        res.writeHead(200);
        res.end(data);
    });
});

server.listen(PORT, () => {
    console.log(`\n🌐 Web Server running on http://localhost:${PORT}`);
    console.log(`📄 Main page: http://localhost:${PORT}/web-demo.html`);
    console.log(`📋 API Test: http://localhost:${PORT}/API_TEST.html`);
    console.log(`\n🔗 Backend API: http://localhost:8080`);
    console.log(`\n✨ Sample users (for login):`);
    console.log(`   admin / password123`);
    console.log(`   john_buyer / password123`);
    console.log(`   jane_seller / password123\n`);
});

process.on('SIGINT', () => {
    console.log('\n🛑 Web server shutting down...');
    process.exit(0);
});

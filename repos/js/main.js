const http = require('http');

http.createServer((req, res) => {
  if (req.url === '/js/getarch') {
    console.log("responding to client request")
    const arch = process.arch;
    const os = process.platform
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end(`OS: ${os}\nArch: ${arch}`);
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
}).listen(3000, () => {
  console.log('Server listening on port 3000');
});

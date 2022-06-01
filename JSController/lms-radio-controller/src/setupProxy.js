const { createProxyMiddleware } = require('http-proxy-middleware');

module.exports = function(app) {
  app.use(
    ['/api','/cometd'],
    createProxyMiddleware({
      target: 'http://172.16.0.59:9000',
      changeOrigin: true,
    })
  );
  
};
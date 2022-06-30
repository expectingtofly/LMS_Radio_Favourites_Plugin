const { createProxyMiddleware } = require('http-proxy-middleware');

module.exports = function(app) {
  app.use(
    ['/api','/cometd','/plugins/TimesRadio','/plugins/VirginRadio','/imageproxy'],
    createProxyMiddleware({
      target: 'http://172.16.0.59:9000',
      changeOrigin: true,
    })
  );
  
};
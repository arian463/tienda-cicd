const express = require('express');
const client = require('prom-client');

function createApp() {
  const app = express();
  app.use(express.json());

  const register = new client.Registry();
  client.collectDefaultMetrics({ register });

  const httpDuration = new client.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duración de las peticiones HTTP en segundos',
    labelNames: ['method', 'route', 'status'],
    buckets: [0.05, 0.1, 0.2, 0.3, 0.5, 1, 2],
    registers: [register],
  });

  const ordersCreated = new client.Counter({
    name: 'orders_created_total',
    help: 'Pedidos creados correctamente',
    registers: [register],
  });

  app.use((req, res, next) => {
    const end = httpDuration.startTimer();
    res.on('finish', () => {
      const route = req.route ? req.route.path : 'unmatched';
      end({ method: req.method, route, status: res.statusCode });
    });
    next();
  });

  const products = [
    { id: 1, name: 'Camiseta', price: 199.0, stock: 20 },
    { id: 2, name: 'Taza', price: 99.0, stock: 50 },
    { id: 3, name: 'Gorra', price: 149.0, stock: 30 },
  ];
  const orders = [];

  app.get('/health', (req, res) => {
    res.json({ status: 'ok', version: process.env.APP_VERSION || 'dev' });
  });

  app.get('/products', (req, res) => {
    res.json(products);
  });

  app.get('/products/:id', (req, res) => {
    const product = products.find((p) => p.id === Number(req.params.id));
    if (!product) return res.status(404).json({ error: 'Producto no encontrado' });
    return res.json(product);
  });

  app.post('/orders', (req, res) => {
    const { productId, quantity } = req.body || {};
    const product = products.find((p) => p.id === Number(productId));
    if (!product) return res.status(404).json({ error: 'Producto no encontrado' });
    if (!Number.isInteger(quantity) || quantity < 1) {
      return res.status(400).json({ error: 'La cantidad debe ser un entero mayor a 0' });
    }
    if (quantity > product.stock) {
      return res.status(400).json({ error: 'No hay existencias suficientes' });
    }
    product.stock -= quantity;
    const order = { id: orders.length + 1, productId: product.id, quantity, total: product.price * quantity };
    orders.push(order);
    ordersCreated.inc();
    return res.status(201).json(order);
  });

  app.get('/metrics', async (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  });

  return app;
}

module.exports = { createApp };

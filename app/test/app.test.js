const { test, before, after } = require('node:test');
const assert = require('node:assert');
const { createApp } = require('../src/app');

let server;
let base;

before(async () => {
  await new Promise((resolve) => {
    server = createApp().listen(0, resolve);
  });
  base = `http://127.0.0.1:${server.address().port}`;
});

after(() => {
  server.close();
});

test('GET /health responde ok con la versión', async () => {
  const res = await fetch(`${base}/health`);
  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.status, 'ok');
  assert.ok(body.version);
});

test('GET /products devuelve el catálogo', async () => {
  const res = await fetch(`${base}/products`);
  const body = await res.json();
  assert.strictEqual(res.status, 200);
  assert.ok(Array.isArray(body) && body.length > 0);
});

test('GET /products/:id inexistente devuelve 404', async () => {
  const res = await fetch(`${base}/products/9999`);
  assert.strictEqual(res.status, 404);
});

test('POST /orders crea un pedido válido', async () => {
  const res = await fetch(`${base}/orders`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ productId: 1, quantity: 2 }),
  });
  assert.strictEqual(res.status, 201);
  const body = await res.json();
  assert.strictEqual(body.total, 398);
});

test('POST /orders rechaza cantidad inválida', async () => {
  const res = await fetch(`${base}/orders`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ productId: 1, quantity: 0 }),
  });
  assert.strictEqual(res.status, 400);
});

test('POST /orders rechaza cantidad mayor a las existencias', async () => {
  const res = await fetch(`${base}/orders`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ productId: 2, quantity: 100000 }),
  });
  assert.strictEqual(res.status, 400);
});

test('GET /metrics expone las métricas de Prometheus', async () => {
  await fetch(`${base}/products`);
  const res = await fetch(`${base}/metrics`);
  const text = await res.text();
  assert.strictEqual(res.status, 200);
  assert.match(text, /http_request_duration_seconds/);
  assert.match(text, /orders_created_total/);
});

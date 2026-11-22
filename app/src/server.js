const { createApp } = require('./app');

const port = process.env.PORT || 3000;
createApp().listen(port, () => {
  console.log(`Tienda API escuchando en el puerto ${port}`);
});

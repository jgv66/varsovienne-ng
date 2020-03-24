// conexion a la base real de varsovienne
module.exports = {
    user: 'sa',
    password: 'megatron.123',
    server: '200.113.49.181', // You can use 'localhost\\instance' to connect to named instance
    port: 1433,
    database: 'BVARSOVIENNE',
    options: { encrypt: false } // Use this if you're on Windows Azure
};
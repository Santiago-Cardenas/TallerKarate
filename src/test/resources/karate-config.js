function fn() {
    var env = karate.env || 'dev';

    var config = {
        env: env,
        // URL base de las APIs del taller de técnicas de caja negra (se puede sobrescribir con -DbaseUrl=...)
        baseUrl: karate.properties['baseUrl'] || 'https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api/'
    };

    // El servidor está en Render: si está "dormido" la primera petición puede tardar ~1 minuto
    karate.configure('connectTimeout', 90000);
    karate.configure('readTimeout', 90000);

    // Formatea el JSON de requests y responses en la consola
    karate.configure('logPrettyRequest', true);
    karate.configure('logPrettyResponse', true);

    return config;
}

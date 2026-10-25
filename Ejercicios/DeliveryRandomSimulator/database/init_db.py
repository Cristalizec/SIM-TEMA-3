
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from database.connection import get_engine


def initialize_database():

    # Tabla de simulaciones
    simulaciones = """
    CREATE TABLE IF NOT EXISTS simulaciones (
        id BIGSERIAL PRIMARY KEY,
        metodo VARCHAR(50) NOT NULL,
        cantidad_pedidos INTEGER NOT NULL,
        tiempo_promedio DOUBLE PRECISION DEFAULT 0,
        fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
    """

    # Tabla de pedidos
    pedidos = """
    CREATE TABLE IF NOT EXISTS pedidos (
        id BIGSERIAL PRIMARY KEY,
        simulacion_id BIGINT NOT NULL,
        numero_pedido INTEGER NOT NULL,
        tipo_entrega VARCHAR(50) NOT NULL,
        distancia_km DOUBLE PRECISION NOT NULL,
        peso_kg DOUBLE PRECISION NOT NULL,
        origen_dato VARCHAR(30) DEFAULT 'simulado',

        FOREIGN KEY (simulacion_id)
        REFERENCES simulaciones(id)
        ON DELETE CASCADE,

        UNIQUE (simulacion_id, numero_pedido)
    );
    """

    # Tabla de entregas
    entregas = """
    CREATE TABLE IF NOT EXISTS entregas (
        id BIGSERIAL PRIMARY KEY,
        pedido_id BIGINT NOT NULL UNIQUE,
        tiempo_preparacion DOUBLE PRECISION NOT NULL,
        tiempo_transporte DOUBLE PRECISION NOT NULL,
        tiempo_total DOUBLE PRECISION NOT NULL,
        estado VARCHAR(30) DEFAULT 'Entregado',

        FOREIGN KEY (pedido_id)
        REFERENCES pedidos(id)
        ON DELETE CASCADE
    );
    """

    # Tabla de pruebas estadísticas
    pruebas_estadisticas = """
    CREATE TABLE IF NOT EXISTS pruebas_estadisticas (
        id BIGSERIAL PRIMARY KEY,
        simulacion_id BIGINT NOT NULL,
        nombre_prueba VARCHAR(100) NOT NULL,
        estadistico DOUBLE PRECISION,
        valor_p DOUBLE PRECISION,
        resultado VARCHAR(50),
        fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

        FOREIGN KEY (simulacion_id)
        REFERENCES simulaciones(id)
        ON DELETE CASCADE
    );
    """

    # Crear las tablas automáticamente
    try:

        engine = get_engine()

        with engine.begin() as connection:

            connection.execute(text(simulaciones))
            print("Tabla simulaciones creada correctamente")

            connection.execute(text(pedidos))
            print("Tabla pedidos creada correctamente")

            connection.execute(text(entregas))
            print("Tabla entregas creada correctamente")

            connection.execute(text(pruebas_estadisticas))
            print("Tabla pruebas_estadisticas creada correctamente")

        engine.dispose()

        print("\n¡Base de datos inicializada correctamente!")

        return True

    except SQLAlchemyError as error:

        print("Error al crear las tablas:")
        print(error)

        return False


# Ejecutar creación de tablas
if __name__ == "__main__":

    initialize_database()

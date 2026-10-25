
from sqlalchemy import text

from database.connection import get_engine
from services.simulation_service import simular_entregas
from services.statistics_service import analizar_simulacion


# Guardar simulación completa en PostgreSQL
def guardar_simulacion(resultado):

    if not resultado.pedidos:
        raise ValueError(
            "La simulación no contiene pedidos."
        )

    if len(resultado.pedidos) != len(resultado.entregas):
        raise ValueError(
            "La cantidad de pedidos y entregas "
            "no coincide."
        )

    # Realizar análisis estadístico
    analisis = analizar_simulacion(resultado)

    engine = get_engine()

    ids_pedidos = []

    try:

        # Una transacción para todos los registros
        with engine.begin() as connection:

            # 1. GUARDAR SIMULACIÓN
            sql_simulacion = text("""
                INSERT INTO simulaciones (
                    metodo,
                    cantidad_pedidos,
                    tiempo_promedio
                )
                VALUES (
                    :metodo,
                    :cantidad,
                    :promedio
                )
                RETURNING id
            """)

            simulacion_id = connection.execute(
                sql_simulacion,
                {
                    "metodo": resultado.metodo,
                    "cantidad": len(resultado.pedidos),
                    "promedio": resultado.tiempo_promedio
                }
            ).scalar_one()

            print(
                f"Simulación creada con ID: "
                f"{simulacion_id}"
            )

            # 2. GUARDAR PEDIDOS
            sql_pedido = text("""
                INSERT INTO pedidos (
                    simulacion_id,
                    numero_pedido,
                    tipo_entrega,
                    distancia_km,
                    peso_kg,
                    origen_dato
                )
                VALUES (
                    :simulacion_id,
                    :numero_pedido,
                    :tipo_entrega,
                    :distancia_km,
                    :peso_kg,
                    :origen_dato
                )
                RETURNING id
            """)

            # 3. GUARDAR ENTREGAS
            sql_entrega = text("""
                INSERT INTO entregas (
                    pedido_id,
                    tiempo_preparacion,
                    tiempo_transporte,
                    tiempo_total,
                    estado
                )
                VALUES (
                    :pedido_id,
                    :tiempo_preparacion,
                    :tiempo_transporte,
                    :tiempo_total,
                    :estado
                )
            """)

            for pedido, entrega in zip(
                resultado.pedidos,
                resultado.entregas
            ):

                # Insertar pedido
                pedido_id = connection.execute(
                    sql_pedido,
                    {
                        "simulacion_id": simulacion_id,
                        "numero_pedido": pedido.numero_pedido,
                        "tipo_entrega": pedido.tipo_entrega,
                        "distancia_km": pedido.distancia_km,
                        "peso_kg": pedido.peso_kg,
                        "origen_dato": pedido.origen_dato
                    }
                ).scalar_one()

                ids_pedidos.append(pedido_id)

                # Insertar entrega correspondiente
                connection.execute(
                    sql_entrega,
                    {
                        "pedido_id": pedido_id,
                        "tiempo_preparacion":
                            entrega.tiempo_preparacion,
                        "tiempo_transporte":
                            entrega.tiempo_transporte,
                        "tiempo_total":
                            entrega.tiempo_total,
                        "estado": entrega.estado
                    }
                )

            # 4. GUARDAR PRUEBAS ESTADÍSTICAS
            sql_prueba = text("""
                INSERT INTO pruebas_estadisticas (
                    simulacion_id,
                    nombre_prueba,
                    estadistico,
                    valor_p,
                    resultado
                )
                VALUES (
                    :simulacion_id,
                    :nombre_prueba,
                    :estadistico,
                    :valor_p,
                    :resultado
                )
            """)

            for prueba in analisis["pruebas"]:

                connection.execute(
                    sql_prueba,
                    {
                        "simulacion_id": simulacion_id,
                        "nombre_prueba":
                            prueba["nombre_prueba"],
                        "estadistico":
                            prueba["estadistico"],
                        "valor_p":
                            prueba["valor_p"],
                        "resultado":
                            prueba["resultado"]
                    }
                )

        # La transacción terminó correctamente.
        # Actualizar los objetos en memoria.
        for pedido, entrega, pedido_id in zip(
            resultado.pedidos,
            resultado.entregas,
            ids_pedidos
        ):

            pedido.id = pedido_id
            pedido.simulacion_id = simulacion_id

            entrega.pedido_id = pedido_id

        print("Pedidos guardados correctamente.")
        print("Entregas guardadas correctamente.")
        print("Pruebas estadísticas guardadas.")
        print("Transacción confirmada en PostgreSQL.")

        return simulacion_id

    finally:

        engine.dispose()


# PROBAR EL GUARDADO EN POSTGRESQL
if __name__ == "__main__":

    print("SIMULADOR DE ENTREGAS")
    print("------------------------------")

    try:

        # Generar 100 pedidos aleatorios
        simulacion = simular_entregas(
            metodo="Transformada inversa",
            cantidad_pedidos=100,
            semilla=123
        )

        print("\nSimulación generada.")
        print(
            "Cantidad de pedidos:",
            len(simulacion.pedidos)
        )

        print(
            f"Tiempo promedio: "
            f"{simulacion.tiempo_promedio:.2f} min"
        )

        # Guardar todos los resultados
        identificador = guardar_simulacion(
            simulacion
        )

        print("\nGUARDADO COMPLETADO")
        print(
            "ID de simulación:",
            identificador
        )

    except Exception as error:

        print("\nError al guardar la simulación:")
        print(error)

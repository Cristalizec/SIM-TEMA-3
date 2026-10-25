
import pandas as pd
import plotly.express as px
import streamlit as st

from sqlalchemy import text

from database.connection import get_engine
from database.simulation_repository import guardar_simulacion

from services.dataset_service import cargar_dataset
from services.simulation_service import (
    METODOS,
    simular_entregas
)
from services.statistics_service import analizar_simulacion


# Convertir una simulación en una tabla
def crear_tabla_resultados(simulacion):

    registros = []

    for pedido, entrega in zip(
        simulacion.pedidos,
        simulacion.entregas
    ):

        registros.append({
            "Pedido": pedido.numero_pedido,
            "Tipo de entrega": pedido.tipo_entrega,
            "Distancia (km)": pedido.distancia_km,
            "Peso (kg)": pedido.peso_kg,
            "Preparación (min)":
                entrega.tiempo_preparacion,
            "Transporte (min)":
                entrega.tiempo_transporte,
            "Total (min)":
                entrega.tiempo_total,
            "Estado": entrega.estado
        })

    return pd.DataFrame(registros)


# Consultar el historial de PostgreSQL
def consultar_historial():

    engine = get_engine()

    try:

        consulta = text("""
            SELECT
                id,
                metodo,
                cantidad_pedidos,
                tiempo_promedio,
                fecha_creacion
            FROM simulaciones
            ORDER BY id DESC
            LIMIT 100
        """)

        with engine.connect() as connection:

            registros = connection.execute(
                consulta
            ).mappings().all()

            return pd.DataFrame(
                [dict(fila) for fila in registros]
            )

    finally:
        engine.dispose()


# Consultar pedidos de una simulación guardada
def consultar_detalles(simulacion_id):

    engine = get_engine()

    try:

        consulta = text("""
            SELECT
                p.numero_pedido,
                p.tipo_entrega,
                p.distancia_km,
                p.peso_kg,
                e.tiempo_preparacion,
                e.tiempo_transporte,
                e.tiempo_total,
                e.estado
            FROM pedidos p
            INNER JOIN entregas e
                ON e.pedido_id = p.id
            WHERE p.simulacion_id = :simulacion_id
            ORDER BY p.numero_pedido
        """)

        with engine.connect() as connection:

            registros = connection.execute(
                consulta,
                {"simulacion_id": simulacion_id}
            ).mappings().all()

            return pd.DataFrame(
                [dict(fila) for fila in registros]
            )

    finally:
        engine.dispose()


# Consultar pruebas estadísticas guardadas
def consultar_pruebas(simulacion_id):

    engine = get_engine()

    try:

        consulta = text("""
            SELECT
                nombre_prueba,
                estadistico,
                valor_p,
                resultado
            FROM pruebas_estadisticas
            WHERE simulacion_id = :simulacion_id
            ORDER BY id
        """)

        with engine.connect() as connection:

            registros = connection.execute(
                consulta,
                {"simulacion_id": simulacion_id}
            ).mappings().all()

            return pd.DataFrame(
                [dict(fila) for fila in registros]
            )

    finally:
        engine.dispose()


# INTERFAZ PRINCIPAL
def mostrar_dashboard():

    st.title("📦 Delivery Random Simulator")

    st.write(
        "Sistema de generación de variables aleatorias "
        "para simular entregas de paquetes."
    )

    st.divider()

    # PANEL LATERAL
    with st.sidebar:

        st.header("⚙️ Configuración")

        st.write(
            "Selecciona los parámetros "
            "de la simulación."
        )

        with st.form("form_simulacion"):

            metodo = st.selectbox(
                "Método de generación",
                METODOS
            )

            cantidad = st.number_input(
                "Cantidad de pedidos",
                min_value=1,
                max_value=1000,
                value=100,
                step=1
            )

            usar_semilla = st.checkbox(
                "Utilizar semilla fija",
                value=True
            )

            semilla = st.number_input(
                "Semilla aleatoria",
                min_value=0,
                value=123,
                step=1
            )

            ejecutar = st.form_submit_button(
                "🚀 Simular y guardar",
                use_container_width=True,
                type="primary"
            )

        st.divider()

        st.caption(
            "Python + Streamlit + PostgreSQL"
        )

    # EJECUTAR SIMULACIÓN
    if ejecutar:

        try:

            with st.spinner(
                "Generando pedidos y entregas..."
            ):

                resultado = simular_entregas(
                    metodo=metodo,
                    cantidad_pedidos=int(cantidad),
                    semilla=(
                        int(semilla)
                        if usar_semilla else None
                    )
                )

                analisis = analizar_simulacion(
                    resultado
                )

                st.session_state["simulacion"] = resultado
                st.session_state["analisis"] = analisis

                st.session_state["simulacion_id"] = None
                st.session_state["error_guardado"] = None

                # Guardar automáticamente
                try:

                    identificador = guardar_simulacion(
                        resultado
                    )

                    st.session_state[
                        "simulacion_id"
                    ] = identificador

                except Exception as error:

                    st.session_state[
                        "error_guardado"
                    ] = str(error)

        except Exception as error:

            st.error(
                f"No se pudo generar la simulación: {error}"
            )

    # MOSTRAR ESTADO DEL GUARDADO
    if "simulacion" in st.session_state:

        identificador = st.session_state.get(
            "simulacion_id"
        )

        error_guardado = st.session_state.get(
            "error_guardado"
        )

        if identificador is not None:

            st.success(
                f"Simulación guardada en PostgreSQL. "
                f"ID: {identificador}"
            )

        elif error_guardado:

            st.warning(
                "La simulación se generó, pero "
                "no pudo guardarse en PostgreSQL."
            )

            with st.expander("Ver error"):
                st.code(error_guardado)

    # PESTAÑAS PRINCIPALES
    tab1, tab2, tab3, tab4, tab5 = st.tabs([
        "📋 Resultados",
        "📊 Gráficas",
        "🧪 Estadísticas",
        "📂 Dataset",
        "🗄️ PostgreSQL"
    ])

    simulacion = st.session_state.get(
        "simulacion"
    )

    analisis = st.session_state.get(
        "analisis"
    )

    # =====================================
    # PESTAÑA 1: RESULTADOS
    # =====================================
    with tab1:

        st.subheader("Resultados de la simulación")

        if simulacion is None:

            st.info(
                "Configura y ejecuta una simulación "
                "para visualizar los resultados."
            )

        else:

            resumen = analisis["resumen"]

            columna1, columna2, columna3 = st.columns(3)

            columna1.metric(
                "Pedidos generados",
                resumen["cantidad_pedidos"]
            )

            columna2.metric(
                "Tiempo promedio",
                f"{resumen['tiempo_promedio']:.2f} min"
            )

            columna3.metric(
                "Tiempo máximo",
                f"{resumen['tiempo_maximo']:.2f} min"
            )

            st.write(
                f"**Método utilizado:** {simulacion.metodo}"
            )

            tabla = crear_tabla_resultados(
                simulacion
            )

            st.dataframe(
                tabla,
                use_container_width=True,
                hide_index=True
            )

            st.download_button(
                "📥 Descargar resultados CSV",
                data=tabla.to_csv(
                    index=False
                ).encode("utf-8-sig"),
                file_name="resultados_simulacion.csv",
                mime="text/csv"
            )

    # =====================================
    # PESTAÑA 2: GRÁFICAS
    # =====================================
    with tab2:

        st.subheader("Gráficas de la simulación")

        if simulacion is None:

            st.info(
                "Primero debes realizar una simulación."
            )

        else:

            tabla = crear_tabla_resultados(
                simulacion
            )

            # Gráfica de barras
            grafica1 = px.bar(
                tabla,
                x="Pedido",
                y="Total (min)",
                color="Tipo de entrega",
                title="Tiempo total por pedido"
            )

            st.plotly_chart(
                grafica1,
                use_container_width=True
            )

            # Histograma
            grafica2 = px.histogram(
                tabla,
                x="Total (min)",
                nbins=20,
                color="Tipo de entrega",
                title="Distribución de tiempos de entrega"
            )

            st.plotly_chart(
                grafica2,
                use_container_width=True
            )

            # Distancia contra tiempo
            grafica3 = px.scatter(
                tabla,
                x="Distancia (km)",
                y="Total (min)",
                color="Tipo de entrega",
                hover_data=["Pedido"],
                title="Distancia y tiempo de entrega"
            )

            st.plotly_chart(
                grafica3,
                use_container_width=True
            )

    # =====================================
    # PESTAÑA 3: PRUEBAS ESTADÍSTICAS
    # =====================================
    with tab3:

        st.subheader("Análisis estadístico")

        if analisis is None:

            st.info(
                "Realiza una simulación para "
                "obtener las estadísticas."
            )

        else:

            resumen = analisis["resumen"]

            columna1, columna2 = st.columns(2)

            with columna1:

                st.metric(
                    "Mediana",
                    f"{resumen['mediana']:.2f} min"
                )

                st.metric(
                    "Tiempo mínimo",
                    f"{resumen['tiempo_minimo']:.2f} min"
                )

            with columna2:

                st.metric(
                    "Desviación estándar",
                    f"{resumen['desviacion_estandar']:.2f}"
                )

                st.metric(
                    "Varianza",
                    f"{resumen['varianza']:.2f}"
                )

            st.subheader("Pruebas estadísticas")

            pruebas = pd.DataFrame(
                analisis["pruebas"]
            )

            st.dataframe(
                pruebas,
                use_container_width=True,
                hide_index=True
            )

            st.info(
                "Las pruebas se aplican a los números "
                "uniformes utilizados por los métodos "
                "de generación. No rechazar una hipótesis "
                "no demuestra aleatoriedad perfecta."
            )

    # =====================================
    # PESTAÑA 4: DATASET
    # =====================================
    with tab4:

        st.subheader("Dataset de entregas")

        try:

            datos = cargar_dataset()

            st.metric(
                "Registros del dataset",
                len(datos)
            )

            st.dataframe(
                datos,
                use_container_width=True,
                hide_index=True
            )

            grafica_dataset = px.histogram(
                datos,
                x="tipo_entrega",
                title="Distribución de tipos de entrega"
            )

            st.plotly_chart(
                grafica_dataset,
                use_container_width=True
            )

            st.download_button(
                "📥 Descargar dataset",
                data=datos.to_csv(
                    index=False
                ).encode("utf-8-sig"),
                file_name="entregas.csv",
                mime="text/csv"
            )

        except Exception as error:

            st.error(
                f"Error al cargar dataset: {error}"
            )

    # =====================================
    # PESTAÑA 5: POSTGRESQL
    # =====================================
    with tab5:

        st.subheader("Historial de simulaciones")

        st.write(
            "Consulta las simulaciones que se "
            "encuentran guardadas en PostgreSQL."
        )

        try:

            historial = consultar_historial()

            if historial.empty:

                st.info(
                    "Todavía no hay simulaciones guardadas."
                )

            else:

                st.dataframe(
                    historial,
                    use_container_width=True,
                    hide_index=True
                )

                identificador = st.selectbox(
                    "Selecciona una simulación",
                    historial["id"].astype(int).tolist()
                )

                st.subheader(
                    f"Pedidos de la simulación {identificador}"
                )

                detalles = consultar_detalles(
                    identificador
                )

                st.dataframe(
                    detalles,
                    use_container_width=True,
                    hide_index=True
                )

                st.subheader(
                    "Pruebas estadísticas guardadas"
                )

                pruebas_guardadas = consultar_pruebas(
                    identificador
                )

                st.dataframe(
                    pruebas_guardadas,
                    use_container_width=True,
                    hide_index=True
                )

        except Exception as error:

            st.error(
                "No fue posible consultar PostgreSQL."
            )

            with st.expander("Ver detalle del error"):
                st.code(str(error))

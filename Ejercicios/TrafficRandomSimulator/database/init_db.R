
# ==========================================
# TRAFFIC RANDOM SIMULATOR
# Creacion automatica de tablas
# PostgreSQL + RStudio
# ==========================================

library(DBI)
library(RPostgres)

# Importar nuestra conexion
source("database/connection.R")


# Funcion para crear las tablas
crear_tablas <- function() {
  
  conexion <- NULL
  
  tryCatch({
    
    # Conectar con PostgreSQL
    conexion <- get_connection()
    
    # ======================================
    # TABLA 1: SEMAFOROS
    # ======================================
    
    tabla_semaforos <- "
      CREATE TABLE IF NOT EXISTS semaforos (

        id BIGSERIAL PRIMARY KEY,

        nombre VARCHAR(100) NOT NULL UNIQUE,

        verde_segundos INTEGER NOT NULL
          CHECK (verde_segundos > 0),

        amarillo_segundos INTEGER NOT NULL
          CHECK (amarillo_segundos >= 0),

        rojo_segundos INTEGER NOT NULL
          CHECK (rojo_segundos > 0),

        fecha_creacion TIMESTAMPTZ
          DEFAULT CURRENT_TIMESTAMP
      );
    "
    
    # ======================================
    # TABLA 2: SIMULACIONES
    # ======================================
    
    tabla_simulaciones <- "
      CREATE TABLE IF NOT EXISTS simulaciones (

        id BIGSERIAL PRIMARY KEY,

        semaforo_id BIGINT NOT NULL
          REFERENCES semaforos(id),

        metodo VARCHAR(50) NOT NULL,

        cantidad_vehiculos INTEGER NOT NULL
          CHECK (cantidad_vehiculos > 0),

        tiempo_promedio_espera_seg
          DOUBLE PRECISION DEFAULT 0,

        tiempo_total_seg
          DOUBLE PRECISION DEFAULT 0,

        fecha_creacion TIMESTAMPTZ
          DEFAULT CURRENT_TIMESTAMP
      );
    "
    
    # ======================================
    # TABLA 3: VEHICULOS
    # ======================================
    
    tabla_vehiculos <- "
      CREATE TABLE IF NOT EXISTS vehiculos (

        id BIGSERIAL PRIMARY KEY,

        simulacion_id BIGINT NOT NULL
          REFERENCES simulaciones(id)
          ON DELETE CASCADE,

        numero_vehiculo INTEGER NOT NULL,

        tipo_vehiculo VARCHAR(50) NOT NULL,

        velocidad_kmh DOUBLE PRECISION NOT NULL
          CHECK (velocidad_kmh > 0),

        intervalo_llegada_seg DOUBLE PRECISION NOT NULL
          CHECK (intervalo_llegada_seg >= 0),

        tiempo_llegada_seg DOUBLE PRECISION NOT NULL
          CHECK (tiempo_llegada_seg >= 0),

        tiempo_cruce_seg DOUBLE PRECISION NOT NULL
          CHECK (tiempo_cruce_seg > 0),

        UNIQUE (
          simulacion_id,
          numero_vehiculo
        )
      );
    "
    
    # ======================================
    # TABLA 4: RESULTADOS DEL TRAFICO
    # ======================================
    
    tabla_resultados <- "
      CREATE TABLE IF NOT EXISTS resultados_trafico (

        id BIGSERIAL PRIMARY KEY,

        vehiculo_id BIGINT NOT NULL UNIQUE
          REFERENCES vehiculos(id)
          ON DELETE CASCADE,

        tiempo_inicio_cruce_seg
          DOUBLE PRECISION NOT NULL,

        tiempo_espera_seg
          DOUBLE PRECISION NOT NULL,

        tiempo_salida_seg
          DOUBLE PRECISION NOT NULL,

        estado VARCHAR(30)
          DEFAULT 'Completado'
      );
    "
    
    # ======================================
    # TABLA 5: PRUEBAS ESTADISTICAS
    # ======================================
    
    tabla_pruebas <- "
      CREATE TABLE IF NOT EXISTS pruebas_estadisticas (

        id BIGSERIAL PRIMARY KEY,

        simulacion_id BIGINT NOT NULL
          REFERENCES simulaciones(id)
          ON DELETE CASCADE,

        nombre_prueba VARCHAR(100) NOT NULL,

        estadistico DOUBLE PRECISION,

        valor_p DOUBLE PRECISION,

        resultado VARCHAR(100),

        fecha_creacion TIMESTAMPTZ
          DEFAULT CURRENT_TIMESTAMP
      );
    "
    
    # ======================================
    # CREAR TABLAS AUTOMATICAMENTE
    # ======================================
    
    tablas <- list(
      semaforos = tabla_semaforos,
      simulaciones = tabla_simulaciones,
      vehiculos = tabla_vehiculos,
      resultados_trafico = tabla_resultados,
      pruebas_estadisticas = tabla_pruebas
    )
    
    # Ejecutar dentro de una transaccion
    DBI::dbWithTransaction(conexion, {
      
      for (nombre in names(tablas)) {
        
        DBI::dbExecute(
          conexion,
          tablas[[nombre]]
        )
        
      }
      
      # Crear semaforo inicial
      # No duplica registros al ejecutar otra vez
      DBI::dbExecute(
        conexion,
        "
        INSERT INTO semaforos (
          nombre,
          verde_segundos,
          amarillo_segundos,
          rojo_segundos
        )
        VALUES (
          'Semaforo principal',
          40,
          5,
          35
        )
        ON CONFLICT (nombre) DO NOTHING;
        "
      )
      
    })
    
    cat("\n================================\n")
    cat("BASE DE DATOS INICIALIZADA\n")
    cat("================================\n")
    
    for (nombre in names(tablas)) {
      cat("Tabla lista:", nombre, "\n")
    }
    
    cat("\nSemaforo principal configurado.\n")
    cat("Todas las operaciones fueron exitosas.\n")
    
    return(TRUE)
    
  }, error = function(error) {
    
    cat("\nERROR AL CREAR LAS TABLAS\n")
    cat(conditionMessage(error), "\n")
    
    return(FALSE)
    
  }, finally = {
    
    # Cerrar la conexion
    if (!is.null(conexion) &&
        DBI::dbIsValid(conexion)) {
      
      DBI::dbDisconnect(conexion)
    }
    
  })
  
}

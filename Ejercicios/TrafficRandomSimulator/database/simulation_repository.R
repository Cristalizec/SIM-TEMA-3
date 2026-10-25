
# ==========================================
# TRAFFIC RANDOM SIMULATOR
# Repositorio PostgreSQL
# ==========================================

source("database/connection.R")


# ==========================================
# GUARDAR SIMULACION COMPLETA
# ==========================================

guardar_simulacion <- function(
    simulacion,
    analisis) {
  
  conexion <- get_connection()
  
  on.exit(
    DBI::dbDisconnect(conexion),
    add = TRUE
  )
  
  sem <- simulacion$semaforo
  
  # Nombre unico para esta configuracion
  nombre_config <- paste0(
    "Config_V", sem$verde_segundos,
    "_A", sem$amarillo_segundos,
    "_R", sem$rojo_segundos
  )
  
  # Todas las operaciones se guardan
  # en una sola transaccion
  simulacion_id <- DBI::dbWithTransaction(
    conexion, {
      
      # 1. REGISTRAR CONFIGURACION DEL SEMAFORO
      semaforo_id <- DBI::dbGetQuery(
        conexion,
        "
        INSERT INTO semaforos (
          nombre,
          verde_segundos,
          amarillo_segundos,
          rojo_segundos
        )
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (nombre)
        DO UPDATE SET
          nombre = EXCLUDED.nombre
        RETURNING id
        ",
        params = list(
          nombre_config,
          as.integer(sem$verde_segundos),
          as.integer(sem$amarillo_segundos),
          as.integer(sem$rojo_segundos)
        )
      )$id[[1]]
      
      # 2. GUARDAR SIMULACION
      id <- DBI::dbGetQuery(
        conexion,
        "
        INSERT INTO simulaciones (
          semaforo_id,
          metodo,
          cantidad_vehiculos,
          tiempo_promedio_espera_seg,
          tiempo_total_seg
        )
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id
        ",
        params = list(
          semaforo_id,
          simulacion$metodo,
          as.integer(simulacion$cantidad_vehiculos),
          as.numeric(simulacion$promedio_espera),
          as.numeric(simulacion$tiempo_total)
        )
      )$id[[1]]
      
      # 3. GUARDAR VEHICULOS Y RESULTADOS
      vehiculos <- simulacion$vehiculos
      resultados <- simulacion$resultados
      
      for (i in seq_len(nrow(vehiculos))) {
        
        vehiculo <- vehiculos[i, ]
        resultado <- resultados[i, ]
        
        # Insertar vehiculo
        vehiculo_id <- DBI::dbGetQuery(
          conexion,
          "
          INSERT INTO vehiculos (
            simulacion_id,
            numero_vehiculo,
            tipo_vehiculo,
            velocidad_kmh,
            intervalo_llegada_seg,
            tiempo_llegada_seg,
            tiempo_cruce_seg
          )
          VALUES ($1, $2, $3, $4, $5, $6, $7)
          RETURNING id
          ",
          params = list(
            id,
            as.integer(vehiculo$numero_vehiculo),
            as.character(vehiculo$tipo_vehiculo),
            as.numeric(vehiculo$velocidad_kmh),
            as.numeric(vehiculo$intervalo_llegada_seg),
            as.numeric(vehiculo$tiempo_llegada_seg),
            as.numeric(vehiculo$tiempo_cruce_seg)
          )
        )$id[[1]]
        
        # Guardar resultados del vehiculo
        DBI::dbExecute(
          conexion,
          "
          INSERT INTO resultados_trafico (
            vehiculo_id,
            tiempo_inicio_cruce_seg,
            tiempo_espera_seg,
            tiempo_salida_seg,
            estado
          )
          VALUES ($1, $2, $3, $4, $5)
          ",
          params = list(
            vehiculo_id,
            as.numeric(
              resultado$tiempo_inicio_cruce_seg
            ),
            as.numeric(
              resultado$tiempo_espera_seg
            ),
            as.numeric(
              resultado$tiempo_salida_seg
            ),
            as.character(resultado$estado)
          )
        )
      }
      
      # 4. GUARDAR PRUEBAS ESTADISTICAS
      for (i in seq_len(nrow(analisis$pruebas))) {
        
        prueba <- analisis$pruebas[i, ]
        
        DBI::dbExecute(
          conexion,
          "
          INSERT INTO pruebas_estadisticas (
            simulacion_id,
            nombre_prueba,
            estadistico,
            valor_p,
            resultado
          )
          VALUES ($1, $2, $3, $4, $5)
          ",
          params = list(
            id,
            as.character(prueba$nombre_prueba),
            as.numeric(prueba$estadistico),
            as.numeric(prueba$valor_p),
            as.character(prueba$resultado)
          )
        )
      }
      
      id
    }
  )
  
  cat(
    "Simulacion guardada. ID:",
    as.character(simulacion_id),
    "\n"
  )
  
  return(simulacion_id)
}


# ==========================================
# CONSULTAR HISTORIAL
# ==========================================

consultar_historial <- function() {
  
  conexion <- get_connection()
  
  on.exit(
    DBI::dbDisconnect(conexion),
    add = TRUE
  )
  
  DBI::dbGetQuery(
    conexion,
    "
    SELECT
      s.id,
      s.metodo,
      s.cantidad_vehiculos,
      ROUND(
        s.tiempo_promedio_espera_seg::numeric,
        2
      ) AS espera_promedio_seg,
      ROUND(
        s.tiempo_total_seg::numeric,
        2
      ) AS tiempo_total_seg,
      s.fecha_creacion
    FROM simulaciones s
    ORDER BY s.id DESC
    LIMIT 100
    "
  )
}


# ==========================================
# CONSULTAR RESULTADOS GUARDADOS
# ==========================================

consultar_detalles <- function(simulacion_id) {
  
  conexion <- get_connection()
  
  on.exit(
    DBI::dbDisconnect(conexion),
    add = TRUE
  )
  
  DBI::dbGetQuery(
    conexion,
    "
    SELECT
      v.numero_vehiculo,
      v.tipo_vehiculo,
      v.velocidad_kmh,
      v.tiempo_llegada_seg,
      v.tiempo_cruce_seg,
      r.tiempo_inicio_cruce_seg,
      r.tiempo_espera_seg,
      r.tiempo_salida_seg
    FROM vehiculos v
    INNER JOIN resultados_trafico r
      ON r.vehiculo_id = v.id
    WHERE v.simulacion_id = $1
    ORDER BY v.numero_vehiculo
    ",
    params = list(as.numeric(simulacion_id))
  )
}


# ==========================================
# CONSULTAR PRUEBAS GUARDADAS
# ==========================================

consultar_pruebas <- function(simulacion_id) {
  
  conexion <- get_connection()
  
  on.exit(
    DBI::dbDisconnect(conexion),
    add = TRUE
  )
  
  DBI::dbGetQuery(
    conexion,
    "
    SELECT
      nombre_prueba,
      estadistico,
      valor_p,
      resultado
    FROM pruebas_estadisticas
    WHERE simulacion_id = $1
    ORDER BY id
    ",
    params = list(as.numeric(simulacion_id))
  )
}

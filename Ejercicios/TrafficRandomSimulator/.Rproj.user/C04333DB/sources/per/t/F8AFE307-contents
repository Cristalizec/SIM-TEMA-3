
# ==========================================
# TRAFFIC RANDOM SIMULATOR
# Generacion de dataset de trafico
# ==========================================

# Cargar modelo de vehiculos
source("models/vehiculo.R")

# Ruta del archivo CSV
RUTA_DATASET <- file.path(
  "dataset",
  "trafico.csv"
)


# ==========================================
# GENERAR DATASET ALEATORIO
# ==========================================

generar_dataset_trafico <- function(
    cantidad = 500,
    semilla = 123) {
  
  # Validar parametros
  if (!is.numeric(cantidad) ||
      length(cantidad) != 1 ||
      is.na(cantidad) ||
      !is.finite(cantidad) ||
      cantidad < 1 ||
      cantidad != floor(cantidad)) {
    
    stop("La cantidad debe ser un entero positivo.")
  }
  
  if (!is.numeric(semilla) ||
      length(semilla) != 1 ||
      is.na(semilla) ||
      !is.finite(semilla) ||
      semilla < 0 ||
      semilla > .Machine$integer.max ||
      semilla != floor(semilla)) {
    
    stop("La semilla debe ser un entero valido.")
  }
  
  # Permite repetir los resultados
  set.seed(semilla)
  
  # Generar tipos de vehiculos
  tipos <- sample(
    TIPOS_VEHICULOS,
    size = cantidad,
    replace = TRUE,
    prob = c(0.60, 0.25, 0.10, 0.05)
  )
  
  # Generar velocidades aleatorias
  velocidades <- vapply(
    tipos,
    generar_velocidad,
    numeric(1)
  )
  
  # Intervalos de llegada
  # Distribucion exponencial
  # Promedio: 6 segundos
  intervalos <- rexp(
    cantidad,
    rate = 1 / 6
  )
  
  intervalos <- pmax(
    round(intervalos, 2),
    0.01
  )
  
  # Tiempos de llegada acumulados
  llegadas <- round(
    cumsum(intervalos),
    2
  )
  
  # Tiempo medio de cruce por tipo
  medias_cruce <- c(
    Automovil = 4,
    Motocicleta = 3,
    Camion = 7,
    Autobus = 8
  )
  
  # Generar tiempos de cruce
  # Distribucion Gamma
  cruces <- rgamma(
    cantidad,
    shape = 4,
    scale = unname(
      medias_cruce[tipos]
    ) / 4
  )
  
  # Mantener tiempos entre 1 y 25 segundos
  cruces <- round(
    pmin(pmax(cruces, 1), 25),
    2
  )
  
  # Crear dataset
  datos <- data.frame(
    numero_vehiculo = seq_len(cantidad),
    tipo_vehiculo = tipos,
    velocidad_kmh = velocidades,
    intervalo_llegada_seg = intervalos,
    tiempo_llegada_seg = llegadas,
    tiempo_cruce_seg = cruces,
    stringsAsFactors = FALSE
  )
  
  # Crear carpeta dataset si no existe
  dir.create(
    "dataset",
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  # Guardar archivo CSV
  write.csv(
    datos,
    file = RUTA_DATASET,
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
  
  cat("\n================================\n")
  cat("DATASET GENERADO CORRECTAMENTE\n")
  cat("================================\n")
  
  cat("Total de vehiculos:", nrow(datos), "\n")
  cat("Archivo:", RUTA_DATASET, "\n")
  
  return(datos)
}


# ==========================================
# CARGAR DATASET
# ==========================================

cargar_dataset_trafico <- function() {
  
  # Crear dataset si no existe
  if (!file.exists(RUTA_DATASET)) {
    
    cat("Dataset no encontrado. Generando...\n")
    
    generar_dataset_trafico()
  }
  
  # Leer CSV
  datos <- read.csv(
    RUTA_DATASET,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8"
  )
  
  columnas <- c(
    "numero_vehiculo",
    "tipo_vehiculo",
    "velocidad_kmh",
    "intervalo_llegada_seg",
    "tiempo_llegada_seg",
    "tiempo_cruce_seg"
  )
  
  # Comprobar estructura
  if (!all(columnas %in% names(datos))) {
    
    stop(
      "El dataset no contiene todas las columnas."
    )
  }
  
  if (nrow(datos) == 0) {
    stop("El dataset esta vacio.")
  }
  
  # Validar valores
  columnas_numericas <- c(
    "velocidad_kmh",
    "intervalo_llegada_seg",
    "tiempo_llegada_seg",
    "tiempo_cruce_seg"
  )
  
  for (columna in columnas_numericas) {
    
    valores <- datos[[columna]]
    
    if (!is.numeric(valores) ||
        any(!is.finite(valores)) ||
        any(valores <= 0)) {
      
      stop(paste(
        "Datos invalidos en:",
        columna
      ))
    }
  }
  
  if (!all(datos$tipo_vehiculo %in%
           TIPOS_VEHICULOS)) {
    
    stop("Existen tipos de vehiculos invalidos.")
  }
  
  return(datos)
}


# ==========================================
# MOSTRAR RESUMEN DEL DATASET
# ==========================================

resumen_dataset <- function(datos) {
  
  cat("\n================================\n")
  cat("RESUMEN DEL TRAFICO\n")
  cat("================================\n")
  
  cat(
    "Total de vehiculos:",
    nrow(datos),
    "\n"
  )
  
  cat(
    "Velocidad promedio:",
    round(mean(datos$velocidad_kmh), 2),
    "km/h\n"
  )
  
  cat(
    "Tiempo promedio entre llegadas:",
    round(mean(datos$intervalo_llegada_seg), 2),
    "segundos\n"
  )
  
  cat(
    "Tiempo promedio de cruce:",
    round(mean(datos$tiempo_cruce_seg), 2),
    "segundos\n"
  )
  
  cat("\nVehiculos por tipo:\n")
  
  print(
    table(datos$tipo_vehiculo)
  )
}


# ==========================================
# TRAFFIC RANDOM SIMULATOR
# Servicio de simulacion
# ==========================================

source("config.R")
source("models/semaforo.R")
source("services/dataset_service.R")


# ==========================================
# GENERAR VARIABLES ALEATORIAS
# ==========================================

# Transformada inversa exponencial
generar_exponencial <- function(media) {
  
  u <- runif(1)
  
  valor <- -media * log1p(-u)
  
  return(list(
    valor = valor,
    uniformes = u
  ))
}


# Generar tiempo utilizando uno de
# los tres metodos de simulacion
generar_intervalo <- function(metodo, media) {
  
  if (!is.finite(media) || media <= 0) {
    stop("La media debe ser positiva.")
  }
  
  # Metodo 1: Transformada inversa
  if (metodo == "Transformada inversa") {
    
    return(generar_exponencial(media))
  }
  
  # Metodo 2: Convolucion
  # Suma de dos variables exponenciales
  if (metodo == "Convolución") {
    
    x1 <- generar_exponencial(media / 2)
    x2 <- generar_exponencial(media / 2)
    
    return(list(
      valor = x1$valor + x2$valor,
      uniformes = c(
        x1$uniformes,
        x2$uniformes
      )
    ))
  }
  
  # Metodo 3: Composicion
  # Mezcla de dos distribuciones
  if (metodo == "Composición") {
    
    seleccion <- runif(1)
    
    if (seleccion < 0.80) {
      
      x <- generar_exponencial(media * 0.75)
      
    } else {
      
      x <- generar_exponencial(media * 2)
    }
    
    return(list(
      valor = x$valor,
      uniformes = c(
        seleccion,
        x$uniformes
      )
    ))
  }
  
  stop("Metodo de generacion desconocido.")
}


# ==========================================
# SIMULAR TRAFICO VEHICULAR
# ==========================================

simular_trafico <- function(
    metodo,
    cantidad,
    semaforo,
    semilla = NULL) {
  
  # Validar metodo
  if (!metodo %in% METODOS_GENERACION) {
    stop("Selecciona un metodo valido.")
  }
  
  # Validar cantidad
  if (!is.numeric(cantidad) ||
      length(cantidad) != 1 ||
      is.na(cantidad) ||
      !is.finite(cantidad) ||
      cantidad < 1 ||
      cantidad > CONFIG_SIMULADOR$max_vehiculos ||
      cantidad != floor(cantidad)) {
    
    stop("Cantidad de vehiculos no valida.")
  }
  
  # Configurar semilla
  if (!is.null(semilla)) {
    
    set.seed(as.integer(semilla))
  }
  
  # Cargar dataset
  datos <- cargar_dataset_trafico()
  
  # Tomar muestras del dataset
  indices <- sample(
    seq_len(nrow(datos)),
    size = cantidad,
    replace = TRUE
  )
  
  muestras <- datos[indices, , drop = FALSE]
  
  # Obtener intervalo medio del dataset
  media_intervalo <- mean(
    datos$intervalo_llegada_seg
  )
  
  # Generar intervalos aleatorios
  intervalos <- numeric(cantidad)
  
  # Guardar numeros uniformes utilizados
  numeros_uniformes <- numeric(0)
  
  for (i in seq_len(cantidad)) {
    
    generado <- generar_intervalo(
      metodo,
      media_intervalo
    )
    
    intervalos[i] <- generado$valor
    
    numeros_uniformes <- c(
      numeros_uniformes,
      generado$uniformes
    )
  }
  
  # Llegadas acumuladas
  llegadas <- cumsum(intervalos)
  
  # Tomar los tiempos de cruce del dataset
  cruces <- muestras$tiempo_cruce_seg
  
  # Comprobar que los vehiculos puedan
  # completar el cruce en una fase verde
  if (any(cruces > semaforo$verde_segundos)) {
    
    stop(
      paste(
        "El tiempo verde es demasiado corto.",
        "Debe permitir completar el cruce."
      )
    )
  }
  
  # ======================================
  # CALCULAR FILA Y TIEMPOS DE ESPERA
  # ======================================
  
  inicio_cruce <- numeric(cantidad)
  espera <- numeric(cantidad)
  salida <- numeric(cantidad)
  
  # Un solo carril de salida
  tiempo_libre <- 0
  
  for (i in seq_len(cantidad)) {
    
    # El vehiculo espera si el carril
    # esta ocupado
    disponible <- max(
      llegadas[i],
      tiempo_libre
    )
    
    # Comprobar fase del semaforo
    inicio <- calcular_inicio_cruce(
      disponible,
      cruces[i],
      semaforo
    )
    
    # Calcular salida y espera
    inicio_cruce[i] <- inicio
    
    espera[i] <- max(
      0,
      inicio - llegadas[i]
    )
    
    salida[i] <- inicio + cruces[i]
    
    # El siguiente vehiculo debe esperar
    # hasta que termine el anterior
    tiempo_libre <- salida[i]
  }
  
  # ======================================
  # CREAR TABLA DE VEHICULOS
  # ======================================
  
  vehiculos <- data.frame(
    
    numero_vehiculo = seq_len(cantidad),
    
    tipo_vehiculo = muestras$tipo_vehiculo,
    
    velocidad_kmh = round(
      muestras$velocidad_kmh, 2
    ),
    
    intervalo_llegada_seg = round(
      intervalos, 2
    ),
    
    tiempo_llegada_seg = round(
      llegadas, 2
    ),
    
    tiempo_cruce_seg = round(
      cruces, 2
    ),
    
    stringsAsFactors = FALSE
  )
  
  # ======================================
  # CREAR TABLA DE RESULTADOS
  # ======================================
  
  resultados <- data.frame(
    
    numero_vehiculo = seq_len(cantidad),
    
    tiempo_inicio_cruce_seg = round(
      inicio_cruce, 2
    ),
    
    tiempo_espera_seg = round(
      espera, 2
    ),
    
    tiempo_salida_seg = round(
      salida, 2
    ),
    
    estado = rep(
      "Completado",
      cantidad
    ),
    
    stringsAsFactors = FALSE
  )
  
  # Calcular indicadores
  promedio_espera <- mean(espera)
  
  tiempo_total <- max(salida)
  
  maximo_espera <- max(espera)
  
  # ======================================
  # DEVOLVER SIMULACION COMPLETA
  # ======================================
  
  simulacion <- list(
    
    metodo = metodo,
    
    cantidad_vehiculos = cantidad,
    
    semaforo = semaforo,
    
    vehiculos = vehiculos,
    
    resultados = resultados,
    
    numeros_uniformes = numeros_uniformes,
    
    promedio_espera = promedio_espera,
    
    tiempo_total = tiempo_total,
    
    maximo_espera = maximo_espera
  )
  
  return(simulacion)
}

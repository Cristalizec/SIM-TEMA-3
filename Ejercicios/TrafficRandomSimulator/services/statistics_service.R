
# ==========================================
# TRAFFIC RANDOM SIMULATOR
# Pruebas estadisticas
# ==========================================

ALFA <- 0.05


# Crear resultado de una prueba
crear_resultado_prueba <- function(
    nombre, estadistico, valor_p, decision) {
  
  data.frame(
    nombre_prueba = nombre,
    estadistico = estadistico,
    valor_p = valor_p,
    resultado = decision,
    stringsAsFactors = FALSE
  )
}


# ==========================================
# PRUEBA DE UNIFORMIDAD
# Kolmogorov-Smirnov
# ==========================================

prueba_uniformidad <- function(numeros) {
  
  if (length(numeros) < 5) {
    
    return(crear_resultado_prueba(
      "Kolmogorov-Smirnov",
      NA_real_,
      NA_real_,
      "Datos insuficientes"
    ))
  }
  
  if (any(!is.finite(numeros)) ||
      any(numeros < 0 | numeros >= 1)) {
    
    stop("Los numeros deben estar entre 0 y 1.")
  }
  
  prueba <- stats::ks.test(
    numeros,
    "punif",
    min = 0,
    max = 1
  )
  
  valor_p <- as.numeric(prueba$p.value)
  
  decision <- if (valor_p < ALFA) {
    "Se rechaza H0"
  } else {
    "No se rechaza H0"
  }
  
  crear_resultado_prueba(
    "Kolmogorov-Smirnov",
    as.numeric(prueba$statistic),
    valor_p,
    decision
  )
}


# ==========================================
# PRUEBA DE INDEPENDENCIA
# Corridas respecto a 0.5
# ==========================================

prueba_independencia <- function(numeros) {
  
  n <- length(numeros)
  
  if (n < 10) {
    
    return(crear_resultado_prueba(
      "Prueba de corridas",
      NA_real_,
      NA_real_,
      "Datos insuficientes"
    ))
  }
  
  if (any(!is.finite(numeros)) ||
      any(numeros < 0 | numeros >= 1)) {
    
    stop("Los numeros deben estar entre 0 y 1.")
  }
  
  signos <- numeros >= 0.5
  
  n1 <- sum(signos)
  n2 <- n - n1
  
  if (n1 == 0 || n2 == 0) {
    
    return(crear_resultado_prueba(
      "Prueba de corridas",
      NA_real_,
      NA_real_,
      "Datos insuficientes"
    ))
  }
  
  # Contar corridas
  corridas <- 1 + sum(
    signos[-1] != signos[-n]
  )
  
  # Media esperada
  media <- 1 + (2 * n1 * n2) / n
  
  # Varianza esperada
  varianza <- (
    2 * n1 * n2 * (2 * n1 * n2 - n)
  ) / (
    n^2 * (n - 1)
  )
  
  if (varianza <= 0) {
    
    return(crear_resultado_prueba(
      "Prueba de corridas",
      NA_real_,
      NA_real_,
      "Datos insuficientes"
    ))
  }
  
  # Estadistico normal
  z <- (corridas - media) / sqrt(varianza)
  
  # Valor p bilateral
  valor_p <- 2 * stats::pnorm(
    -abs(z)
  )
  
  decision <- if (valor_p < ALFA) {
    "Se rechaza H0"
  } else {
    "No se rechaza H0"
  }
  
  crear_resultado_prueba(
    "Prueba de corridas",
    as.numeric(z),
    as.numeric(valor_p),
    decision
  )
}


# ==========================================
# ANALIZAR SIMULACION
# ==========================================

analizar_simulacion <- function(simulacion) {
  
  esperas <- simulacion$resultados$
    tiempo_espera_seg
  
  cruces <- simulacion$vehiculos$
    tiempo_cruce_seg
  
  # Estadisticas descriptivas
  resumen <- data.frame(
    
    cantidad_vehiculos =
      simulacion$cantidad_vehiculos,
    
    espera_promedio_seg =
      mean(esperas),
    
    mediana_espera_seg =
      median(esperas),
    
    desviacion_espera_seg =
      if (length(esperas) > 1) {
        sd(esperas)
      } else {
        0
      },
    
    espera_minima_seg =
      min(esperas),
    
    espera_maxima_seg =
      max(esperas),
    
    cruce_promedio_seg =
      mean(cruces),
    
    tiempo_total_seg =
      simulacion$tiempo_total
  )
  
  # Pruebas de numeros uniformes
  uniformidad <- prueba_uniformidad(
    simulacion$numeros_uniformes
  )
  
  independencia <- prueba_independencia(
    simulacion$numeros_uniformes
  )
  
  pruebas <- rbind(
    uniformidad,
    independencia
  )
  
  return(list(
    resumen = resumen,
    pruebas = pruebas
  ))
}

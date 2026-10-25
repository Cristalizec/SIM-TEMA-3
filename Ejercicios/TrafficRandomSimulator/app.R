
# ==========================================
# TRAFFIC RANDOM SIMULATOR
# Aplicacion principal
# ==========================================

library(shiny)
library(DBI)
library(RPostgres)
library(ggplot2)
library(DT)


# Cargar configuracion
source("config.R")


# Cargar conexion y tablas
source("database/init_db.R")


# Cargar modelos y servicios
source("services/simulation_service.R")

source("services/statistics_service.R")


# Cargar repositorio PostgreSQL
source("database/simulation_repository.R")


# Cargar interfaz
source("views/dashboard.R")


# Inicializar base de datos
base_correcta <- crear_tablas()

if (!base_correcta) {
  
  stop(
    "No fue posible inicializar PostgreSQL."
  )
}


cat("\n================================\n")
cat("TRAFFIC RANDOM SIMULATOR\n")
cat("================================\n")
cat("PostgreSQL preparado correctamente.\n")
cat("Iniciando interfaz Shiny...\n")


# Ejecutar aplicacion
shinyApp(
  ui = crear_ui(),
  server = servidor_dashboard
)


# ==========================================
# TRAFFIC RANDOM SIMULATOR
# Interfaz grafica con Shiny
# ==========================================

library(shiny)
library(ggplot2)
library(DT)


# ==========================================
# INTERFAZ DEL USUARIO
# ==========================================

crear_ui <- function() {
  
  fluidPage(
    
    tags$head(
      tags$style(HTML("
        body {
          background-color: #f3f6fa;
        }

        .titulo-principal {
          background-color: #16324f;
          color: white;
          padding: 22px;
          border-radius: 12px;
          margin-bottom: 20px;
        }

        .tarjeta {
          background-color: white;
          padding: 18px;
          border-radius: 10px;
          margin-bottom: 15px;
          border: 1px solid #dde3ea;
        }

        .tarjeta h2 {
          margin-top: 5px;
          color: #1764a0;
        }
      "))
    ),
    
    div(
      class = "titulo-principal",
      h2("Traffic Random Simulator"),
      p(
        "Simulacion de trafico vehicular ",
        "mediante variables aleatorias"
      )
    ),
    
    sidebarLayout(
      
      # PANEL DE CONFIGURACION
      sidebarPanel(
        width = 3,
        
        h4("Configuracion"),
        
        selectInput(
          "metodo",
          "Metodo de generacion",
          choices = METODOS_GENERACION
        ),
        
        numericInput(
          "cantidad",
          "Cantidad de vehiculos",
          value = 100,
          min = 1,
          max = 1000,
          step = 1
        ),
        
        checkboxInput(
          "usar_semilla",
          "Utilizar semilla fija",
          value = TRUE
        ),
        
        numericInput(
          "semilla",
          "Semilla aleatoria",
          value = 123,
          min = 0,
          step = 1
        ),
        
        hr(),
        
        h4("Semaforo"),
        
        numericInput(
          "verde",
          "Verde (segundos)",
          value = 40,
          min = 25,
          max = 120,
          step = 1
        ),
        
        numericInput(
          "amarillo",
          "Amarillo (segundos)",
          value = 5,
          min = 0,
          max = 30,
          step = 1
        ),
        
        numericInput(
          "rojo",
          "Rojo (segundos)",
          value = 35,
          min = 1,
          max = 120,
          step = 1
        ),
        
        hr(),
        
        actionButton(
          "simular",
          "Iniciar simulacion",
          class = "btn-success",
          width = "100%"
        )
      ),
      
      # PANEL PRINCIPAL
      mainPanel(
        width = 9,
        
        tabsetPanel(
          
          # RESULTADOS
          tabPanel(
            "Resultados",
            
            br(),
            
            uiOutput("mensaje"),
            
            uiOutput("indicadores"),
            
            h4("Vehiculos simulados"),
            
            DTOutput("tabla_resultados")
          ),
          
          # GRAFICAS
          tabPanel(
            "Graficas",
            
            br(),
            
            h4("Tiempos de espera"),
            
            plotOutput(
              "grafica_esperas",
              height = "330px"
            ),
            
            h4("Tipos de vehiculos"),
            
            plotOutput(
              "grafica_tipos",
              height = "330px"
            )
          ),
          
          # PRUEBAS ESTADISTICAS
          tabPanel(
            "Estadisticas",
            
            br(),
            
            h4("Pruebas estadisticas"),
            
            DTOutput("tabla_pruebas"),
            
            p(
              "Las pruebas se aplican a los ",
              "numeros uniformes generados."
            )
          ),
          
          # DATASET
          tabPanel(
            "Dataset",
            
            br(),
            
            h4("Dataset de trafico"),
            
            DTOutput("tabla_dataset"),
            
            plotOutput(
              "grafica_dataset",
              height = "320px"
            )
          ),
          
          # POSTGRESQL
          tabPanel(
            "PostgreSQL",
            
            br(),
            
            h4("Historial de simulaciones"),
            
            actionButton(
              "refrescar",
              "Actualizar historial"
            ),
            
            br(),
            br(),
            
            DTOutput("tabla_historial"),
            
            hr(),
            
            selectInput(
              "historial_id",
              "Seleccionar simulacion",
              choices = character(0)
            ),
            
            h4("Vehiculos guardados"),
            
            DTOutput("tabla_detalles"),
            
            h4("Pruebas guardadas"),
            
            DTOutput("tabla_pruebas_guardadas")
          )
        )
      )
    )
  )
}


# ==========================================
# SERVIDOR SHINY
# ==========================================

servidor_dashboard <- function(
    input,
    output,
    session) {
  
  # Guardar resultados de la sesion
  simulacion_actual <- reactiveVal(NULL)
  
  analisis_actual <- reactiveVal(NULL)
  
  id_guardado <- reactiveVal(NULL)
  
  historial_actual <- reactiveVal(data.frame())
  
  
  # ======================================
  # BOTON INICIAR SIMULACION
  # ======================================
  
  observeEvent(input$simular, {
    
    tryCatch({
      
      # Crear semaforo configurado
      semaforo <- crear_semaforo(
        verde_segundos = input$verde,
        amarillo_segundos = input$amarillo,
        rojo_segundos = input$rojo
      )
      
      # Configurar semilla
      semilla <- if (input$usar_semilla) {
        input$semilla
      } else {
        NULL
      }
      
      # Generar simulacion
      resultado <- simular_trafico(
        metodo = input$metodo,
        cantidad = input$cantidad,
        semaforo = semaforo,
        semilla = semilla
      )
      
      # Analizar resultados
      analisis <- analizar_simulacion(
        resultado
      )
      
      # Guardar resultados en memoria
      simulacion_actual(resultado)
      
      analisis_actual(analisis)
      
      id_guardado(NULL)
      
      # Guardar automaticamente en PostgreSQL
      tryCatch({
        
        identificador <- guardar_simulacion(
          resultado,
          analisis
        )
        
        id_guardado(
          as.character(identificador)
        )
        
        historial_actual(
          consultar_historial()
        )
        
        showNotification(
          "Simulacion guardada correctamente",
          type = "message"
        )
        
      }, error = function(error) {
        
        showNotification(
          paste(
            "Simulacion generada, pero no guardada:",
            conditionMessage(error)
          ),
          type = "warning",
          duration = 10
        )
        
      })
      
    }, error = function(error) {
      
      showNotification(
        conditionMessage(error),
        type = "error",
        duration = 10
      )
      
    })
    
  })
  
  
  # ======================================
  # MENSAJE DE ESTADO
  # ======================================
  
  output$mensaje <- renderUI({
    
    req(simulacion_actual())
    
    id <- id_guardado()
    
    if (is.null(id)) {
      
      div(
        class = "alert alert-warning",
        "Simulacion generada. ",
        "No se ha confirmado su guardado."
      )
      
    } else {
      
      div(
        class = "alert alert-success",
        paste(
          "Simulacion guardada en PostgreSQL.",
          "ID:", id
        )
      )
    }
  })
  
  
  # ======================================
  # INDICADORES GENERALES
  # ======================================
  
  output$indicadores <- renderUI({
    
    resultado <- simulacion_actual()
    
    req(resultado)
    
    fluidRow(
      
      column(
        4,
        div(
          class = "tarjeta",
          
          h4("Vehiculos"),
          
          h2(resultado$cantidad_vehiculos)
        )
      ),
      
      column(
        4,
        div(
          class = "tarjeta",
          
          h4("Espera promedio"),
          
          h2(
            sprintf(
              "%.2f s",
              resultado$promedio_espera
            )
          )
        )
      ),
      
      column(
        4,
        div(
          class = "tarjeta",
          
          h4("Tiempo total"),
          
          h2(
            sprintf(
              "%.2f s",
              resultado$tiempo_total
            )
          )
        )
      )
    )
  })
  
  
  # ======================================
  # TABLA DE RESULTADOS
  # ======================================
  
  output$tabla_resultados <- renderDT({
    
    resultado <- simulacion_actual()
    
    req(resultado)
    
    tabla <- cbind(
      resultado$vehiculos,
      resultado$resultados[
        c(
          "tiempo_inicio_cruce_seg",
          "tiempo_espera_seg",
          "tiempo_salida_seg"
        )
      ]
    )
    
    datatable(
      tabla,
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      rownames = FALSE
    )
  })
  
  
  # ======================================
  # GRAFICA DE ESPERAS
  # ======================================
  
  output$grafica_esperas <- renderPlot({
    
    resultado <- simulacion_actual()
    
    req(resultado)
    
    datos <- resultado$resultados
    
    ggplot(
      datos,
      aes(
        x = numero_vehiculo,
        y = tiempo_espera_seg
      )
    ) +
      geom_line(
        color = "#1764a0",
        linewidth = 0.8
      ) +
      labs(
        title = "Tiempo de espera por vehiculo",
        x = "Numero de vehiculo",
        y = "Espera (segundos)"
      ) +
      theme_minimal()
  })
  
  
  # ======================================
  # GRAFICA DE TIPOS DE VEHICULOS
  # ======================================
  
  output$grafica_tipos <- renderPlot({
    
    resultado <- simulacion_actual()
    
    req(resultado)
    
    ggplot(
      resultado$vehiculos,
      aes(
        x = tipo_vehiculo,
        fill = tipo_vehiculo
      )
    ) +
      geom_bar() +
      labs(
        title = "Cantidad de vehiculos por tipo",
        x = "Tipo",
        y = "Cantidad"
      ) +
      theme_minimal() +
      theme(
        legend.position = "none"
      )
  })
  
  
  # ======================================
  # TABLA DE PRUEBAS ESTADISTICAS
  # ======================================
  
  output$tabla_pruebas <- renderDT({
    
    analisis <- analisis_actual()
    
    req(analisis)
    
    datatable(
      analisis$pruebas,
      options = list(
        pageLength = 5,
        dom = "t"
      ),
      rownames = FALSE
    )
  })
  
  
  # ======================================
  # DATASET
  # ======================================
  
  output$tabla_dataset <- renderDT({
    
    datos <- cargar_dataset_trafico()
    
    datatable(
      datos,
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      rownames = FALSE
    )
  })
  
  
  # ======================================
  # GRAFICA DEL DATASET
  # ======================================
  
  output$grafica_dataset <- renderPlot({
    
    datos <- cargar_dataset_trafico()
    
    ggplot(
      datos,
      aes(
        x = tipo_vehiculo,
        fill = tipo_vehiculo
      )
    ) +
      geom_bar() +
      labs(
        title = "Distribucion del dataset",
        x = "Tipo de vehiculo",
        y = "Frecuencia"
      ) +
      theme_minimal() +
      theme(
        legend.position = "none"
      )
  })
  
  
  # ======================================
  # ACTUALIZAR HISTORIAL
  # ======================================
  
  observeEvent(
    input$refrescar,
    {
      
      tryCatch({
        
        historial_actual(
          consultar_historial()
        )
        
      }, error = function(error) {
        
        showNotification(
          conditionMessage(error),
          type = "error"
        )
        
      })
      
    },
    ignoreNULL = FALSE
  )
  
  
  # Actualizar opciones del historial
  observeEvent(historial_actual(), {
    
    datos <- historial_actual()
    
    if (nrow(datos) > 0) {
      
      ids <- as.character(datos$id)
      
      choices <- setNames(
        ids,
        paste("Simulacion", ids)
      )
      
      updateSelectInput(
        session,
        "historial_id",
        choices = choices,
        selected = ids[1]
      )
    }
  })
  
  
  # ======================================
  # TABLA DEL HISTORIAL
  # ======================================
  
  output$tabla_historial <- renderDT({
    
    datos <- historial_actual()
    
    if (nrow(datos) == 0) {
      
      datos <- data.frame(
        Mensaje = "Sin simulaciones guardadas"
      )
    }
    
    datatable(
      datos,
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      rownames = FALSE
    )
  })
  
  
  # ======================================
  # DETALLES DE SIMULACION GUARDADA
  # ======================================
  
  output$tabla_detalles <- renderDT({
    
    req(input$historial_id)
    
    datos <- consultar_detalles(
      input$historial_id
    )
    
    datatable(
      datos,
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      rownames = FALSE
    )
  })
  
  
  # ======================================
  # PRUEBAS GUARDADAS EN POSTGRESQL
  # ======================================
  
  output$tabla_pruebas_guardadas <- renderDT({
    
    req(input$historial_id)
    
    datos <- consultar_pruebas(
      input$historial_id
    )
    
    datatable(
      datos,
      options = list(
        pageLength = 5,
        scrollX = TRUE
      ),
      rownames = FALSE
    )
  })
  
}

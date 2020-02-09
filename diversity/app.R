library(shiny)
library(shinyFiles)
library(immunarch)
data(immdata)


ui <- fluidPage(
    sidebarLayout(
        sidebarPanel(
            shinyDirButton(
                'folder',
                'Load data',
                'Select a folder with data:',
                FALSE,
                class = 'btn-success',
            ),
            verbatimTextOutput("dir", placeholder = TRUE),
            selectInput(
                'method',
                'Choose estimation method',
                choices = list('chao1', 'hill', 'div', 'gini.simp',
                            'inv.simp', 'gini', 'raref', 'd50', 'dxx'),
            ),
            checkboxInput(
                'grouped',
                'Group data?',
            ),
            conditionalPanel(
                condition = "input.grouped == true",
                uiOutput("groupSelection"),
            ),
        ),
        mainPanel(
            tabsetPanel(
                type = "tabs", 
                tabPanel("Plot", plotOutput("plot")), 
                tabPanel("Metadata", tableOutput("metadata"), class = 'rightAlign')
            )
        )
    )
)

server <- function(input, output, session) {
    shinyDirChoose(
        input,
        'folder',
        roots = c(wd = '/'),
    )
    
    immdata <- reactiveValues(data = immdata)
    global <- reactiveValues(datapath = getwd())
    folder <- reactive(input$folder)

    output$dir <- renderText({
        global$datapath
    })
    
    observeEvent(
        eventExpr = {
            input$folder
        },
        handlerExpr = {
            if (!"path" %in% names(folder())) return()
            req(is.list(input$folder))
            wd <- normalizePath("/")
            global$datapath <-
                 file.path(wd, paste(unlist(folder()$path[-1]), collapse = .Platform$file.sep))
            immdata$data <- repLoad(global$datapath)
            immdata$data$data <- lapply(immdata$data$data, setDT)
            updateCheckboxInput(
                session = session,
                inputId = 'grouped',
                value = FALSE,
            )
        },
    )
    
    observe({
        req(!input$grouped)
        output$groupSelection <- renderUI({
            checkboxGroupInput(
                'by',
                'Choose data grouping:',
                choices = colnames(immdata$data$meta),
            )
        })
    })
    
    observe({
        div_data <- repDiversity(
            immdata$data$data,
            input$method
        )
        
        output$metadata <- renderTable(
            immdata$data$meta,
        )
        
        if (length(input$by) == 0) {
            output$plot <- renderPlot({
                vis(
                    div_data,
                    .by = NA,
                    .meta = NA,
                )
            })
            return()
        }
        
        by <- input$by
        meta <- immdata$data$meta
        
        output$plot <- renderPlot({
            vis(
                div_data,
                .by = by,
                .meta = meta,
            )
        })
    })
}

shinyApp(
    ui=ui,
    server=server
)

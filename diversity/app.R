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
                F,
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
                checkboxGroupInput(
                    'by',
                    'Choose data grouping:',
                    choices = colnames(immdata$meta),
                ),
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

server <- function(input, output) {
    shinyDirChoose(
        input,
        'folder',
        roots = c(wd = '/'),
    )

    global <- reactiveValues(datapath = getwd())

    folder <- reactive(input$folder)

    output$dir <- renderText({
        global$datapath
    })
    
    observeEvent(
        ignoreNULL = TRUE,
        eventExpr = {
            input$folder
        },
        handlerExpr = {
            if (!"path" %in% names(folder())) return()
            req(is.list(input$folder))
            wd <- normalizePath("/")
            global$datapath <-
                 file.path(wd, paste(unlist(folder()$path[-1]), collapse = .Platform$file.sep))
            immdata <- repLoad(global$datapath)
        }
    )
    
    observe({
        div_data <- repDiversity(
            immdata$data,
            input$method
        )
        by <- if (input$grouped) input$by else NA
        meta <- if (input$grouped) immdata$meta else NA
        
        output$metadata <- renderTable(
            immdata$meta,
        )

        output$plot <- renderPlot({
            vis(
                div_data,
                .by = by,
                .meta = meta,
            )
        })
    })
}

runApp(list(
    ui=ui,
    server=server
))

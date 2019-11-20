library(shiny)
library(immunarch)
data(immdata)


ui <- fluidPage(
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
    plotOutput('plot'),
)

server <- function(input, output) {
    observe({
        div_data <- repDiversity(
            immdata$data,
            input$method
        )
        by <- if (input$grouped) input$by else NA
        meta <- if (input$grouped) immdata$meta else NA
        
        output$plot <- renderPlot({
            vis(
                div_data,
                .by = by,
                .meta = meta,
            )
        })
    })
}

shinyApp(ui = ui, server = server)

library(shiny)
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
        value = F,
    ),
    conditionalPanel(
        condition = "input.grouped == true",
        checkboxGroupInput(
            'by',
            'Choose data grouping:',
            choices = colnames(immdata$meta),
    ),
    plotOutput('plot'),
    ),
)

server <- function(input, output) {
    div_data <- reactive(repDiversity(immdata$data, input$method))
    by <- reactive(if (input$grouped) input$by else NA)
    meta <- reactive(if (input$grouped) immdata$meta else NA)

    output$plot <- renderPlot({
        vis(
            div_data(),
            .by = by(),
            .meta = meta(),
        )
    })
}

shinyApp(ui = ui, server = server)

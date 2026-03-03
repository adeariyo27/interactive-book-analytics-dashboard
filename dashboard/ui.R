library(shiny)
library(shinydashboard)
library(plotly)
library(ggplot2)
library(dplyr)
library(lubridate)

# ================= DATA =================
set.seed(123)
n <- 1000

data <- data.frame(
  judul = paste("Buku", sample(1:200, n, replace = TRUE)),
  genre = sample(c("Romance","Fantasy","Horror","Sci-Fi","Drama"), n, replace = TRUE),
  harga = sample(50000:150000, n, replace = TRUE),
  halaman = sample(100:600, n, replace = TRUE),
  rating = sample(1:5, n, replace = TRUE),
  penulis = paste("Penulis", sample(1:50, n, replace = TRUE)),
  penerbit = paste("Penerbit", sample(1:20, n, replace = TRUE)),
  user = paste("User", sample(1:300, n, replace = TRUE)),
  gender = sample(c("Laki-laki","Perempuan"), n, replace = TRUE),
  kota = sample(c("Jakarta","Bandung","Surabaya","Medan","Yogyakarta"), n, replace = TRUE),
  tanggal = sample(seq(as.Date('2022-01-01'),
                       as.Date('2023-12-31'),
                       by="day"), n, replace = TRUE),
  tahun_lahir = sample(1970:2010, n, replace = TRUE)
)

data$tahun <- year(data$tanggal)
data$bulan <- month(data$tanggal)
data$nama_bulan <- month.name[data$bulan]

data$usia <- year(Sys.Date()) - data$tahun_lahir
data$kelompok_usia <- cut(
  data$usia,
  breaks = c(0,17,25,35,45,60,100),
  labels = c("<18","18-25","26-35","36-45","46-60","60+")
)

# ================= UI =================
ui <- dashboardPage(
  dashboardHeader(disable = TRUE),
  
  dashboardSidebar(
    sidebarMenu(id="tabs", selected="ringkasan",
                menuItem("Overview", tabName="ringkasan"),
                menuItem("Books", tabName="books"),
                menuItem("Author", tabName="author"),
                menuItem("User", tabName="user"),
                menuItem("Team", tabName="team")
    )
  ),
  
  dashboardBody(
    
    tags$head(tags$style(HTML("
      .main-sidebar {
        position: relative;
        width: 100% !important;
        height: auto;
        background: transparent;
        border: none;
      }
      .content-wrapper, .right-side {
        margin-left: 0 !important;
        background: #f4f6f9;
      }
      .sidebar-menu {
        display: flex;
        justify-content: center;
        gap: 40px;
        background: white;
        padding: 15px 40px;
        border-radius: 40px;
        width: fit-content;
        margin: 20px auto;
        box-shadow: 0 5px 20px rgba(0,0,0,0.08);
        font-weight: 600;
      }
      .sidebar-menu > li { float: none; }
      .small-box {border-radius:15px;}
      .box {border-radius:15px;}
      .book-row {display:flex; gap:20px; flex-wrap:wrap;}
      .book-card {
        width:48%;
        background:white;
        padding:15px;
        border-radius:15px;
        box-shadow:0 4px 12px rgba(0,0,0,0.08);
        display:flex;
        gap:15px;
        align-items:center;
      }
      .book-img {
        width:120px;
        height:80px;
        object-fit:cover;
        border-radius:10px;
      }
      .team-row {
        display:flex;
        justify-content:space-between;
        gap:20px;
        margin-top:30px;
      }
      .team-card {
        width:23%;
        background:white;
        padding:30px;
        border-radius:20px;
        text-align:center;
        box-shadow:0 4px 12px rgba(0,0,0,0.08);
      }
      .team-img {
        width:120px;
        height:120px;
        border-radius:50%;
        object-fit:cover;
        margin-bottom:15px;
      }
    "))),
    
    tabItems(
      
      # ================= OVERVIEW =================
      tabItem(tabName="ringkasan",
              fluidRow(
                box(width=6,
                    selectInput("tahun_filter","Pilih Tahun",
                                choices=sort(unique(data$tahun)),
                                selected=max(data$tahun))),
                box(width=6,
                    selectInput("bulan_filter","Pilih Bulan",
                                choices=month.name,
                                selected=month.name[1]))
              ),
              fluidRow(
                valueBoxOutput("total_titles", width=6),
                valueBoxOutput("total_reviews", width=6)
              ),
              fluidRow(
                valueBoxOutput("total_users", width=6),
                valueBoxOutput("global_rating", width=6)
              ),
              fluidRow(
                box(width=3,"Distribusi Rating",plotlyOutput("donut_plot")),
                box(width=3,"Distribusi Genre",plotlyOutput("genre_plot")),
                box(width=3,"Trend Bulanan",plotlyOutput("trend_plot")),
                box(width=3,"Top 5 Genre",plotlyOutput("top_genre_plot"))
              ),
              box(width=12,"Top 5 Buku",uiOutput("top_books_landscape"))
      ),
      
      # ================= BOOKS =================
      tabItem(tabName="books",
              fluidRow(
                box(width=6,"Rata-rata Rating per Penulis",plotlyOutput("avg_author")),
                box(width=6,"Rata-rata Halaman per Genre",plotlyOutput("avg_pages"))
              ),
              fluidRow(
                box(width=6,"Distribusi Rating (1-5)",plotlyOutput("rating_scale")),
                box(width=6,"Distribusi Genre",plotlyOutput("genre_dist"))
              ),
              box(width=12,"Top 10 Buku Terpopuler",uiOutput("top10")),
              box(width=12,"Buku Potensial (Underrated)",uiOutput("underrated"))
      ),
      
      # ================= AUTHOR =================
      tabItem(tabName="author",
              fluidRow(
                box(width=6,"Rata-rata Rating per Penulis",plotlyOutput("avg_author_rating")),
                box(width=6,"Rata-rata Rating per Penerbit",plotlyOutput("avg_publisher_rating"))
              ),
              fluidRow(
                box(width=6,"Kombinasi Penulis-Penerbit Terbanyak",plotlyOutput("author_publisher_combo")),
                box(width=6,"Penulis Terpopuler",plotlyOutput("most_popular_author"))
              )
      ),
      
      # ================= USER =================
      tabItem(tabName="user",
              fluidRow(
                box(width=6,"Distribusi Kelompok Usia",plotlyOutput("age_group_plot")),
                box(width=6,"Distribusi Kota",plotlyOutput("kota_plot"))
              ),
              fluidRow(
                box(width=6,"Distribusi Rating",plotlyOutput("user_rating_dist")),
                box(width=6,"Pengguna Paling Aktif",plotlyOutput("active_user_plot"))
              ),
              box(width=12,"Distribusi Gender",plotlyOutput("gender_plot"))
      ),
      
      # ================= TEAM =================
      tabItem(tabName="team",
              h2("Tim Pengembang Dashboard", align="center"),
              div(class="team-row",
                  div(class="team-card",
                      tags$img(src="https://picsum.photos/200?1", class="team-img"),
                      h4("Ade Ariyo Yudanto"),
                      p("Database Manager")),
                  div(class="team-card",
                      tags$img(src="https://picsum.photos/200?2", class="team-img"),
                      h4("Natalinda Erlina Amheka"),
                      p("Data Analyst")),
                  div(class="team-card",
                      tags$img(src="https://picsum.photos/200?3", class="team-img"),
                      h4("Muhammad Hanif Nafiis"),
                      p("Backend Developer")),
                  div(class="team-card",
                      tags$img(src="https://picsum.photos/200?4", class="team-img"),
                      h4("Rizky Mardhatillah"),
                      p("Frontend Developer"))
              )
      )
      
    )
  )
)

# ================= SERVER =================
server <- function(input, output, session){
  
  filtered_data <- reactive({
    data %>%
      filter(tahun==input$tahun_filter,
             nama_bulan==input$bulan_filter)
  })
  
  # OVERVIEW
  output$total_titles <- renderValueBox({
    valueBox(length(unique(filtered_data()$judul)),"Total Judul",icon=icon("book"),color="purple")
  })
  output$total_reviews <- renderValueBox({
    valueBox(nrow(filtered_data()),"Total Ulasan",icon=icon("comments"),color="aqua")
  })
  output$total_users <- renderValueBox({
    valueBox(length(unique(filtered_data()$user)),"Total User",icon=icon("users"),color="green")
  })
  output$global_rating <- renderValueBox({
    valueBox(round(mean(filtered_data()$rating),2),"Rata-rata Rating",icon=icon("star"),color="yellow")
  })
  output$donut_plot <- renderPlotly({
    r <- filtered_data() %>% count(rating)
    plot_ly(r, labels=~rating, values=~n, type='pie', hole=0.6)
  })
  output$genre_plot <- renderPlotly({
    g <- filtered_data() %>% count(genre)
    plot_ly(g, x=~n, y=~reorder(genre,n), type="bar", orientation="h")
  })
  output$trend_plot <- renderPlotly({
    t <- filtered_data() %>% group_by(bulan) %>% summarise(total=n())
    plot_ly(t, x=~bulan, y=~total, type="scatter", mode="lines+markers")
  })
  output$top_genre_plot <- renderPlotly({
    g <- filtered_data() %>% count(genre) %>% arrange(desc(n)) %>% head(5)
    plot_ly(g, x=~n, y=~reorder(genre,n), type="bar", orientation="h")
  })
  output$top_books_landscape <- renderUI({
    top_books <- filtered_data() %>% count(judul) %>% arrange(desc(n)) %>% head(5)
    div(class="book-row",
        lapply(1:nrow(top_books), function(i){
          div(class="book-card",
              tags$img(src=paste0("https://picsum.photos/200/120?random=",i),
                       class="book-img"),
              strong(top_books$judul[i])
          )
        }))
  })
  
  # BOOKS
  output$avg_author <- renderPlotly({
    p <- data %>% group_by(penulis) %>%
      summarise(avg=mean(rating)) %>% arrange(desc(avg)) %>% head(15)
    plot_ly(p, x=~avg, y=~reorder(penulis,avg), type="bar", orientation="h")
  })
  output$avg_pages <- renderPlotly({
    p <- data %>% group_by(genre) %>%
      summarise(avg_pages=mean(halaman))
    plot_ly(p, x=~avg_pages, y=~genre, type="bar", orientation="h")
  })
  output$rating_scale <- renderPlotly({
    r <- data %>% count(rating)
    plot_ly(r, x=~factor(rating), y=~n, type="bar")
  })
  output$genre_dist <- renderPlotly({
    g <- data %>% count(genre)
    plot_ly(g, x=~n, y=~genre, type="bar", orientation="h")
  })
  output$top10 <- renderUI({
    top_books <- data %>% count(judul) %>% arrange(desc(n)) %>% head(10)
    div(class="book-row",
        lapply(1:nrow(top_books), function(i){
          div(class="book-card",
              tags$img(src=paste0("https://picsum.photos/200/120?random=",i),
                       class="book-img"),
              strong(top_books$judul[i])
          )
        }))
  })
  output$underrated <- renderUI({
    stats <- data %>% group_by(judul) %>%
      summarise(avg_rating=mean(rating), total_review=n())
    under <- stats %>%
      filter(avg_rating>=4.5,
             total_review <= quantile(total_review,0.25)) %>%
      head(5)
    div(class="book-row",
        lapply(1:nrow(under), function(i){
          div(class="book-card",
              tags$img(src=paste0("https://picsum.photos/200/120?random=",i+30),
                       class="book-img"),
              strong(under$judul[i])
          )
        }))
  })
  
  # AUTHOR
  output$avg_author_rating <- renderPlotly({
    p <- data %>% group_by(penulis) %>%
      summarise(avg=mean(rating))
    plot_ly(p, x=~avg, y=~penulis, type="bar", orientation="h")
  })
  output$avg_publisher_rating <- renderPlotly({
    p <- data %>% group_by(penerbit) %>%
      summarise(avg=mean(rating))
    plot_ly(p, x=~avg, y=~penerbit, type="bar", orientation="h")
  })
  output$author_publisher_combo <- renderPlotly({
    combo <- data %>% count(penulis, penerbit) %>%
      arrange(desc(n)) %>% head(10)
    plot_ly(combo, x=~n, y=~paste(penulis,penerbit),
            type="bar", orientation="h")
  })
  output$most_popular_author <- renderPlotly({
    pop <- data %>% count(penulis) %>%
      arrange(desc(n)) %>% head(10)
    plot_ly(pop, x=~n, y=~penulis, type="bar", orientation="h")
  })
  
  # USER
  output$age_group_plot <- renderPlotly({
    g <- data %>% count(kelompok_usia)
    plot_ly(g, x=~kelompok_usia, y=~n, type="bar")
  })
  output$kota_plot <- renderPlotly({
    k <- data %>% count(kota)
    plot_ly(k, x=~kota, y=~n, type="bar")
  })
  output$user_rating_dist <- renderPlotly({
    r <- data %>% count(rating)
    plot_ly(r, x=~factor(rating), y=~n, type="bar")
  })
  output$active_user_plot <- renderPlotly({
    a <- data %>% count(user) %>% arrange(desc(n)) %>% head(10)
    plot_ly(a, x=~n, y=~user, type="bar", orientation="h")
  })
  output$gender_plot <- renderPlotly({
    g <- data %>% count(gender)
    plot_ly(g, x=~gender, y=~n, type="bar")
  })
  
}

shinyApp(ui, server)


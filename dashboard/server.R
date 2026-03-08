# ================= SERVER =================

server <- function(input, output, session){
  
  # ============================================================================
  # 1. OVERVIEW (RINGKASAN UMUM) - FULLY DYNAMIC & ALL-TIME SUPPORT
  # ============================================================================
  
    sql_filter <- reactive({
    kondisi <- "1=1"
    if(input$tahun_filter != "Semua Tahun") {
      kondisi <- paste0(kondisi, " AND YEAR(review_date) = ", input$tahun_filter)
    }
    if(input$bulan_filter != "Semua Bulan") {
      bulan_angka <- match(input$bulan_filter, month.name)
      bulan_angka <- match(input$bulan_filter, daftar_bulan) - 1 
      kondisi <- paste0(kondisi, " AND MONTH(review_date) = ", bulan_angka)
    }
    return(kondisi)
  })
  
  sql_filter_r <- reactive({
    kondisi <- "1=1"
    if(input$tahun_filter != "Semua Tahun") {
      kondisi <- paste0(kondisi, " AND YEAR(r.review_date) = ", input$tahun_filter)
    }
    if(input$bulan_filter != "Semua Bulan") {
      bulan_angka <- match(input$bulan_filter, daftar_bulan) - 1
      kondisi <- paste0(kondisi, " AND MONTH(r.review_date) = ", bulan_angka)
    }
    return(kondisi)
  })

  # --- KPI SCORECARDS ---
  output$total_titles <- renderValueBox({
    q <- sprintf("SELECT COUNT(DISTINCT b.book_id) AS total FROM tbl_books b LEFT JOIN tbl_reviews r ON b.book_id = r.book_id WHERE %s;", sql_filter_r())
    val <- dbGetQuery(koneksi_db, q)
    valueBox(val$total, "Jumlah Buku", icon=icon("book"), color="purple")
  })
  
  output$total_reviews <- renderValueBox({
    q <- sprintf("SELECT COUNT(review_id) AS total FROM tbl_reviews WHERE %s;", sql_filter())
    val <- dbGetQuery(koneksi_db, q)
    valueBox(val$total, "Jumlah Ulasan", icon=icon("comments"), color="aqua")
  })
  
  output$total_users <- renderValueBox({
    q <- sprintf("SELECT COUNT(DISTINCT u.user_id) AS total FROM tbl_users u LEFT JOIN tbl_reviews r ON u.user_id = r.user_id WHERE %s;", sql_filter_r())
    val <- dbGetQuery(koneksi_db, q)
    valueBox(val$total, "Jumlah Pengguna", icon=icon("users"), color="green")
  })
  
  output$global_rating <- renderValueBox({
    q <- sprintf("SELECT COALESCE(ROUND(AVG(rating), 2), 0) AS total FROM tbl_reviews WHERE %s;", sql_filter())
    val <- dbGetQuery(koneksi_db, q)
    valueBox(val$total, "Rata-rata Ulasan", icon=icon("star"), color="yellow")
  })

  # --- CHARTS ---
  output$donut_plot <- renderPlotly({
    q <- sprintf("SELECT rating, COUNT(review_id) AS n FROM tbl_reviews WHERE rating IS NOT NULL AND %s GROUP BY rating;", sql_filter())
    df <- dbGetQuery(koneksi_db, q)
    if (nrow(df) == 0) {
      return(
        plotly_empty() %>% layout(
          title = list(
            text = "Belum ada buku yang diulas pada periode ini.",
            x = 0.5,  # center horizontally
            xanchor = "center",
            font = list(color = "gray", size = 16)
          )
        )
      )
    }
    
    plot_ly(df, labels=~paste("⭐", rating), values=~n, type='pie', hole=0.5, 
            text = ~format(n, big.mark=".", decimal.mark=","), textposition = 'outside',
            textinfo='percent', hoverinfo='label+value',
            hovertemplate = "<b>%{label}</b><br>Jumlah Ulasan: %{text} <extra></extra>",
            marker=list(colors=c('#f1c40f', '#e67e22', '#e74c3c', '#9b59b6', '#34495e'))) %>%
      layout(showlegend = TRUE, 
             legend = list(orientation = 'h', x = 0.5, y = -0.2, xanchor = 'center'),
             margin = list(b = 40))
  })
  
  output$trend_plot <- renderPlotly({
    if(input$tahun_filter == "Semua Tahun") {
      q <- "SELECT DATE_FORMAT(review_date, '%Y-%m') AS bulan_label, COUNT(review_id) AS total 
            FROM tbl_reviews WHERE review_date IS NOT NULL GROUP BY bulan_label ORDER BY bulan_label ASC;"
      df <- dbGetQuery(koneksi_db, q)
      if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Tidak ada data"))
      
      df$bulan_label <- as.Date(paste0(df$bulan_label, "-01"))
      df$nama_bulan <- format(df$bulan_label, "%B %Y")  
      
      plot_ly(df, x=~bulan_label, y=~total, customdata = ~nama_bulan, type="scatter", mode="lines", 
              hovertemplate = "<b>%{customdata}</b> <br>Jumlah Ulasan: %{y} <extra></extra>",
              line=list(color='#3498db', width=3)) %>%
        layout(xaxis = list(title = "", 
                            type = "date",          
                            tickformat = "%Y",      
                            nticks = 10,
                            showgrid = FALSE),
               yaxis = list(title = "Jumlah Ulasan", showgrid = FALSE),
               margin = list(b = 40))
      
    } else {
      q <- sprintf("SELECT DATE_FORMAT(review_date, '%%m') AS bulan_angka, COUNT(review_id) AS total 
                    FROM tbl_reviews WHERE review_date IS NOT NULL AND YEAR(review_date) = %s 
                    GROUP BY bulan_angka ORDER BY bulan_angka ASC;", input$tahun_filter)
      df <- dbGetQuery(koneksi_db, q)
      if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Tidak ada data"))
      
      df$bulan_label <- month.name[as.numeric(df$bulan_angka)]
      df$bulan_label <- factor(df$bulan_label, levels = month.name)
      
      plot_ly(df, x=~bulan_label, y=~total, type="scatter", mode="lines+markers",
              hovertemplate = "<b>%{x}</b><br>Jumlah Ulasan: %{y} <extra></extra>",
              line=list(color='#3498db', width=3), marker=list(color='#2980b9', size=8)) %>%
        layout(xaxis = list(title = "", tickangle = -45, showgrid = FALSE), 
               yaxis = list(title = "Jumlah Ulasan", showgrid = FALSE),
               margin = list(b = 60))
    }
  })
  
  output$top_genre_plot <- renderPlotly({
    q <- sprintf("SELECT COALESCE(b.category, 'Lainnya') AS genre, COUNT(r.review_id) AS n 
                  FROM tbl_books b JOIN tbl_reviews r ON b.book_id = r.book_id 
                  WHERE %s GROUP BY genre ORDER BY n DESC LIMIT 5;", sql_filter_r())
    df <- dbGetQuery(koneksi_db, q)
    if (nrow(df) == 0) {
      return(
        plotly_empty() %>% layout(
          title = list(
            text = "Belum ada buku yang diulas pada periode ini.",
            x = 0.5,  # center horizontally
            xanchor = "center",
            font = list(color = "gray", size = 16)
          )
        )
      )
    }
    
    plot_ly(df, x=~n, y=~genre, type="bar", orientation="h", 
            hovertemplate = "<b>%{y}</b><br>Jumlah Ulasan: %{x}<extra></extra>",
            marker=list(color = ~n,                  
                        colorscale = 'Greens',       
                        reversescale = TRUE,         
                        showscale = FALSE)) %>%      
      layout(xaxis = list(title = "Jumlah Ulasan", showgrid = FALSE),
             yaxis = list(title = "", categoryorder = "total ascending", showgrid = FALSE), 
             margin = list(l = 120, t = 10, b = 30))
  })
  
  output$top_books_landscape <- renderUI({
   q <- sprintf("SELECT b.title AS judul, 
                         COALESCE(NULLIF(b.cover_book, ''), 'no-cover.jpg') AS cover,
                         COALESCE(a.author_name, 'Unknown') AS penulis,
                         COALESCE(p.publisher_name, 'Unknown') AS penerbit,
                         COALESCE(b.price, 0) AS harga,
                         COALESCE(b.pages, 0) AS halaman,
                         COALESCE(b.category, 'Unknown') AS genre
                  FROM tbl_books b 
                  LEFT JOIN tbl_authors a ON b.author_id = a.author_id
                  LEFT JOIN tbl_publishers p ON b.publisher_id = p.publisher_id
                  JOIN tbl_reviews r ON b.book_id = r.book_id 
                  WHERE %s 
                  GROUP BY b.book_id, b.title, b.cover_book, a.author_name, p.publisher_name, b.price, b.pages, b.category 
                  ORDER BY COUNT(r.review_id) DESC 
                  LIMIT 5;", sql_filter_r())
    df <- dbGetQuery(koneksi_db, q)
    if(nrow(df) == 0) return(h4("Belum ada buku yang diulas.", style="text-align:center; color:gray; padding:20px;"))
    
    div(class="book-row",
        lapply(1:nrow(df), function(i){
          # Struktur Flip Card
          div(class="flip-card", onclick="this.classList.toggle('flipped')",
              div(class="flip-card-inner",
                  div(class="flip-card-front", tags$img(src=df$cover[i], class="book-img"), span(df$judul[i])),
                  div(class="flip-card-back",
                      h5(df$judul[i]),
                      p(tags$b("Penulis: "), df$penulis[i]),
                      p(tags$b("Penerbit: "), df$penerbit[i]),
                      p(tags$b("Harga: "), paste0("Rp ", format(df$harga[i], big.mark=".", decimal.mark=","))),
                      p(tags$b("Halaman: "), df$halaman[i]),
                      p(tags$b("Genre: "), df$genre[i])
                  )
              )
          )
        }))
  })
  
  # ============================================================================
  # 2. BOOKS (ANALISIS PERFORMA BUKU & GENRE)
  # ============================================================================
  
  output$price_corr_plot <- renderPlotly({
    q <- "SELECT b.title, b.price, AVG(r.rating) AS avg_rating 
          FROM tbl_books b 
          JOIN tbl_reviews r ON b.book_id = r.book_id 
          WHERE b.price IS NOT NULL AND b.price > 0 
          GROUP BY b.book_id, b.title, b.price;"
    df <- dbGetQuery(koneksi_db, q)
    
    if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Tidak ada data"))
    
    df$harga_rp <- paste0("Rp ", formatC(df$price, format="f", big.mark=".", digits=0))

    plot_ly(df, x = ~price, y = ~avg_rating, type = "scatter", mode = "markers",
            text = ~paste("<b>", title, "</b>", "<br>Harga:", harga_rp, "<br>Rating:", round(avg_rating, 2)),
            hoverinfo = "text",
            marker = list(color = '#2ecc71', opacity = 0.5, size = 8)) %>%
      layout(xaxis = list(title = "Harga Buku", 
                          tickformat = ",.0f",      
                          tickprefix = "Rp ",
                          showgrid = FALSE),      
             yaxis = list(title = "Rata-rata Ulasan", showgrid = FALSE),
             margin = list(b = 40))
  })
  
  output$page_corr_plot <- renderPlotly({
    q <- "SELECT b.title, b.pages, AVG(r.rating) AS avg_rating 
          FROM tbl_books b 
          JOIN tbl_reviews r ON b.book_id = r.book_id 
          WHERE b.pages IS NOT NULL AND b.pages > 0 
          GROUP BY b.book_id, b.title, b.pages;"
    df <- dbGetQuery(koneksi_db, q)
    
    if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Tidak ada data"))
    
    plot_ly(df, x = ~pages, y = ~avg_rating, type = "scatter", mode = "markers",
            text = ~paste("<b>", title, "</b>", "<br>Jumlah Halaman:", pages, "<br>Rating:", round(avg_rating, 2)),
            hoverinfo = "text",
            marker = list(color = '#3498db', opacity = 0.5, size = 8)) %>%
      layout(xaxis = list(title = "Jumlah Halaman", showgrid = FALSE),
             yaxis = list(title = "Rata-rata Ulasan", showgrid = FALSE),
             margin = list(b = 40))
  })
  
  output$avg_pages <- renderPlotly({
    q <- "SELECT COALESCE(category, 'Uncategorized') AS genre, ROUND(AVG(pages), 0) AS avg_pages 
          FROM tbl_books WHERE pages > 0 
          GROUP BY genre ORDER BY avg_pages DESC LIMIT 15;"
    df <- dbGetQuery(koneksi_db, q)
    
    plot_ly(df, x = ~avg_pages, y = ~genre, type = "bar", orientation = "h",
            text = ~paste(avg_pages), textposition = 'inside', insidetextanchor = 'middle', textfont = list(color = 'white', weight = 'bold'),
            hoverinfo = 'none',
            marker = list(color = ~avg_pages, colorscale = 'Blues', reversescale = TRUE, showscale = FALSE)) %>%
      layout(xaxis = list(title = "Rata-rata Halaman", showgrid = FALSE),
             yaxis = list(title = "", categoryorder = "total ascending", showgrid = FALSE), 
             margin = list(l = 120, t = 10, b = 30))
  })
  
  output$rating_scale <- renderPlotly({
    df <- dbGetQuery(koneksi_db, "SELECT rating, COUNT(review_id) AS n FROM tbl_reviews WHERE rating IS NOT NULL GROUP BY rating;")
    
    df$label_bintang <- paste("⭐", df$rating)
      
    plot_ly(df, x = ~label_bintang, y = ~n, type = "bar",
            text = ~format(n, big.mark=".", decimal.mark=","), textposition = 'outside',
            hovertemplate = "<b>%{x}</b><br>Jumlah Ulasan: %{text} <extra></extra>",
            marker = list(color = ~n, colorscale = 'Oranges', reversescale = TRUE, showscale = FALSE)) %>%
      layout(xaxis = list(title = "", categoryorder = "category ascending", showgrid = FALSE),
             yaxis = list(title = "Jumlah Ulasan", showgrid = FALSE),
             margin = list(t = 20, b = 40))
  })
  
  output$genre_dist <- renderPlotly({
    q <- "SELECT COALESCE(category, 'Uncategorized') AS genre, COUNT(book_id) AS n 
          FROM tbl_books GROUP BY genre HAVING n > 0;"
    df <- dbGetQuery(koneksi_db, q)
    
    df$persentase <- round((df$n / sum(df$n)) * 100, 1)
    
    plot_ly(df, 
            labels = ~genre, 
            parents = rep("", nrow(df)), 
            values = ~n, 
            type = "treemap",
            textinfo = "label+value",
            customdata = ~paste0(persentase, "%"), 
            hovertemplate = "<b>%{label}</b><br>Jumlah Buku: %{value}<br>Proporsi: %{customdata}<extra></extra>",
            marker = list(colorscale = 'Purples')) %>%
      layout(margin = list(l = 10, r = 10, t = 10, b = 10))
  })
  
  output$top5 <- renderUI({
    # Menambahkan SELECT dan LEFT JOIN untuk data belakang kartu
    q <- "SELECT b.title AS judul, 
                 COALESCE(NULLIF(b.cover_book, ''), 'no-cover.jpg') AS cover,
                 COALESCE(a.author_name, 'Unknown') AS penulis,
                 COALESCE(p.publisher_name, 'Unknown') AS penerbit,
                 COALESCE(b.price, 0) AS harga,
                 COALESCE(b.pages, 0) AS halaman,
                 COALESCE(b.category, 'Unknown') AS genre
          FROM tbl_books b 
          LEFT JOIN tbl_authors a ON b.author_id = a.author_id
          LEFT JOIN tbl_publishers p ON b.publisher_id = p.publisher_id
          JOIN tbl_reviews r ON b.book_id = r.book_id 
          GROUP BY b.book_id, b.title, b.cover_book, a.author_name, p.publisher_name, b.price, b.pages, b.category 
          ORDER BY COUNT(r.review_id) DESC LIMIT 5;"
    df <- dbGetQuery(koneksi_db, q)
    
    if(nrow(df) == 0) return(h4("Tidak ada data.", style="text-align:center; padding:20px;"))
    
    div(class="book-row",
        lapply(1:nrow(df), function(i){
          # Struktur Flip Card
          div(class="flip-card", onclick="this.classList.toggle('flipped')",
              div(class="flip-card-inner",
                  div(class="flip-card-front", 
                      tags$img(src=df$cover[i], class="book-img"), 
                      span(df$judul[i], 
                           style="font-size: 14px; font-weight: 900 !important; text-transform: uppercase; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; margin-top: 10px; color: #000;")
                  ),
                  div(class="flip-card-back",
                      h5(df$judul[i]),
                      p(tags$b("Penulis: "), df$penulis[i]),
                      p(tags$b("Penerbit: "), df$penerbit[i]),
                      p(tags$b("Harga: "), paste0("Rp ", format(df$harga[i], big.mark=".", decimal.mark=","))),
                      p(tags$b("Halaman: "), df$halaman[i]),
                      p(tags$b("Genre: "), df$genre[i])
                  )
              )
          )
        }))
  })
  
  output$underrated <- renderUI({
    q <- "SELECT b.title AS judul, 
                 COALESCE(NULLIF(b.cover_book, ''), 'no-cover.jpg') AS cover,
                 COALESCE(a.author_name, 'Unknown') AS penulis,
                 COALESCE(p.publisher_name, 'Unknown') AS penerbit,
                 COALESCE(b.price, 0) AS harga,
                 COALESCE(b.pages, 0) AS halaman,
                 COALESCE(b.category, 'Unknown') AS genre
          FROM tbl_books b 
          LEFT JOIN tbl_authors a ON b.author_id = a.author_id
          LEFT JOIN tbl_publishers p ON b.publisher_id = p.publisher_id
          JOIN tbl_reviews r ON b.book_id = r.book_id 
          GROUP BY b.book_id, b.title, b.cover_book, a.author_name, p.publisher_name, b.price, b.pages, b.category 
          HAVING AVG(r.rating) >= 4.5 AND COUNT(r.review_id) BETWEEN 20 AND 100 
          ORDER BY AVG(r.rating) DESC, COUNT(r.review_id) DESC LIMIT 5;"
    df <- dbGetQuery(koneksi_db, q)
    
    if(nrow(df) == 0) return(h4("Belum ada buku potensial yang memenuhi kriteria.", style="text-align:center; padding:20px;"))
    
    div(class="book-row",
        lapply(1:nrow(df), function(i){
          # Struktur Flip Card
          div(class="flip-card", onclick="this.classList.toggle('flipped')",
              div(class="flip-card-inner",
                  div(class="flip-card-front", 
                      tags$img(src=df$cover[i], class="book-img"), 
                      span(df$judul[i], 
                           style="font-size: 14px; font-weight: 900 !important; text-transform: uppercase; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; margin-top: 10px; color: #000;")
                  ),
                  div(class="flip-card-back",
                      h5(df$judul[i]),
                      p(tags$b("Penulis: "), df$penulis[i]),
                      p(tags$b("Penerbit: "), df$penerbit[i]),
                      p(tags$b("Harga: "), paste0("Rp ", format(df$harga[i], big.mark=".", decimal.mark=","))),
                      p(tags$b("Halaman: "), df$halaman[i]),
                      p(tags$b("Genre: "), df$genre[i])
                  )
              )
          )
        }))
  })
  
  # ============================================================================
  # 3. AUTHOR (ANALISIS PENULIS & PENERBIT)
  # ============================================================================
  output$avg_author_rating <- renderPlotly({
    q <- "SELECT COALESCE(a.author_name, 'Unknown Author') AS penulis, ROUND(AVG(r.rating), 2) AS avg, COUNT(r.review_id) AS n_ulasan
          FROM tbl_authors a 
          LEFT JOIN tbl_books b ON a.author_id = b.author_id 
          LEFT JOIN tbl_reviews r ON b.book_id = r.book_id 
          GROUP BY a.author_id, a.author_name 
          ORDER BY avg DESC LIMIT 10;"
    df <- dbGetQuery(koneksi_db, q)
    if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Tidak ada data"))

    plot_ly(df) %>%
      add_segments(x = 0, xend = ~avg, y = ~penulis, n = ~n_ulasan, yend = ~penulis, 
                   line = list(color = '#bdc3c7', width = 2), showlegend = FALSE) %>%
      add_markers(
        x = ~avg,
        y = ~penulis,
        marker = list(
          size = 14,
          color = ~avg,
          colorscale = 'Reds',
          reversescale = FALSE,
          showscale = FALSE
        ),
        text = ~paste(
          "<b>", penulis, "</b>",
          "<br>Rating: ⭐ ", avg,
          "<br>Jumlah Ulasan: ", format(n_ulasan, big.mark=",")
        ),
        hoverinfo = "text",
        showlegend = FALSE
      ) %>%
      layout(xaxis = list(title = "Rata-rata Rating", range = c(0, 5.2), showgrid = FALSE),
             yaxis = list(title = "", categoryorder = "total ascending", showgrid = FALSE),
             margin = list(l = 150, t = 10, b = 30))
  })
  
  output$avg_publisher_rating <- renderPlotly({
    q <- "SELECT COALESCE(p.publisher_name, 'Unknown Publisher') AS penerbit, ROUND(AVG(r.rating), 2) AS avg, COUNT(r.review_id) AS n_ulasan
          FROM tbl_publishers p 
          LEFT JOIN tbl_books b ON p.publisher_id = b.publisher_id 
          LEFT JOIN tbl_reviews r ON b.book_id = r.book_id 
          GROUP BY p.publisher_id, p.publisher_name 
          ORDER BY avg DESC LIMIT 10;"
    df <- dbGetQuery(koneksi_db, q)
    if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Tidak ada data"))
    
    plot_ly(df, x = ~avg, y = ~penerbit, type = "bar", orientation = "h",
            text = ~paste("⭐", avg), textposition = 'outside',
            customdata = ~n_ulasan,
            hovertemplate = "<b>%{y}</b><br>Jumlah Ulasan: %{customdata}<extra></extra>",
            marker = list(color = ~avg, colorscale = 'Oranges', reversescale = FALSE, showscale = FALSE)) %>%
      layout(xaxis = list(title = "Rata-rata Rating", range = c(0, 5.5), showgrid = FALSE), 
             yaxis = list(title = "", categoryorder = "total ascending", showgrid = FALSE),
             margin = list(l = 150, t = 10, b = 30))
  })
  
  
  output$author_publisher_combo <- renderPlotly({
    q <- "SELECT COALESCE(a.author_name, 'Unknown') AS penulis, 
                 COALESCE(p.publisher_name, 'Unknown') AS penerbit, 
                 COUNT(b.book_id) AS n 
          FROM tbl_books b 
          JOIN tbl_authors a ON b.author_id = a.author_id 
          JOIN tbl_publishers p ON b.publisher_id = p.publisher_id 
          GROUP BY a.author_id, a.author_name, p.publisher_id, p.publisher_name 
          HAVING n > 1 ORDER BY n DESC LIMIT 10;"
    df <- dbGetQuery(koneksi_db, q)
    
    if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Tidak ada data"))
    df$combo <- paste(df$penulis, "|", df$penerbit)
    
    plot_ly(df, x = ~n, y = ~combo, type = 'scatter', mode = 'markers',
            marker = list(size = ~n, 
                          sizeref = max(df$n) / 50,  
                          sizemin = 12,              
                          color = ~n, 
                          colorscale = 'Viridis', 
                          reversescale = FALSE,     
                          showscale = FALSE),
            hovertemplate = "<b>%{y}</b><br>Total Kolaborasi: %{x} Buku<extra></extra>") %>%
      layout(xaxis = list(title = "Jumlah Buku", showgrid = FALSE),
             yaxis = list(title = "", categoryorder = "total ascending", showgrid = FALSE), 
             margin = list(l = 220, t = 10, b = 30)) 
  })
  
  output$most_popular_author <- renderUI({
    q <- "SELECT COALESCE(a.author_name, 'Unknown') AS penulis, 
                 COALESCE(a.author_profile, '') AS foto,
                 COUNT(r.review_id) AS n, 
                 ROUND(AVG(r.rating), 2) AS avg_rating,
                 COUNT(DISTINCT b.book_id) AS jml_buku
          FROM tbl_authors a 
          JOIN tbl_books b ON a.author_id = b.author_id 
          JOIN tbl_reviews r ON b.book_id = r.book_id 
          GROUP BY a.author_id, a.author_name, a.author_profile 
          ORDER BY n DESC LIMIT 5;"
    df <- dbGetQuery(koneksi_db, q)
    
    if(nrow(df) == 0) return(h4("Tidak ada data.", style="text-align:center; padding:20px;"))
    
    df$foto_final <- sapply(1:nrow(df), function(i) {
      if(df$foto[i] == "" || is.na(df$foto[i])) {
        paste0("https://ui-avatars.com/api/?name=", gsub(" ", "+", df$penulis[i]), "&background=2c3e50&color=fff&size=200&bold=true")
      } else {
        df$foto[i]
      }
    })
    
    div(class="book-row",
        lapply(1:nrow(df), function(i){
          div(class="flip-card", onclick="this.classList.toggle('flipped')",
              div(class="flip-card-inner",
                  div(class="flip-card-front", style="justify-content: center;",
                      tags$img(src=df$foto_final[i], 
                               style="width: 140px; height: 140px; object-fit: cover; border-radius: 50%; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"), 
                      span(df$penulis[i], 
                           style="font-size: 15px; font-weight: 900 !important; text-transform: uppercase; text-align: center; margin-top: 20px; color: #000;")
                  ),
                  div(class="flip-card-back",
                      h5(df$penulis[i]),
                      p(tags$b("Rating: "), "⭐ ", df$avg_rating[i]),
                      p(tags$b("Jumlah Ulasan: "), format(df$n[i], big.mark=",", scientific=FALSE)),
                      p(tags$b("Jumlah Buku: "), df$jml_buku[i])
                  )
              )
          )
        }))
  })
  
  output$most_productive_author <- renderPlotly({
    q <- "SELECT COALESCE(a.author_name, 'Unknown') AS penulis, 
                 COUNT(b.book_id) AS jml_buku
          FROM tbl_authors a 
          JOIN tbl_books b ON a.author_id = b.author_id 
          GROUP BY a.author_id, a.author_name 
          ORDER BY jml_buku DESC LIMIT 5;"
    df <- dbGetQuery(koneksi_db, q)
    if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Tidak ada data"))
    
    plot_ly(df, x = ~penulis, y = ~jml_buku, type = "bar",
            textposition = 'none', 
            hovertext = ~paste(
              "<b>", penulis, "</b>",
              "<br>Jumlah Buku: ", jml_buku
            ),
            hoverinfo = "text",
            marker = list(color = ~jml_buku, colorscale = 'Teals', reversescale = FALSE, showscale = FALSE)) %>%
      layout(xaxis = list(title = "", categoryorder = "total descending", tickangle = -45, showgrid = FALSE),
             yaxis = list(title = "Jumlah Buku", showgrid = FALSE),
             margin = list(b = 80))
  })
  
  # ============================================================================
  # 4. USER (ANALISIS PERILAKU PENGGUNA)
  # ============================================================================
  output$age_group_plot <- renderPlotly({
    q <- "SELECT 
              CASE 
                  WHEN TIMESTAMPDIFF(YEAR, u.date_of_birth, CURDATE()) < 20 THEN '1. Remaja (<20)' 
                  WHEN TIMESTAMPDIFF(YEAR, u.date_of_birth, CURDATE()) BETWEEN 20 AND 29 THEN '2. Dewasa Muda (20-29)' 
                  WHEN TIMESTAMPDIFF(YEAR, u.date_of_birth, CURDATE()) BETWEEN 30 AND 39 THEN '3. Dewasa (30-39)' 
                  WHEN TIMESTAMPDIFF(YEAR, u.date_of_birth, CURDATE()) >= 40 THEN '4. Senior (>=40)' 
                  ELSE '5. Tidak Diketahui' 
              END AS Kelompok_Usia, 
              COUNT(DISTINCT u.user_id) AS Jumlah_Pengguna, 
              ROUND(AVG(r.rating), 2) AS Rata_Rata_Rating_Diberikan 
          FROM tbl_users u 
          JOIN tbl_reviews r ON u.user_id = r.user_id 
          GROUP BY Kelompok_Usia 
          ORDER BY Kelompok_Usia ASC;"
    df <- dbGetQuery(koneksi_db, q)
    if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Tidak ada data"))
    
    plot_ly(df, x = ~Kelompok_Usia, y = ~Jumlah_Pengguna, type = "bar",
            textposition = 'none',
            hovertext = ~paste("<b>", Kelompok_Usia, "</b>",
                               "<br>Jumlah Pengguna:", format(Jumlah_Pengguna, big.mark=","),
                               "<br>Pola Ulasan: ⭐", Rata_Rata_Rating_Diberikan),
            hoverinfo = "text",
            marker = list(color = ~Jumlah_Pengguna, colorscale = 'Teals', reversescale = FALSE, showscale = FALSE)) %>%
      layout(xaxis = list(title = "", tickangle = -15, showgrid = FALSE), 
             yaxis = list(title = "Jumlah Pengguna", showgrid = FALSE),
             margin = list(b = 50))
  })
  
  
  output$kota_plot <- renderPlotly({
    q <- "SELECT COALESCE(city, 'Unknown') AS Kota, 
                 COUNT(DISTINCT user_id) AS Jumlah_Pengguna 
          FROM tbl_users 
          GROUP BY Kota 
          ORDER BY Jumlah_Pengguna DESC LIMIT 10;"
    df <- dbGetQuery(koneksi_db, q)
    if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Tidak ada data"))
    
    plot_ly(df, x = ~Jumlah_Pengguna, y = ~Kota, type = "bar", orientation = "h",
            textposition = 'none', 
            hovertext = ~paste("<b>Kota", Kota, "</b><br>Jumlah Pengguna: ", format(Jumlah_Pengguna, big.mark=",")),
            hoverinfo = "text",
            marker = list(color = ~Jumlah_Pengguna, colorscale = 'Purples', reversescale = FALSE, showscale = FALSE)) %>%
      layout(xaxis = list(title = "Jumlah Pengguna", showgrid = FALSE),
             yaxis = list(title = "", categoryorder = "total ascending", showgrid = FALSE),
             margin = list(l = 100, t = 10, b = 30))
  })
  
  output$active_user_plot <- renderPlotly({
      q <- "SELECT DISTINCT 
                 u.username, 
                 COALESCE(u.city, 'Unknown') AS user_city, 
                 COUNT(r.review_id) AS Jumlah_Ulasan_Diberikan 
          FROM tbl_users u 
          JOIN tbl_reviews r ON u.user_id = r.user_id 
          GROUP BY u.user_id, u.username, u.city 
          ORDER BY Jumlah_Ulasan_Diberikan DESC 
          LIMIT 10;"
      df <- dbGetQuery(koneksi_db, q)
      if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Tidak ada data"))
      
      df$label_unik <- paste0(df$username, " (", df$user_city, ")")
      
      plot_ly(df, x = ~Jumlah_Ulasan_Diberikan, y = ~label_unik, type = "bar", orientation = "h",
              textposition = 'none',
              hovertext = ~paste("<b>", username, "</b>",
                                 "<br>Asal: ", user_city,
                                 "<br>Kontribusi Ulasan: ", format(Jumlah_Ulasan_Diberikan, big.mark=",")),
              hoverinfo = "text",
              marker = list(color = ~Jumlah_Ulasan_Diberikan, colorscale = 'Blues', reversescale = FALSE, showscale = FALSE)) %>%
        layout(xaxis = list(title = "Jumlah Ulasan Diberikan", showgrid = FALSE),
               yaxis = list(title = "", categoryorder = "total ascending", showgrid = FALSE),
               margin = list(l = 150, t = 10, b = 30))
    })
  
  output$gender_plot <- renderPlotly({
    q <- "SELECT COALESCE(gender, 'Unknown') AS Kelamin, 
                 COUNT(DISTINCT user_id) AS Jumlah_Pengguna 
          FROM tbl_users 
          GROUP BY Kelamin 
          ORDER BY Jumlah_Pengguna DESC;"
    df <- dbGetQuery(koneksi_db, q)
    if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Tidak ada data"))
    
    df$Kelamin_Label <- sapply(df$Kelamin, function(x) {
      if(x == 'L') return('Laki-laki')
      if(x == 'P') return('Perempuan')
      return('Tidak Diketahui')
    })
    
    plot_ly(df, labels = ~Kelamin_Label, values = ~Jumlah_Pengguna, type = 'pie', hole = 0.5,
            textinfo = 'percent+label', 
            hovertext = ~paste("<b>", Kelamin_Label, "</b><br>Jumlah Pengguna: ", format(Jumlah_Pengguna, big.mark=",")),
            hoverinfo = 'text',
            marker = list(colors = c('#1abc9c', '#ff7675', '#bdc3c7'),
                          line = list(color = '#FFFFFF', width = 2))) %>%
      layout(showlegend = FALSE, margin = list(t = 20, b = 20))
  })
}

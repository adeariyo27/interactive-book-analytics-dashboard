# ================= UI =================

ui <- dashboardPage(
  dashboardHeader(disable = TRUE),
  
  dashboardSidebar(
    sidebarMenu(id="tabs", selected="ringkasan",
                menuItem("Ringkasan", tabName="ringkasan"),
                menuItem("Buku", tabName="books"),
                menuItem("Penulis", tabName="author"),
                menuItem("Pengguna", tabName="user"),
                menuItem("Tentang Kami", tabName="team")
    )
  ),
  
  dashboardBody(
    tags$head(tags$style(HTML("
  /* =========================================================
     1. PENGATURAN LAYOUT UTAMA
  ========================================================= */
  .main-sidebar { position: relative; width: 100% !important; height: auto; background: transparent; border: none; }
  .content-wrapper, .right-side { margin-left: 0 !important; background: #f4f6f9; }

  /* =========================================================
     2. NAVBAR (SIDEBAR MENU GLASSMORPHISM)
  ========================================================= */
  .sidebar-menu {
    display: flex;
    justify-content: center;
    gap: 10px;
    background: rgba(255, 255, 255, 0.9);
    backdrop-filter: blur(10px);
    padding: 8px 15px;
    border-radius: 50px;
    width: fit-content;
    margin: 20px auto;
    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
    border: 1px solid rgba(255,255,255,0.3);
  }
  .sidebar-menu > li { float: none; list-style: none; }
  .sidebar-menu > li > a {
    color: #555 !important;
    border-radius: 30px !important;
    padding: 10px 25px !important;
    transition: all 0.3s ease !important;
    background: transparent !important;
    border: none !important;
    font-size: 14px;
  }
  .sidebar-menu > li > a:hover {
    background: rgba(0, 0, 0, 0.05) !important;
    color: #000 !important;
    transform: translateY(-2px);
  }
  .sidebar-menu > li.active > a {
    background: #2c3e50 !important;
    color: white !important;
    box-shadow: 0 4px 15px rgba(0,0,0,0.2);
  }
  .sidebar-menu i { display: none; }

  /* =========================================================
     3. KUSTOMISASI KOTAK (BOX) & HEADER CLEAN WHITE
  ========================================================= */
  .small-box { border-radius: 15px; }
  
  .box { 
    border-radius: 15px; 
    border: none !important; /* Membunuh semua border warna bawaan AdminLTE */
    box-shadow: 0 4px 15px rgba(0,0,0,0.05) !important; /* Shadow diperhalus */
    background: #ffffff !important;
  }
  
  .box-header {
    background-color: #ffffff !important; /* Latar Putih Bersih */
    color: #000000 !important;            /* Teks Hitam */
    padding: 15px 20px 10px 20px !important;
    border-radius: 15px 15px 0 0 !important;
    border-bottom: 1px solid #f0f0f0 !important; /* Garis pembatas abu-abu super tipis nan elegan */
  }
  
  .box-title {
    font-family: 'Source Sans Pro', sans-serif;
    font-weight: 900 !important;  /* Tetap Ultra-Bold */
    font-size: 18px !important;
    text-transform: uppercase;    
    letter-spacing: 1.5px;      
    display: block;
  }
  
  .box-body {
    border-radius: 0 0 15px 15px !important;
    padding-top: 15px !important;
  }

  /* =========================================================
     4. DESAIN RAK BUKU (BOOK CARDS)
  ========================================================= */
  .book-row {
    display: flex; 
    justify-content: center; 
    gap: 20px; 
    flex-wrap: wrap;
  }
  .book-card {
    width: 18%; /* Lebar proporsional agar muat 5 buku sejajar */
    background: white;
    padding: 15px;
    border-radius: 15px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.08);
    display: flex;
    flex-direction: column;
    gap: 12px;
    align-items: center;
    text-align: center;
    transition: transform 0.2s;
  }
  .book-card:hover {
    transform: translateY(-5px); 
  }
  .book-img {
    width: 100%;
    height: 220px;       
    object-fit: contain; 
    border-radius: 4px;  
  }
  /* Mengatur teks judul buku di bawah gambar */
  .book-card span, .book-card strong {
    font-family: 'Source Sans Pro', sans-serif;
    font-weight: 900 !important; 
    text-transform: uppercase;   
    color: #000000 !important;   
    display: block;
    margin-top: 5px;
  }

  /* =========================================================
     5. TEAM CARDS (TABS TEAM)
  ========================================================= */
  .team-row { display:flex; justify-content:space-between; gap:20px; margin-top:30px; }
  .team-card { width:23%; background:white; padding:30px; border-radius:20px; text-align:center; box-shadow:0 4px 12px rgba(0,0,0,0.08); }
  .team-img { width:120px; height:120px; border-radius:50%; object-fit:cover; margin-bottom:15px; }

"))),
    
    tabItems(
      
      # ================= OVERVIEW =================
      tabItem(tabName="ringkasan",
              fluidRow(
                box(width=6, selectInput("tahun_filter", "Pilih Tahun", choices=daftar_tahun, selected=daftar_tahun[1])),
                box(width=6, selectInput("bulan_filter", "Pilih Bulan", choices=daftar_bulan, selected=daftar_bulan[1]))
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
                box(width=6, title="Distribusi Penilaian (Ulasan)", solidHeader=TRUE, plotlyOutput("donut_plot")),
                box(width=6, title="Tren Ulasan Bulanan", status="primary", solidHeader=TRUE, plotlyOutput("trend_plot"))
              ),
              fluidRow(
                box(width=12, title="Top 10 Genre Paling Banyak Diulas", solidHeader=TRUE, 
                    plotlyOutput("top_genre_plot", height="350px")) 
              ),
              fluidRow(
                box(width=12, title="Top 5 Buku Terpopuler", solidHeader=TRUE, 
                    uiOutput("top_books_landscape"))
              )
      ),
      
      # ================= BOOKS =================
      tabItem(tabName="books",
              fluidRow(
                box(width=6, title="Korelasi Harga & Ulasan", solidHeader=TRUE, plotlyOutput("price_corr_plot")),
                box(width=6, title="Korelasi Halaman & Ulasan", solidHeader=TRUE, plotlyOutput("page_corr_plot"))
              ),
              fluidRow(
                box(width=6, title="Rata-rata Halaman per Genre", solidHeader=TRUE, plotlyOutput("avg_pages")),
                box(width=6, title="Distribusi Ulasan (1-5)", solidHeader=TRUE, plotlyOutput("rating_scale"))
              ),
              fluidRow(
                box(width=12, title="Distribusi Genre", solidHeader=TRUE, plotlyOutput("genre_dist")),
                box(width=12, title="Top 10 Buku Terpopuler", solidHeader=TRUE, uiOutput("top10")),
                box(width=12, title=HTML("TOP 5 Buku Potensial (<i>Underrated</i>)"), solidHeader=TRUE, uiOutput("underrated"))
              ),
      ),
      
      # ================= AUTHOR =================
      tabItem(tabName="author",
              fluidRow(
                box(width=6, title="Rata-rata Ulasan Penulis", solidHeader=TRUE, plotlyOutput("avg_author_rating")),
                box(width=6, title="Rata-rata Ulasan Penerbit", solidHeader=TRUE, plotlyOutput("avg_publisher_rating"))
              ),
              fluidRow(
                box(width=12, title="Kombinasi Penulis-Penerbit Terbanyak", solidHeader=TRUE, plotlyOutput("author_publisher_combo")),
                box(width=6, title="Penulis Terpopuler", solidHeader=TRUE, plotlyOutput("most_popular_author")),
                box(width=6, title="Penulis Terproduktif", solidHeader=TRUE, plotlyOutput("most_productive_author"))
              )
      ),
      
      # ================= USER =================
      tabItem(tabName="user",
              fluidRow(
                box(width=6, title="Distribusi Kelompok Usia", solidHeader=TRUE, plotlyOutput("age_group_plot")),
                box(width=6, title="Distribusi Kota", solidHeader=TRUE, plotlyOutput("kota_plot"))
              ),
              fluidRow(
                box(width=6, title="Pengguna Paling Aktif", solidHeader=TRUE, plotlyOutput("active_user_plot")),
                box(width=6, title="Distribusi Gender", solidHeader=TRUE, plotlyOutput("gender_plot"))
              ),
      ),
      
      # ================= TEAM =================
      tabItem(
        tabName = "team",
        h2(tags$b("TIM PENGEMBANG DASHBOARD"), align="center", style="margin-bottom: 30px; font-weight: 900;"),
        div(class="team-row",
            div(class="team-card", 
                # Background Biru Baja (#2980b9)
                tags$img(src="https://ui-avatars.com/api/?name=Ade+Ariyo&background=2980b9&color=fff&size=200&bold=true&rounded=true", class="team-img"), 
                h4(tags$b("Ade Ariyo Yudanto")), 
                p("Database Manager", style="color: #7f8c8d; font-weight: bold;")
            ),
            div(class="team-card", 
                # Background Merah Muda (#e74c3c)
                tags$img(src="https://ui-avatars.com/api/?name=Natalinda+Erlina&background=e74c3c&color=fff&size=200&bold=true&rounded=true", class="team-img"), 
                h4(tags$b("Natalinda Erlina Amheka")), 
                p("Data Analyst", style="color: #7f8c8d; font-weight: bold;")
            ),
            div(class="team-card", 
                # Background Hijau (#2ecc71)
                tags$img(src="https://ui-avatars.com/api/?name=Muhammad+Hanif&background=2ecc71&color=fff&size=200&bold=true&rounded=true", class="team-img"), 
                h4(tags$b("Muhammad Hanif Nafiis")), 
                p("Backend Developer", style="color: #7f8c8d; font-weight: bold;")
            ),
            div(class="team-card", 
                # Background Oranye (#f39c12)
                tags$img(src="https://ui-avatars.com/api/?name=Rizky+Mardhatillah&background=f39c12&color=fff&size=200&bold=true&rounded=true", class="team-img"), 
                h4(tags$b("Rizky Mardhatillah")), 
                p("Frontend Developer", style="color: #7f8c8d; font-weight: bold;")
            )
        )
      )
    )
  )
)

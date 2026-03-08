# ================= UI =================

ui <- dashboardPage(
  
  dashboardHeader(
    title = tags$div(
      tags$span("NOVEL ANALYTICS DASHBOARD", style = "font-weight: 900; vertical-align: middle; font-size: 14px; color: white;"),
      style = "text-align: left;"
    ),
    titleWidth = 350
  ),
  
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
      .main-header .navbar-custom-menu { display: none !important; } 
      .main-header .sidebar-toggle { display: none !important; }
      .main-header .logo { text-align: left !important; padding-left: 15px !important; }

      /* =========================================================
         1. BANNER IMAGE 
      ========================================================= */
      /* Menyulap container menu menjadi banner bergambar di bagian atas */
      .main-sidebar { 
        position: relative !important; 
        width: 100% !important; 
        height: 200px !important; 
        padding-top: 40px !important; /* Memberi ruang di atas menu */
        padding-bottom: 40px !important; /* Memberi ruang di bawah menu */
        background-image: url('hero-banner.jpg') !important; 
        background-size: cover !important; 
        background-position: center 30% !important; 
        z-index: 10;
      }
      
      /* Efek overlay gelap HANYA di banner agar menu terbaca jelas */
      .main-sidebar::before {
        content: '';
        position: absolute;
        top: 0; left: 0; width: 100%; height: 100%;
        background-color: rgba(0, 0, 0, 0.4); 
        z-index: 0; /* Taruh di bawah menu */
      }

      /* =========================================================
         2. NAVBAR (SIDEBAR MENU GLASSMORPHISM)
      ========================================================= */
      .sidebar-menu {
        position: relative;
        z-index: 1; /* Taruh di atas overlay gelap */
        display: flex;
        justify-content: center;
        gap: 10px;
        background: rgba(255, 255, 255, 0.9);
        backdrop-filter: blur(10px);
        padding: 8px 15px;
        border-radius: 50px;
        width: fit-content;
        margin: 0 auto;
        box-shadow: 0 10px 30px rgba(0,0,0,0.2);
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
        font-weight: bold;
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
         3. DASHBOARD BODY (KEMBALI KE WHITE CLEAN)
      ========================================================= */
      .content-wrapper, .right-side { 
        margin-left: 0 !important; 
        background-color: #f4f6f9 !important; /* Warna putih bersih bawaan */
        background-image: none !important; /* Memastikan tidak ada gambar bocor ke bawah */
        padding-top: 20px;
      }

      /* =========================================================
         4. KUSTOMISASI KOTAK (BOX) 
      ========================================================= */
      .small-box { border-radius: 15px; }
      
      .box { 
        border-radius: 15px; 
        border: none !important;
        box-shadow: 0 4px 15px rgba(0,0,0,0.05) !important; 
        background: #ffffff !important;
      }
      .box-header {
        background-color: #ffffff !important; 
        color: #000000 !important;            
        padding: 15px 20px 10px 20px !important;
        border-radius: 15px 15px 0 0 !important;
        border-bottom: 1px solid #f0f0f0 !important; 
      }
      .box-title {
        font-family: 'Source Sans Pro', sans-serif;
        font-weight: 900 !important;  
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
         5. DESAIN RAK BUKU (FLIP CARD) & TEAM 
      ========================================================= */
      .book-row { display: flex; justify-content: center; gap: 20px; flex-wrap: wrap; }
      
      /* Membungkus kartu utama agar mendukung efek 3D */
      .flip-card {
        background-color: transparent;
        width: 18%; 
        height: 320px; 
        perspective: 1000px; 
        cursor: pointer;
        margin-bottom: 20px;
      }
      
      /* Wadah poros putaran */
      .flip-card-inner {
        position: relative;
        width: 100%;
        height: 100%;
        text-align: center;
        transition: transform 0.6s cubic-bezier(0.4, 0.2, 0.2, 1); 
        transform-style: preserve-3d;
      }
      
      /* Memicu putaran saat di-hover atau diklik */
      .flip-card:hover .flip-card-inner, .flip-card.flipped .flip-card-inner { 
        transform: rotateY(180deg); 
      }
      
      /* Struktur umum Sisi Depan & Belakang */
      .flip-card-front, .flip-card-back {
        position: absolute;
        width: 100%;
        height: 100%;
        backface-visibility: hidden; 
        border-radius: 15px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        padding: 15px;
        display: flex;
        flex-direction: column;
      }
      
      /* SISI DEPAN: Gambar & Judul */
      .flip-card-front {
        background: white;
        align-items: center;
        justify-content: flex-start;
      }
      .book-img { width: 100%; height: 210px; object-fit: contain; border-radius: 4px; }
      .flip-card-front span { 
        font-family: 'Source Sans Pro', sans-serif; font-weight: 900 !important; 
        text-transform: uppercase; color: #000; margin-top: 10px; 
        display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
      }
      
      /* SISI BELAKANG: Informasi Detail Buku */
      .flip-card-back {
        background: linear-gradient(135deg, #2c3e50, #3498db); 
        color: white;
        transform: rotateY(180deg); 
        justify-content: center;
        text-align: left;
        padding: 20px;
      }
      .flip-card-back h5 {
        font-weight: 900; font-size: 14px; margin-top: 0; margin-bottom: 15px;
        border-bottom: 2px solid rgba(255,255,255,0.5); padding-bottom: 10px; text-align: center;
        text-transform: uppercase;
      }
      .flip-card-back p {
        margin: 4px 0; font-size: 12px; line-height: 1.4;
        border-bottom: 1px dashed rgba(255,255,255,0.2); padding-bottom: 4px;
      }

      /* --- BAGIAN TEAM (TETAP SAMA) --- */
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
                valueBoxOutput("total_titles", width=3),
                valueBoxOutput("total_reviews", width=3),
                valueBoxOutput("total_users", width=3),
                valueBoxOutput("global_rating", width=3)
              ),
              fluidRow(
                box(width=6, title="Distribusi Penilaian (Ulasan)", solidHeader=TRUE, plotlyOutput("donut_plot")),
                box(width=6, title="Tren Ulasan Bulanan", status="primary", solidHeader=TRUE, plotlyOutput("trend_plot")),
                box(width=12, title="Top 5 Buku Terpopuler", solidHeader=TRUE, uiOutput("top_books_landscape"))
              ),
              fluidRow(
                box(width=12, title="Top 10 Genre Paling Banyak Diulas", solidHeader=TRUE, plotlyOutput("top_genre_plot", height="350px")) 
              ),
      ),
      
      # ================= BOOKS =================
      tabItem(tabName="books",
              fluidRow(
                box(width=12, title="Top 5 Buku Terpopuler", solidHeader=TRUE, uiOutput("top5")),
                box(width=12, title=HTML("TOP 5 Buku Potensial (<i>Underrated</i>)"), solidHeader=TRUE, uiOutput("underrated"))
              ),
              fluidRow(
                box(width=6, title="Korelasi Harga & Ulasan", solidHeader=TRUE, plotlyOutput("price_corr_plot")),
                box(width=6, title="Korelasi Halaman & Ulasan", solidHeader=TRUE, plotlyOutput("page_corr_plot")),
                box(width=6, title="Rata-rata Halaman per Genre", solidHeader=TRUE, plotlyOutput("avg_pages")),
                box(width=6, title="Distribusi Ulasan (1-5)", solidHeader=TRUE, plotlyOutput("rating_scale"))
              ),
              fluidRow(
                box(width=12, title="Distribusi Genre", solidHeader=TRUE, plotlyOutput("genre_dist"))
              )
      ),
      
      # ================= AUTHOR =================
      tabItem(tabName="author",
              fluidRow(
                box(width=12, title="Penulis Terpopuler", solidHeader=TRUE, uiOutput("most_popular_author")),
                box(width=6, title="Kombinasi Penulis-Penerbit Terbanyak", solidHeader=TRUE, plotlyOutput("author_publisher_combo")),
                box(width=6, title="Penulis Terproduktif", solidHeader=TRUE, plotlyOutput("most_productive_author")),
              ),
              fluidRow(
                box(width=6, title="Rata-rata Ulasan Penulis", solidHeader=TRUE, plotlyOutput("avg_author_rating")),
                box(width=6, title="Rata-rata Ulasan Penerbit", solidHeader=TRUE, plotlyOutput("avg_publisher_rating"))
              )
      ),
      
      # ================= USER =================
      tabItem(tabName="user",
              fluidRow(
                box(width=6, title="Distribusi Kelompok Usia", solidHeader=TRUE, plotlyOutput("age_group_plot")),
                box(width=6, title="Distribusi Gender", solidHeader=TRUE, plotlyOutput("gender_plot")),
                box(width=6, title="Distribusi Kota", solidHeader=TRUE, plotlyOutput("kota_plot")),
                box(width=6, title="Pengguna Paling Aktif", solidHeader=TRUE, plotlyOutput("active_user_plot"))
              )
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
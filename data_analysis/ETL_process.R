# ==============================================================================
# ETL SCRIPT: BIG DATA PROCESSING PROJECT
# ==============================================================================

setwd("D:/Magister/Kuliah/Semester 2 - Pemrosesan Data Besar/Tugas/Kelompok/Dataset/")
options(scipen = 999) 

library(tidyverse)
library(DBI)
library(RMariaDB)
library(glue)

# ------------------------------------------------------------------------------
# TAHAP 1: INISIALISASI KONEKSI DATABASE
# ------------------------------------------------------------------------------
db_name <- "db_books" 
db_user <- "root"
db_pass <- ""
db_host <- "127.0.0.1"
db_port <- 3306

con <- dbConnect(RMariaDB::MariaDB(), 
                 dbname = db_name, 
                 user = db_user, 
                 password = db_pass, 
                 host = db_host, 
                 port = db_port)

print(paste("Koneksi berhasil ke database:", db_name))

# ------------------------------------------------------------------------------
# TAHAP 2: EKSTRAKSI DAN PRA-PEMROSESAN DATA
# ------------------------------------------------------------------------------
# Membaca data mentah dari database
raw_df <- dbReadTable(con, "novel_rawdata") 

# Standardisasi nama kolom (huruf kecil dan snake_case)
colnames(raw_df) <- tolower(gsub(" ", "_", colnames(raw_df)))

# Pembersihan data string, konversi tanggal, dan normalisasi entitas penerbit
clean_df <- raw_df %>%
  mutate(
    # A. Cleaning String Dasar
    clean_title = str_squish(title),       
    clean_author = str_squish(author),
  
    # Mengubah format 'dd/mm/yyyy' menjadi 'yyyy-mm-dd' (Standar SQL)
    date_of_birth = as.Date(date_of_birth, format = "%d/%m/%Y"),
    publish_date  = as.Date(publish_date, format = "%d/%m/%Y"),
    review_date   = as.Date(review_date, format = "%d/%m/%Y"),
    
    # B. Cleaning Publisher 
    temp_pub = str_to_title(str_squish(publisher)), 
    clean_publisher = case_when(
      str_detect(temp_pub, "(?i)^Mizan") ~ "Mizan Pustaka",
      str_detect(temp_pub, "(?i)Noura") ~ "Noura Books",
      str_detect(temp_pub, "(?i)^Narasi") ~ "Narasi",
      str_detect(temp_pub, "(?i)Gramedia") ~ "Gramedia Pustaka Utama",
      str_detect(temp_pub, "(?i)Pastel") ~ "Pastel Books",
      str_detect(temp_pub, "(?i)Bloomsbury") ~ "Bloomsbury",
      str_detect(temp_pub, "(?i)Random House") ~ "Penguin Random House",
      str_detect(temp_pub, "(?i)Penguin") ~ "Penguin Random House",
      str_detect(temp_pub, "(?i)Harpercollins") ~ "Harpercollins",
      TRUE ~ temp_pub 
    )
  )

# ------------------------------------------------------------------------------
# TAHAP 3: MEMUAT DATA KE STRUKTUR SQL
# ------------------------------------------------------------------------------

dbWriteTable(con, "tbl_authors", tbl_authors, append = TRUE, overwrite = FALSE, row.names = FALSE)
print("Data Penulis berhasil dimuat.")

dbWriteTable(con, "tbl_publishers", tbl_publishers, append = TRUE, overwrite = FALSE, row.names = FALSE)
print("Data Penerbit berhasil dimuat.")

dbWriteTable(con, "tbl_users", tbl_users, append = TRUE, overwrite = FALSE, row.names = FALSE)
print("Data Pengguna berhasil dimuat.")

dbWriteTable(con, "tbl_books", tbl_books, append = TRUE, overwrite = FALSE, row.names = FALSE)
print("Data Buku berhasil dimuat.")

dbWriteTable(con, "tbl_reviews", tbl_reviews, append = TRUE, overwrite = FALSE, row.names = FALSE)
print("Data Review berhasil dimuat.")

print("Proses ETL Selesai. Data telah tersimpan.")

# ------------------------------------------------------------------------------
# TAHAP 6: PENUTUPAN KONEKSI DATABASE
# ------------------------------------------------------------------------------

dbDisconnect(con)

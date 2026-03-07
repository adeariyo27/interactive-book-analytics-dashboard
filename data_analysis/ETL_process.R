# ================= ETL Process =================

options(scipen = 999) 

library(tidyverse)
library(DBI)
library(RMariaDB)

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
# TAHAP 2: EKSTRAKSI DAN PRA-PEMROSESAN DATA (DATA CLEANING)
# ------------------------------------------------------------------------------

raw_df <- dbReadTable(con, "novel_rawdata") 

# Standardisasi nama kolom mentah (huruf kecil)
colnames(raw_df) <- tolower(gsub(" ", "_", colnames(raw_df)))

# Pembersihan data string, tanggal, gender, dan entitas penerbit
clean_df <- raw_df %>%
  mutate(
    # A. Cleaning String Dasar
    clean_title = str_squish(title),       
    clean_author = str_squish(author),
    
    # B. Konversi Format Tanggal ke YYYY-MM-DD
    date_of_birth = as.Date(date_of_birth, format = "%d/%m/%Y"),
    publish_date  = as.Date(publish_date, format = "%d/%m/%Y"),
    review_date   = as.Date(review_date, format = "%d/%m/%Y"),
    
    # C. Penyesuaian Gender agar sesuai schema CHAR(1) -> 'L' atau 'P'
    clean_gender = case_when(
      str_detect(tolower(gender), "^l") ~ "L",
      str_detect(tolower(gender), "^p") ~ "P",
      TRUE ~ NA_character_
    ),
    
    # D. Cleaning Publisher 
    temp_pub = str_to_title(str_squish(publisher)), 
    clean_publisher = case_when(
      str_detect(temp_pub, "(?i)^Mizan") ~ "Mizan Pustaka",
      str_detect(temp_pub, "(?i)Noura") ~ "Noura Books",
      str_detect(temp_pub, "(?i)Gramedia") ~ "Gramedia Pustaka Utama",
      str_detect(temp_pub, "(?i)Penguin|Random House") ~ "Penguin Random House",
      TRUE ~ temp_pub 
    )
  )

# ------------------------------------------------------------------------------
# TAHAP 3: NORMALISASI DATA (SNOWFLAKE SCHEMA) & GENERATE SURROGATE KEY
# ------------------------------------------------------------------------------

# 3A. TABEL PENULIS (tbl_authors)
tbl_authors <- clean_df %>%
  distinct(clean_author) %>%
  drop_na(clean_author) %>%
  rename(author_name = clean_author) %>%
  mutate(author_id = row_number(), # Generate sementara untuk Foreign Key
         author_profile = NA_character_,
         author_biography = NA_character_) %>%
  select(author_id, author_name, author_profile, author_biography)

# 3B. TABEL PENERBIT (tbl_publishers)
tbl_publishers <- clean_df %>%
  distinct(clean_publisher) %>%
  drop_na(clean_publisher) %>%
  rename(publisher_name = clean_publisher) %>%
  mutate(publisher_id = row_number(),
         url_publisher = NA_character_) %>%
  select(publisher_id, publisher_name, url_publisher)

# 3C. TABEL PENGGUNA (tbl_users)
tbl_users <- clean_df %>%
  distinct(username, clean_gender, date_of_birth, city) %>% 
  drop_na(username) %>%
  rename(gender = clean_gender) %>%
  mutate(user_id = row_number()) %>%
  select(user_id, username, gender, date_of_birth, city)

# 3D. TABEL BUKU (tbl_books)
tbl_books <- clean_df %>%
  distinct(clean_title, isbn, category, clean_author, clean_publisher, pages, language, price, publish_date) %>%
  left_join(tbl_authors, by = c("clean_author" = "author_name")) %>%
  left_join(tbl_publishers, by = c("clean_publisher" = "publisher_name")) %>%
  rename(title = clean_title) %>%
  mutate(book_id = row_number(),
         description = NA_character_,
         cover_book = NA_character_,
         url_book = NA_character_) %>%
  select(book_id, isbn, title, category, author_id, publisher_id, description, pages, language, price, publish_date, cover_book, url_book)

# 3E. TABEL ULASAN (tbl_reviews) - FACT TABLE
tbl_reviews <- clean_df %>%
  select(clean_title, username, rating, review_date) %>%
  left_join(tbl_books, by = c("clean_title" = "title")) %>%
  left_join(tbl_users, by = "username") %>%
  mutate(review_id = row_number()) %>%
  select(review_id, book_id, user_id, rating, review_date)

# ------------------------------------------------------------------------------
# TAHAP 4: MEMUAT DATA KE MYSQL (LOAD)
# ------------------------------------------------------------------------------
print("Menulis tabel ke dalam database MySQL...")

# Menyimpan sesuai urutan agar tidak terjadi error Constraint Foreign Key
dbWriteTable(con, "tbl_authors", tbl_authors, append = TRUE, overwrite = FALSE, row.names = FALSE)
print("-> Data tbl_authors berhasil dimuat.")

dbWriteTable(con, "tbl_publishers", tbl_publishers, append = TRUE, overwrite = FALSE, row.names = FALSE)
print("-> Data tbl_publishers berhasil dimuat.")

dbWriteTable(con, "tbl_users", tbl_users, append = TRUE, overwrite = FALSE, row.names = FALSE)
print("-> Data tbl_users berhasil dimuat.")

dbWriteTable(con, "tbl_books", tbl_books, append = TRUE, overwrite = FALSE, row.names = FALSE)
print("-> Data tbl_books berhasil dimuat.")

dbWriteTable(con, "tbl_reviews", tbl_reviews, append = TRUE, overwrite = FALSE, row.names = FALSE)
print("-> Data tbl_reviews berhasil dimuat.")


# ------------------------------------------------------------------------------
# TAHAP 5: PENUTUPAN KONEKSI DATABASE
# ------------------------------------------------------------------------------
dbDisconnect(con)
print("Koneksi database ditutup.")
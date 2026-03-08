# ================= GLOBAL =================

# 1. Memuat Library yang Dibutuhkan
library(shiny)
library(shinydashboard)
library(plotly)
library(ggplot2)
library(dplyr)
library(DBI)
library(RMariaDB)
library(tidyverse)
library(glue)

# ------------------------------------------------------------------------------
# 2. KONEKSI DATABASE
# ------------------------------------------------------------------------------
db_name <- "db_books" 
db_user <- "root"
db_pass <- ""
db_host <- "127.0.0.1"
db_port <- 3306

# Membuat koneksi ke Database 
koneksi_db <- dbConnect(RMariaDB::MariaDB(), 
                        dbname = db_name, 
                        user = db_user, 
                        password = db_pass, 
                        host = db_host, 
                        port = db_port)

print(paste("Koneksi berhasil ke database:", db_name))

# ------------------------------------------------------------------------------
# 3. PERSIAPAN VARIABEL GLOBAL (UNTUK FILTER DI UI)
# ------------------------------------------------------------------------------
# Mengambil daftar tahun dari database, dan menambahkan opsi "Semua Tahun" di urutan pertama
query_tahun <- "SELECT DISTINCT YEAR(review_date) AS tahun FROM tbl_reviews WHERE review_date IS NOT NULL ORDER BY tahun DESC;"
daftar_tahun <- c("Semua Tahun", dbGetQuery(koneksi_db, query_tahun)$tahun)

# Menambahkan opsi "Semua Bulan" pada daftar bulan bawaan R
daftar_bulan <- c("Semua Bulan", month.name)
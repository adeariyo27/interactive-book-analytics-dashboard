# 📊 Interactive Book Analytics Dashboard

**Mata Kuliah:** Pemrosesan Data Besar (S2 Statistika dan Sains Data, IPB University)  
**Status Proyek:** Aktif / Dalam Pengembangan  

---

## 📖 Latar Belakang
[cite_start]Proyek ini bertujuan untuk merancang dan mengimplementasikan dasbor analitik interaktif berbasis RShiny[cite: 11]. [cite_start]Berangkat dari dataset mentah berupa log transaksi ulasan buku e-commerce (format *flat file* tunggal)[cite: 10], kami melakukan transformasi arsitektur data secara menyeluruh. [cite_start]Proses ini mencakup pembersihan data, pemodelan basis data relasional, hingga penyajian wawasan bisnis untuk mendukung pengambilan keputusan strategis[cite: 5, 11].

## 👥 Tim Pengembang dan Peran
Proyek kolaboratif ini dikerjakan oleh 4 peran utama dengan spesialisasi masing-masing:
1. [cite_start]**[Nama Anda/Aryo] - Database Manager:** Bertanggung jawab atas perancangan Entity Relationship Diagram (ERD) [cite: 8][cite_start], normalisasi data hingga 3NF [cite: 6][cite_start], optimasi *raw query*, dan pemeliharaan skema basis data (*Snowflake Schema*)[cite: 7].
2. [cite_start]**Natalinda - Data Analyst:** Bertanggung jawab atas proses ETL, *Exploratory Data Analysis* (EDA), pembersihan data awal[cite: 5], dan penentuan metrik bisnis.
3. **Hanif - Backend Developer:** Bertanggung jawab merancang logika *server* (RShiny), integrasi koneksi basis data MySQL ke R, dan pemrosesan *query* dinamis.
4. **[Nama Anggota] - Frontend Developer:** Bertanggung jawab merancang antarmuka pengguna (UI) RShiny, tata letak dasbor, dan elemen visual yang interaktif.

## ⚙️ Alur Kerja Proyek (Pipeline)
1. **Fase 1: Data Preprocessing & Diagnosis** Identifikasi anomali data mentah (seperti isu ISBN *dummy* dan redundansi atribut penulis/penerbit).
2. [cite_start]**Fase 2: Database Architecture** Penerapan normalisasi tingkat tiga (3NF) [cite: 6] [cite_start]dan pembentukan *Snowflake Schema* [cite: 7] untuk memisahkan entitas *Master* (Buku, Penulis, Penerbit, Pengguna) dan tabel *Fakta* (Ulasan).
3. **Fase 3: Query Optimization** Penyusunan sintaks SQL murni dengan memanfaatkan `LEFT JOIN` dan penanganan *Missing Values* (`COALESCE`) untuk menjaga integritas perhitungan analitik.
4. **Fase 4: Dashboard Implementation** Visualisasi wawasan data melalui 4 halaman interaktif di RShiny.

## 📈 Fitur Utama Dasbor
[cite_start]Dasbor dirancang dalam empat halaman utama yang merangkum seluruh wawasan data[cite: 18, 19]:

* **A. [cite_start]Ringkasan Umum:** Menampilkan KPI utama (Total Buku, Ulasan, Pengguna, Rating Global) dan tren aktivitas ulasan per bulan[cite: 20, 22, 23, 24, 25, 26].
* **B. [cite_start]Analisis Performa Buku dan Genre:** Menyajikan peringkat 10 buku terpopuler, evaluasi genre, analisis korelasi harga/halaman, dan pemetaan buku potensial (*underrated*)[cite: 33, 36, 37, 39, 40, 41].
* **C. [cite_start]Analisis Penulis dan Penerbit:** Mengevaluasi metrik kualitas entitas kreator melalui ulasan terbanyak dan tingkat konsistensi penilaian, serta pasangan kolaborasi penulis-penerbit[cite: 50, 53, 55, 56, 58].
* **D. [cite_start]Analisis Perilaku Pengguna:** Membedah demografi (usia, gender, kota asal) dan distribusi pola penilaian pengguna aktif[cite: 62, 65, 66, 67, 68, 69].

## 📂 Struktur Repositori
```text
interactive-book-analytics-dashboard/
│
├── data_analysis/             # Skrip R untuk ETL & Eksplorasi Data
│   └── ETL_process.R          
│
├── database/                  # Skrip SQL untuk Skema & Analitik
│   ├── table_schema_metadata.sql  # DDL (Create Table, PK, FK, Constraints)
│   └── queries_dashboard.sql      # Kumpulan Raw Query (A1 s.d D4)
│
├── docs/                      # Dokumentasi & Desain Konseptual
│   ├── ERD Schema.png         
│   ├── ERD_schema_script.txt  
│   ├── KPI Dashboard.pdf      
│   └── Rancangan Dashboard.pdf
│
├── dataset/                   # Folder data mentah statis (di-gitignore)
│   └── novel_rawdata.csv      
│
└── README.md                  # Dokumentasi proyek

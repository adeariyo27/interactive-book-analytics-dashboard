-- ====================================================================================
-- BAGIAN A: RINGKASAN UMUM (KPI & TREN)
-- ====================================================================================

-- A1. Scorecard KPI Utama (Menggunakan Subquery Skalar untuk performa)
SELECT 
    (SELECT COUNT(book_id) FROM tbl_books) AS Total_Judul_Buku,
    (SELECT COUNT(review_id) FROM tbl_reviews) AS Total_Ulasan,
    (SELECT COUNT(user_id) FROM tbl_users) AS Total_Pengguna,
    (SELECT ROUND(AVG(rating), 2) FROM tbl_reviews) AS Rata_Rata_Global;

-- A2. Tren Jumlah Ulasan per Bulan
SELECT 
    DATE_FORMAT(review_date, '%Y-%m') AS Bulan,
    COUNT(review_id) AS Jumlah_Ulasan
FROM tbl_reviews
WHERE review_date IS NOT NULL
GROUP BY Bulan
ORDER BY Bulan ASC;


-- ====================================================================================
-- BAGIAN B: ANALISIS PERFORMA BUKU DAN GENRE
-- ====================================================================================

-- B1. 10 Buku Terpopuler (Berdasarkan Jumlah Ulasan Terbanyak)
SELECT 
    b.title, 
    COALESCE(b.category, 'Uncategorized') AS category, 
    COALESCE(a.author_name, 'Unknown Author') AS author_name, 
    COUNT(r.review_id) AS total_reviews, 
    COALESCE(ROUND(AVG(r.rating), 1), 0.0) AS avg_rating
FROM tbl_books b
LEFT JOIN tbl_authors a ON b.author_id = a.author_id
LEFT JOIN tbl_reviews r ON b.book_id = r.book_id
GROUP BY b.book_id, b.title, b.category, a.author_name
ORDER BY total_reviews DESC
LIMIT 10;

-- B2. Rata-rata Penilaian per Genre
SELECT 
    COALESCE(b.category, 'Uncategorized') AS Genre,
    ROUND(AVG(r.rating), 2) AS Rata_Rata_Penilaian,
    COUNT(DISTINCT b.book_id) AS Jumlah_Buku
FROM tbl_books b
LEFT JOIN tbl_reviews r ON b.book_id = r.book_id
GROUP BY Genre
ORDER BY Rata_Rata_Penilaian DESC;

-- B3. Distribusi Penilaian Skala 1-5
SELECT 
    rating AS Skala_Penilaian, 
    COUNT(review_id) AS Jumlah_Ulasan
FROM tbl_reviews
WHERE rating IS NOT NULL
GROUP BY rating
ORDER BY rating DESC;

-- B4. Buku Potensial / Underrated (Menggunakan Klausa HAVING untuk Filter Agregasi)
SELECT 
    b.title, 
    COALESCE(b.category, 'Uncategorized') AS category, 
    COALESCE(a.author_name, 'Unknown Author') AS author_name, 
    COUNT(r.review_id) AS total_reviews, 
    COALESCE(ROUND(AVG(r.rating), 1), 0.0) AS avg_rating
FROM tbl_books b
LEFT JOIN tbl_authors a ON b.author_id = a.author_id
JOIN tbl_reviews r ON b.book_id = r.book_id
GROUP BY b.book_id, b.title, b.category, a.author_name
HAVING avg_rating >= 4.5 AND total_reviews BETWEEN 20 AND 100
ORDER BY avg_rating DESC, total_reviews DESC;

-- B5. Data Scatter Plot: Korelasi Harga & Halaman terhadap Penilaian
SELECT 
    b.title, 
    COALESCE(b.price, 0) AS price, 
    COALESCE(b.pages, 0) AS pages,
    COALESCE(ROUND(AVG(r.rating), 1), 0.0) AS avg_rating,
    COUNT(r.review_id) AS total_reviews
FROM tbl_books b
LEFT JOIN tbl_reviews r ON b.book_id = r.book_id
WHERE b.price > 0 AND b.pages > 0
GROUP BY b.book_id, b.title, b.price, b.pages;

-- B6. Analisis Genre terhadap Jumlah Halaman
SELECT 
    COALESCE(b.category, 'Uncategorized') AS Genre, 
    ROUND(AVG(b.pages), 0) AS Rata_Rata_Halaman
FROM tbl_books b
WHERE b.pages > 0 
GROUP BY Genre
ORDER BY Rata_Rata_Halaman DESC;


-- ====================================================================================
-- BAGIAN C: ANALISIS PENULIS DAN PENERBIT
-- ====================================================================================

-- C1. Top 10 Penulis dengan Ulasan Terbanyak 
SELECT 
    COALESCE(a.author_name, 'Unknown Author') AS Penulis, 
    COUNT(r.review_id) AS Total_Ulasan_Semua_Buku
FROM tbl_authors a
JOIN tbl_books b ON a.author_id = b.author_id
JOIN tbl_reviews r ON b.book_id = r.book_id
GROUP BY a.author_id, a.author_name
ORDER BY Total_Ulasan_Semua_Buku DESC
LIMIT 10;

-- C2. Evaluasi Penulis (Jumlah Karya & Rata-rata Penilaian)
SELECT 
    COALESCE(a.author_name, 'Unknown Author') AS Penulis,
    COUNT(DISTINCT b.book_id) AS Jumlah_Karya_Buku,
    ROUND(AVG(r.rating), 2) AS Rata_Rata_Penilaian
FROM tbl_authors a
LEFT JOIN tbl_books b ON a.author_id = b.author_id
LEFT JOIN tbl_reviews r ON b.book_id = r.book_id
GROUP BY a.author_id, a.author_name
ORDER BY Jumlah_Karya_Buku DESC;

-- C3. Evaluasi Penerbit (Jumlah Buku & Rata-rata Penilaian)
SELECT 
    COALESCE(p.publisher_name, 'Unknown Publisher') AS Penerbit,
    COUNT(DISTINCT b.book_id) AS Jumlah_Buku_Diterbitkan,
    ROUND(AVG(r.rating), 2) AS Rata_Rata_Penilaian
FROM tbl_publishers p
LEFT JOIN tbl_books b ON p.publisher_id = b.publisher_id
LEFT JOIN tbl_reviews r ON b.book_id = r.book_id
GROUP BY p.publisher_id, p.publisher_name
ORDER BY Rata_Rata_Penilaian DESC;

-- C4. Kolaborasi Penulis & Penerbit yang Paling Sering Muncul
SELECT 
    COALESCE(a.author_name, 'Unknown Author') AS Penulis, 
    COALESCE(p.publisher_name, 'Unknown Publisher') AS Penerbit, 
    COUNT(b.book_id) AS Total_Kolaborasi_Buku
FROM tbl_books b
JOIN tbl_authors a ON b.author_id = a.author_id
JOIN tbl_publishers p ON b.publisher_id = p.publisher_id
GROUP BY a.author_id, a.author_name, p.publisher_id, p.publisher_name
HAVING Total_Kolaborasi_Buku > 1
ORDER BY Total_Kolaborasi_Buku DESC;


-- ====================================================================================
-- BAGIAN D: ANALISIS PERILAKU DAN KARAKTERISTIK PENGGUNA
-- ====================================================================================

-- D1. Pengguna Paling Aktif (Top 10 Ulasan Terbanyak)
SELECT 
    u.username, 
    COALESCE(u.city, 'Unknown') AS user_city, 
    COUNT(r.review_id) AS Jumlah_Ulasan_Diberikan
FROM tbl_users u
JOIN tbl_reviews r ON u.user_id = r.user_id
GROUP BY u.user_id, u.username, u.city
ORDER BY Jumlah_Ulasan_Diberikan DESC
LIMIT 10;

-- D2. Sebaran Kota Pengguna
SELECT 
    COALESCE(city, 'Unknown') AS Kota, 
    COUNT(DISTINCT user_id) AS Jumlah_Pengguna
FROM tbl_users
GROUP BY Kota
ORDER BY Jumlah_Pengguna DESC;

-- D3. Distribusi Jenis Kelamin
SELECT 
    COALESCE(gender, 'Unknown') AS Kelamin, 
    COUNT(DISTINCT user_id) AS Jumlah_Pengguna
FROM tbl_users
GROUP BY Kelamin
ORDER BY Jumlah_Pengguna DESC;

-- D4. Analisis Kelompok Usia dan Pola Penilaian (Demografi Spesifik)
-- Menghitung umur real-time berdasarkan tanggal lahir menggunakan TIMESTAMPDIFF
SELECT 
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
ORDER BY Kelompok_Usia ASC;
-- =============================================================================
-- SQL SCHEMA: BOOKS DATABASE (WITH METADATA)
-- =============================================================================
CREATE DATABASE IF NOT EXISTS db_books;
USE db_books;

-- Reset tabel (Urutan Drop penting: Anak dulu, baru Induk)
DROP TABLE IF EXISTS tbl_reviews;
DROP TABLE IF EXISTS tbl_books;
DROP TABLE IF EXISTS tbl_users;
DROP TABLE IF EXISTS tbl_publishers;
DROP TABLE IF EXISTS tbl_authors;

-- =============================================================================
-- BAGIAN 2: TABEL DIMENSI (MASTER DATA)
-- =============================================================================

-- 1. TABEL PENULIS
CREATE TABLE tbl_authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID unik penulis (Auto-generated)',
    author_name VARCHAR(255) NOT NULL COMMENT 'Nama pena penulis (sudah distandarisasi)',
    author_profile VARCHAR(255) COMMENT 'Link foto profil penulis',
    author_biography TEXT COMMENT 'Biografi singkat penulis'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Tabel dimensi menyimpan profil penulis';

-- 2. TABEL PENERBIT
CREATE TABLE tbl_publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID unik penerbit',
    publisher_name VARCHAR(255) NOT NULL COMMENT 'Nama penerbit (sudah diagregasi)',
    url_publisher VARCHAR(255) COMMENT 'Link profil penerbit'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Tabel dimensi menyimpan data penerbit buku';

-- 3. TABEL PENGGUNA
CREATE TABLE tbl_users (
    user_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID unik user sistem',
    username VARCHAR(100) NOT NULL COMMENT 'Nama akun pengguna',
    gender CHAR(1) COMMENT 'Jenis Kelamin: L (Laki-laki) atau P (Perempuan)',
    date_of_birth DATE COMMENT 'Format: YYYY-MM-DD',
    city VARCHAR(100) COMMENT 'Kota domisili user'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Tabel dimensi menyimpan profil reviewer';

-- =============================================================================
-- BAGIAN 3: TABEL UTAMA & TRANSAKSI
-- =============================================================================

-- 4. TABEL BUKU
CREATE TABLE tbl_books (
    book_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate Key: ID unik internal sistem',
    isbn VARCHAR(20) COMMENT 'ISBN Buku (WARNING: Banyak data dummy 979000...)',
    title VARCHAR(255) NOT NULL COMMENT 'Judul buku (sudah dibersihkan)',
    category VARCHAR(100) COMMENT 'Genre atau kategori buku',
    author_id INT COMMENT 'Foreign Key ke tbl_authors',
    publisher_id INT COMMENT 'Foreign Key ke tbl_publishers',
    description TEXT COMMENT 'Sinopsis atau deskripsi buku',
    pages INT COMMENT 'Jumlah halaman',
    language VARCHAR(50) COMMENT 'Bahasa pengantar buku',
    price DECIMAL(15, 2) COMMENT 'Harga buku dalam mata uang lokal (presisi 2 desimal)',
    publish_date DATE COMMENT 'Tanggal terbit',
    cover_book VARCHAR(255) COMMENT 'URL gambar sampul buku',
    url_book VARCHAR(255) COMMENT 'URL halaman produk buku',
    
    -- Constraint Foreign Key
    CONSTRAINT fk_book_author FOREIGN KEY (author_id) 
        REFERENCES tbl_authors(author_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) 
        REFERENCES tbl_publishers(publisher_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Tabel dimensi utama: Katalog Buku (menggunakan Surrogate Key)';

-- 5. TABEL ULASAN
CREATE TABLE tbl_reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID unik transaksi review',
    book_id INT NOT NULL COMMENT 'Foreign Key ke tbl_books',
    user_id INT NOT NULL COMMENT 'Foreign Key ke tbl_users',
    rating INT CHECK (rating BETWEEN 1 AND 5) COMMENT 'Skor rating valid: 1 s.d 5',
    review_date DATE COMMENT 'Tanggal ulasan dibuat',
    
    -- Constraint Foreign Key
    CONSTRAINT fk_review_book FOREIGN KEY (book_id) 
        REFERENCES tbl_books(book_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_review_user FOREIGN KEY (user_id) 
        REFERENCES tbl_users(user_id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Tabel Fakta: Transaksi ulasan pengguna terhadap buku';

-- =============================================================================
-- BAGIAN 4: OPTIMASI PERFORMA (INDEXING)
-- =============================================================================
CREATE INDEX idx_book_title ON tbl_books(title);
CREATE INDEX idx_book_category ON tbl_books(category);
CREATE INDEX idx_book_isbn ON tbl_books(isbn);
CREATE INDEX idx_review_rating ON tbl_reviews(rating);
CREATE INDEX idx_review_date ON tbl_reviews(review_date);
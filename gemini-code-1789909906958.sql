-- ============================================================
-- قاعدة بيانات مخزن كنيسة الأنبا شنودة رئيس المتوحدين بالزرابي
-- Database Schema & Initial Seed Data
-- ============================================================

-- 1. جدول الأدوار والصلاحيات (Roles)
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. جدول المستخدمين (Users)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. جدول التصنيفات (Categories)
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. جدول الموردين والجهات (Suppliers & Entities)
CREATE TABLE IF NOT EXISTS suppliers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    type VARCHAR(20) CHECK (type IN ('supplier', 'entity', 'both')), -- مورد / جهة استلام / كلاهما
    phone VARCHAR(30),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. جدول الأصناف (Products / Items)
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    category_id INT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    unit VARCHAR(30) NOT NULL, -- (كيلو، علبة، كرتونة، قطعة... إلخ)
    quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    min_quantity INT NOT NULL DEFAULT 5,
    location VARCHAR(100),
    image_url TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. جدول حركة الوارد (Stock In)
CREATE TABLE IF NOT EXISTS stock_in (
    id SERIAL PRIMARY KEY,
    receipt_number VARCHAR(50) NOT NULL UNIQUE,
    supplier_id INT REFERENCES suppliers(id) ON DELETE SET NULL,
    product_id INT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) DEFAULT 0.00,
    total_price DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. جدول حركة المنصرف (Stock Out)
CREATE TABLE IF NOT EXISTS stock_out (
    id SERIAL PRIMARY KEY,
    receipt_number VARCHAR(50) NOT NULL UNIQUE,
    recipient_id INT REFERENCES suppliers(id) ON DELETE SET NULL, -- الجهة المستلمة
    product_id INT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    user_id INT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    reason TEXT,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. جدول سجل حركة المخزون الشامل (Stock Movements Audit Trail)
CREATE TABLE IF NOT EXISTS stock_movements (
    id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    type VARCHAR(10) NOT NULL CHECK (type IN ('IN', 'OUT')),
    quantity INT NOT NULL,
    balance_after INT NOT NULL, -- الرصيد المتبقي بعد الحركة
    reference_id INT, -- رقم عملية الوارد أو المنصرف
    user_id INT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. جدول سجل التدقيق والأمان (Audit Logs)
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- البيانات التجريبية الأولية (Seed Data)
-- ============================================================

-- أدوار النظام
INSERT INTO roles (id, name, description) VALUES
(1, 'مدير النظام', 'صلاحيات كاملة للتحكم في الأجهزة والمستخدمين والإعدادات'),
(2, 'أمين المخزن', 'صلاحيات إدخال الوارد والمنصرف وإدارة الأصناف والتصنيفات'),
(3, 'مستخدم للعرض', 'صلاحية قراءة وتقارير فقط بدون تعديل');

-- المستخدمون الافتراضيون (كلمات المرور المشفرة bcrypt)
INSERT INTO users (id, username, full_name, password_hash, role_id) VALUES
(1, 'admin', 'القمص شنودة - مدير المخزن', '$2a$10$YourHashedPasswordHere11111111111111111111111', 1),
(2, 'storekeeper', 'أستاذ مينا - أمين المخزن', '$2a$10$YourHashedPasswordHere22222222222222222222222', 2),
(3, 'viewer', 'خادم الكنيسة - للعرض فقط', '$2a$10$YourHashedPasswordHere33333333333333333333333', 3);

-- التصنيفات
INSERT INTO categories (id, name, description) VALUES
(1, 'مستلزمات الخدمات والكنيسة', 'البخور، الشمع، أواني الخدمة، الأغطية'),
(2, 'أدوات نظافة', 'المنظفات والمطهرات وأدوات التطهير'),
(3, 'مستلزمات مطبخ وخدمة الأغابي', 'الأطباق، الأكواب، وأدوات الضيافة'),
(4, 'أدوات مكتبية ومكتبة', 'الأوراق، الأقلام، والكتب'),
(5, 'أدوات ومستلزمات أنشطة', 'مستلزمات مدارس الأحد والافتئاد');

-- الموردون والجهات
INSERT INTO suppliers (id, name, type, phone, notes) VALUES
(1, 'مكتبة ومستلزمات مارجرجس', 'supplier', '01200000001', 'مورد شمع وبخور'),
(2, 'شركة البركة للمنظفات', 'supplier', '01200000002', 'تعديل أسعار دوري'),
(3, 'خدمة مدارس الأحد', 'entity', '01200000003', 'جهة صرف للمرحلة الابتدائية والإعدادية'),
(4, 'مطبخ القاعة والافتئاد', 'entity', '01200000004', 'مسؤول الضيافة بالمطرانية');

-- الأصناف
INSERT INTO products (id, code, name, category_id, unit, quantity, min_quantity, location, notes) VALUES
(1, 'PRD-101', 'شمع أبيض كبير', 1, 'كيلو', 45, 10, 'رف A1', 'درجة أولى ممتازة'),
(2, 'PRD-102', 'بخور ممتاز للخدمة', 1, 'علبة', 12, 5, 'دولاب B2', 'استيراد مخصوص'),
(3, 'PRD-103', 'صابون سائل مطهر 5 لتر', 2, 'جركن', 18, 5, 'مخزن الأرضي', 'للنظافة الدورية'),
(4, 'PRD-104', 'أكواب بلاستيك استخدام مرة واحدة', 3, 'كرتونة', 3, 5, 'رف C3', 'تحت الحد الأدنى!'),
(5, 'PRD-105', 'ورق تصوير A4 - 80 جرام', 4, 'باكو', 0, 10, 'مكتب الخدمة', 'نافد بالكامل');

-- الفهارس لتحسين الأداء (Indexes)
CREATE INDEX idx_products_code ON products(code);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_stock_in_date ON stock_in(date);
CREATE INDEX idx_stock_out_date ON stock_out(date);
CREATE INDEX idx_movements_product ON stock_movements(product_id);
-- Table pour gérer les réservations de cours
CREATE TABLE IF NOT EXISTS bookings (
    booking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    listing_id BIGINT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    subject VARCHAR(100),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    tutor_name VARCHAR(255),
    price DECIMAL(10, 2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_start_time ON bookings(start_time);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);

-- Commentaires
COMMENT ON TABLE bookings IS 'Table pour stocker les réservations de cours entre étudiants et tuteurs';
COMMENT ON COLUMN bookings.status IS 'Statut de la réservation: pending, confirmed, completed, cancelled';

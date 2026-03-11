-- =========================
-- EXTENSIONS
-- =========================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================
-- ENUMS
-- =========================
CREATE TYPE user_role AS ENUM ('STUDENT', 'TUTOR', 'ADMIN');

CREATE TYPE tx_status AS ENUM ('PENDING', 'CONFIRMED', 'FAILED');
CREATE TYPE tx_type AS ENUM ('TRANSFER', 'REWARD', 'MINT', 'BURN');

CREATE TYPE participation_status AS ENUM ('PENDING', 'CONFIRMED', 'FAILED');

-- =========================
-- USERS
-- =========================
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR NOT NULL UNIQUE,
    password_hash VARCHAR NOT NULL,
    first_name VARCHAR,
    last_name VARCHAR,
    role user_role NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP
);

-- =========================
-- CONVERSATIONS
-- =========================
CREATE TABLE conversations (
    conversation_id SERIAL PRIMARY KEY,
    user1_id UUID NOT NULL REFERENCES users(user_id),
    user2_id UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT no_self_dm CHECK (user1_id <> user2_id),
    CONSTRAINT unique_dm UNIQUE (user1_id, user2_id)
);

-- =========================
-- MESSAGES
-- =========================
CREATE TABLE messages (
    message_id SERIAL PRIMARY KEY,
    conversation_id INT NOT NULL REFERENCES conversations(conversation_id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(user_id),
    receiver_id UUID NOT NULL REFERENCES users(user_id),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================
-- ADMIN ACTIONS
-- =========================
CREATE TABLE admin_actions (
    action_id SERIAL PRIMARY KEY,
    admin_id UUID NOT NULL REFERENCES users(user_id),
    action_type VARCHAR NOT NULL,
    target_id UUID,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================
-- API KEYS
-- =========================
CREATE TABLE api_keys (
    api_key_id SERIAL PRIMARY KEY,
    owner VARCHAR NOT NULL,
    key_hash VARCHAR NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================
-- WALLETS
-- =========================
CREATE TABLE wallets (
    wallet_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    public_address VARCHAR NOT NULL,
    blockchain VARCHAR NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================
-- TRANSACTIONS
-- =========================
CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    tx_hash VARCHAR,
    from_wallet UUID REFERENCES wallets(wallet_id),
    to_wallet UUID REFERENCES wallets(wallet_id),
    amount DECIMAL(18,8) NOT NULL,
    status tx_status NOT NULL,
    type tx_type NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================
-- SERVICES
-- =========================
CREATE TABLE services (
    service_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR NOT NULL,
    description TEXT,
    reward_amount DECIMAL(18,8),
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- =========================
-- SERVICE PARTICIPATIONS
-- =========================
CREATE TABLE service_participations (
    participation_id SERIAL PRIMARY KEY,
    service_id UUID NOT NULL REFERENCES services(service_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    validated_by UUID REFERENCES users(user_id),
    status participation_status NOT NULL,
    validated_at TIMESTAMP
);

-- =========================
-- TUTOR AVAILABILITY SLOTS
-- =========================
CREATE TABLE tutor_availability (
    slot_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tutor_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    listing_id BIGINT,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    is_booked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT valid_slot_time CHECK (end_time > start_time)
);

-- =========================
-- BOOKINGS (RÉSERVATIONS)
-- =========================
CREATE TABLE bookings (
    booking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    listing_id BIGINT,
    slot_id UUID REFERENCES tutor_availability(slot_id) ON DELETE SET NULL,
    title VARCHAR NOT NULL,
    description TEXT,
    subject VARCHAR,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR NOT NULL DEFAULT 'pending',
    tutor_name VARCHAR,
    tutor_email VARCHAR,
    price DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT valid_booking_status CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
    CONSTRAINT valid_booking_time CHECK (end_time > start_time)
);

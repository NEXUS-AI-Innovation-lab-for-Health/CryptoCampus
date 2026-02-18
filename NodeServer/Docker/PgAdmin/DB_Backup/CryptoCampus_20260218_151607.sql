pg_dump: last built-in OID is 16383
pg_dump: reading extensions
pg_dump: identifying extension members
pg_dump: reading schemas
pg_dump: reading user-defined tables
pg_dump: reading user-defined functions
pg_dump: reading user-defined types
pg_dump: reading procedural languages
pg_dump: reading user-defined aggregate functions
pg_dump: reading user-defined operators
pg_dump: reading user-defined access methods
pg_dump: reading user-defined operator classes
pg_dump: reading user-defined operator families
pg_dump: reading user-defined text search parsers
pg_dump: reading user-defined text search templates
pg_dump: reading user-defined text search dictionaries
pg_dump: reading user-defined text search configurations
pg_dump: reading user-defined foreign-data wrappers
pg_dump: reading user-defined foreign servers
pg_dump: reading default privileges
pg_dump: reading user-defined collations
pg_dump: reading user-defined conversions
pg_dump: reading type casts
pg_dump: reading transforms
pg_dump: reading table inheritance information
pg_dump: reading event triggers
pg_dump: finding extension tables
pg_dump: finding inheritance relationships
pg_dump: reading column info for interesting tables
pg_dump: finding table default expressions
pg_dump: finding table check constraints
pg_dump: flagging inherited columns in subtables
pg_dump: reading partitioning data
pg_dump: reading indexes
pg_dump: flagging indexes in partitioned tables
pg_dump: reading extended statistics
pg_dump: reading constraints
pg_dump: reading triggers
pg_dump: reading rewrite rules
pg_dump: reading policies
pg_dump: reading row-level security policies
pg_dump: reading publications
pg_dump: reading publication membership of tables
pg_dump: reading publication membership of schemas
pg_dump: reading subscriptions
pg_dump: reading large objects
pg_dump: reading dependency data
pg_dump: saving encoding = UTF8
pg_dump: saving standard_conforming_strings = on
pg_dump: saving search_path = 
--
-- PostgreSQL database dump
--

\restrict hWWdSxU8hc3XgqGcryXxwC9rmXHeKg8HCSk8vBT6l9U4fcxktJygzYpgTD9PNyG

-- Dumped from database version 16.11 (Debian 16.11-1.pgdg13+1)
-- Dumped by pg_dump version 16.11 (Debian 16.11-1.pgdg13+1)

-- Started on 2026-02-18 14:16:07 UTC

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.wallets DROP CONSTRAINT IF EXISTS wallets_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.transactions DROP CONSTRAINT IF EXISTS transactions_to_wallet_fkey;
ALTER TABLE IF EXISTS ONLY public.transactions DROP CONSTRAINT IF EXISTS transactions_from_wallet_fkey;
ALTER TABLE IF EXISTS ONLY public.services DROP CONSTRAINT IF EXISTS services_created_by_fkey;
ALTER TABLE IF EXISTS ONLY public.service_participations DROP CONSTRAINT IF EXISTS service_participations_validated_by_fkey;
ALTER TABLE IF EXISTS ONLY public.service_participations DROP CONSTRAINT IF EXISTS service_participations_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.service_participations DROP CONSTRAINT IF EXISTS service_participations_service_id_fkey;
ALTER TABLE IF EXISTS ONLY public.messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;
ALTER TABLE IF EXISTS ONLY public.messages DROP CONSTRAINT IF EXISTS messages_receiver_id_fkey;
ALTER TABLE IF EXISTS ONLY public.messages DROP CONSTRAINT IF EXISTS messages_conversation_id_fkey;
ALTER TABLE IF EXISTS ONLY public.conversations DROP CONSTRAINT IF EXISTS conversations_user2_id_fkey;
ALTER TABLE IF EXISTS ONLY public.conversations DROP CONSTRAINT IF EXISTS conversations_user1_id_fkey;
ALTER TABLE IF EXISTS ONLY public.bookings DROP CONSTRAINT IF EXISTS bookings_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.admin_actions DROP CONSTRAINT IF EXISTS admin_actions_admin_id_fkey;
DROP INDEX IF EXISTS public.idx_bookings_user_id;
DROP INDEX IF EXISTS public.idx_bookings_status;
DROP INDEX IF EXISTS public.idx_bookings_start_time;
ALTER TABLE IF EXISTS ONLY public.wallets DROP CONSTRAINT IF EXISTS wallets_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE IF EXISTS ONLY public.conversations DROP CONSTRAINT IF EXISTS unique_dm;
ALTER TABLE IF EXISTS ONLY public.transactions DROP CONSTRAINT IF EXISTS transactions_pkey;
ALTER TABLE IF EXISTS ONLY public.services DROP CONSTRAINT IF EXISTS services_pkey;
ALTER TABLE IF EXISTS ONLY public.service_participations DROP CONSTRAINT IF EXISTS service_participations_pkey;
ALTER TABLE IF EXISTS ONLY public.messages DROP CONSTRAINT IF EXISTS messages_pkey;
ALTER TABLE IF EXISTS ONLY public.conversations DROP CONSTRAINT IF EXISTS conversations_pkey;
ALTER TABLE IF EXISTS ONLY public.bookings DROP CONSTRAINT IF EXISTS bookings_pkey;
ALTER TABLE IF EXISTS ONLY public.api_keys DROP CONSTRAINT IF EXISTS api_keys_pkey;
ALTER TABLE IF EXISTS ONLY public.admin_actions DROP CONSTRAINT IF EXISTS admin_actions_pkey;
ALTER TABLE IF EXISTS public.transactions ALTER COLUMN transaction_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.service_participations ALTER COLUMN participation_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.messages ALTER COLUMN message_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.conversations ALTER COLUMN conversation_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.api_keys ALTER COLUMN api_key_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.admin_actions ALTER COLUMN action_id DROP DEFAULT;
DROP TABLE IF EXISTS public.wallets;
DROP TABLE IF EXISTS public.users;
DROP SEQUENCE IF EXISTS public.transactions_transaction_id_seq;
DROP TABLE IF EXISTS public.transactions;
DROP TABLE IF EXISTS public.services;
DROP SEQUENCE IF EXISTS public.service_participations_participation_id_seq;
DROP TABLE IF EXISTS public.service_participations;
DROP SEQUENCE IF EXISTS public.messages_message_id_seq;
DROP TABLE IF EXISTS public.messages;
DROP SEQUENCE IF EXISTS public.conversations_conversation_id_seq;
DROP TABLE IF EXISTS public.conversations;
DROP TABLE IF EXISTS public.bookings;
DROP SEQUENCE IF EXISTS public.api_keys_api_key_id_seq;
DROP TABLE IF EXISTS public.api_keys;
DROP SEQUENCE IF EXISTS public.admin_actions_action_id_seq;
DROP TABLE IF EXISTS public.admin_actions;
DROP TYPE IF EXISTS public.user_role;
DROP TYPE IF EXISTS public.tx_type;
DROP TYPE IF EXISTS public.tx_status;
DROP TYPE IF EXISTS public.participation_status;
DROP EXTENSION IF EXISTS "uuid-ossp";
--
-- TOC entry 2 (class 3079 OID 16385)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 3561 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 866 (class 1247 OID 16397)
-- Name: participation_status; Type: TYPE; Schema: public; Owner: onlycode-admin
--

CREATE TYPE public.participation_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'FAILED'
);


ALTER TYPE public.participation_status OWNER TO "onlycode-admin";

--
-- TOC entry 869 (class 1247 OID 16404)
-- Name: tx_status; Type: TYPE; Schema: public; Owner: onlycode-admin
--

CREATE TYPE public.tx_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'FAILED'
);


ALTER TYPE public.tx_status OWNER TO "onlycode-admin";

--
-- TOC entry 872 (class 1247 OID 16412)
-- Name: tx_type; Type: TYPE; Schema: public; Owner: onlycode-admin
--

CREATE TYPE public.tx_type AS ENUM (
    'TRANSFER',
    'REWARD',
    'MINT',
    'BURN'
);


ALTER TYPE public.tx_type OWNER TO "onlycode-admin";

--
-- TOC entry 875 (class 1247 OID 16422)
-- Name: user_role; Type: TYPE; Schema: public; Owner: onlycode-admin
--

CREATE TYPE public.user_role AS ENUM (
    'STUDENT',
    'TUTOR',
    'ADMIN'
);


ALTER TYPE public.user_role OWNER TO "onlycode-admin";

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 216 (class 1259 OID 16429)
-- Name: admin_actions; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.admin_actions (
    action_id integer NOT NULL,
    admin_id uuid NOT NULL,
    action_type character varying NOT NULL,
    target_id uuid,
    description text,
    created_at date DEFAULT CURRENT_DATE
);


ALTER TABLE public.admin_actions OWNER TO "onlycode-admin";

--
-- TOC entry 217 (class 1259 OID 16435)
-- Name: admin_actions_action_id_seq; Type: SEQUENCE; Schema: public; Owner: onlycode-admin
--

CREATE SEQUENCE public.admin_actions_action_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_actions_action_id_seq OWNER TO "onlycode-admin";

--
-- TOC entry 3562 (class 0 OID 0)
-- Dependencies: 217
-- Name: admin_actions_action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.admin_actions_action_id_seq OWNED BY public.admin_actions.action_id;


--
-- TOC entry 218 (class 1259 OID 16436)
-- Name: api_keys; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.api_keys (
    api_key_id integer NOT NULL,
    owner character varying NOT NULL,
    key_hash character varying NOT NULL,
    is_active boolean DEFAULT true,
    created_at date DEFAULT CURRENT_DATE
);


ALTER TABLE public.api_keys OWNER TO "onlycode-admin";

--
-- TOC entry 219 (class 1259 OID 16443)
-- Name: api_keys_api_key_id_seq; Type: SEQUENCE; Schema: public; Owner: onlycode-admin
--

CREATE SEQUENCE public.api_keys_api_key_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_keys_api_key_id_seq OWNER TO "onlycode-admin";

--
-- TOC entry 3563 (class 0 OID 0)
-- Dependencies: 219
-- Name: api_keys_api_key_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.api_keys_api_key_id_seq OWNED BY public.api_keys.api_key_id;


--
-- TOC entry 231 (class 1259 OID 16588)
-- Name: bookings; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.bookings (
    booking_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    listing_id bigint,
    title character varying(255) NOT NULL,
    description text,
    subject character varying(100),
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying,
    tutor_name character varying(255),
    price numeric(10,2),
    notes text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.bookings OWNER TO "onlycode-admin";

--
-- TOC entry 3564 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE bookings; Type: COMMENT; Schema: public; Owner: onlycode-admin
--

COMMENT ON TABLE public.bookings IS 'Table pour stocker les réservations de cours entre étudiants et tuteurs';


--
-- TOC entry 3565 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN bookings.status; Type: COMMENT; Schema: public; Owner: onlycode-admin
--

COMMENT ON COLUMN public.bookings.status IS 'Statut de la réservation: pending, confirmed, completed, cancelled';


--
-- TOC entry 220 (class 1259 OID 16444)
-- Name: conversations; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.conversations (
    conversation_id integer NOT NULL,
    user1_id uuid NOT NULL,
    user2_id uuid NOT NULL,
    created_at date DEFAULT CURRENT_DATE,
    CONSTRAINT no_self_dm CHECK ((user1_id <> user2_id))
);


ALTER TABLE public.conversations OWNER TO "onlycode-admin";

--
-- TOC entry 221 (class 1259 OID 16449)
-- Name: conversations_conversation_id_seq; Type: SEQUENCE; Schema: public; Owner: onlycode-admin
--

CREATE SEQUENCE public.conversations_conversation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.conversations_conversation_id_seq OWNER TO "onlycode-admin";

--
-- TOC entry 3566 (class 0 OID 0)
-- Dependencies: 221
-- Name: conversations_conversation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.conversations_conversation_id_seq OWNED BY public.conversations.conversation_id;


--
-- TOC entry 222 (class 1259 OID 16450)
-- Name: messages; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.messages (
    message_id integer NOT NULL,
    conversation_id integer NOT NULL,
    sender_id uuid NOT NULL,
    receiver_id uuid NOT NULL,
    content text NOT NULL,
    is_read boolean DEFAULT false,
    created_at date DEFAULT CURRENT_DATE
);


ALTER TABLE public.messages OWNER TO "onlycode-admin";

--
-- TOC entry 223 (class 1259 OID 16457)
-- Name: messages_message_id_seq; Type: SEQUENCE; Schema: public; Owner: onlycode-admin
--

CREATE SEQUENCE public.messages_message_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.messages_message_id_seq OWNER TO "onlycode-admin";

--
-- TOC entry 3567 (class 0 OID 0)
-- Dependencies: 223
-- Name: messages_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.messages_message_id_seq OWNED BY public.messages.message_id;


--
-- TOC entry 224 (class 1259 OID 16458)
-- Name: service_participations; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.service_participations (
    participation_id integer NOT NULL,
    service_id uuid NOT NULL,
    user_id uuid NOT NULL,
    validated_by uuid,
    status public.participation_status NOT NULL,
    validated_at date
);


ALTER TABLE public.service_participations OWNER TO "onlycode-admin";

--
-- TOC entry 225 (class 1259 OID 16461)
-- Name: service_participations_participation_id_seq; Type: SEQUENCE; Schema: public; Owner: onlycode-admin
--

CREATE SEQUENCE public.service_participations_participation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.service_participations_participation_id_seq OWNER TO "onlycode-admin";

--
-- TOC entry 3568 (class 0 OID 0)
-- Dependencies: 225
-- Name: service_participations_participation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.service_participations_participation_id_seq OWNED BY public.service_participations.participation_id;


--
-- TOC entry 226 (class 1259 OID 16462)
-- Name: services; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.services (
    service_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying NOT NULL,
    description text,
    reward_amount numeric(18,8),
    created_by uuid NOT NULL,
    created_at date DEFAULT CURRENT_DATE
);


ALTER TABLE public.services OWNER TO "onlycode-admin";

--
-- TOC entry 227 (class 1259 OID 16469)
-- Name: transactions; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.transactions (
    transaction_id integer NOT NULL,
    tx_hash character varying,
    from_wallet uuid,
    to_wallet uuid,
    amount numeric(18,8) NOT NULL,
    status public.tx_status NOT NULL,
    type public.tx_type NOT NULL,
    created_at date DEFAULT CURRENT_DATE
);


ALTER TABLE public.transactions OWNER TO "onlycode-admin";

--
-- TOC entry 228 (class 1259 OID 16475)
-- Name: transactions_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: onlycode-admin
--

CREATE SEQUENCE public.transactions_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transactions_transaction_id_seq OWNER TO "onlycode-admin";

--
-- TOC entry 3569 (class 0 OID 0)
-- Dependencies: 228
-- Name: transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.transactions_transaction_id_seq OWNED BY public.transactions.transaction_id;


--
-- TOC entry 229 (class 1259 OID 16476)
-- Name: users; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.users (
    user_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying NOT NULL,
    password_hash character varying NOT NULL,
    first_name character varying,
    last_name character varying,
    role public.user_role NOT NULL,
    is_verified boolean DEFAULT false,
    created_at date DEFAULT CURRENT_DATE,
    last_login date
);


ALTER TABLE public.users OWNER TO "onlycode-admin";

--
-- TOC entry 230 (class 1259 OID 16484)
-- Name: wallets; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.wallets (
    wallet_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    public_address character varying NOT NULL,
    blockchain character varying NOT NULL,
    created_at date DEFAULT CURRENT_DATE
);


ALTER TABLE public.wallets OWNER TO "onlycode-admin";

--
-- TOC entry 3331 (class 2604 OID 16491)
-- Name: admin_actions action_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.admin_actions ALTER COLUMN action_id SET DEFAULT nextval('public.admin_actions_action_id_seq'::regclass);


--
-- TOC entry 3333 (class 2604 OID 16492)
-- Name: api_keys api_key_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN api_key_id SET DEFAULT nextval('public.api_keys_api_key_id_seq'::regclass);


--
-- TOC entry 3336 (class 2604 OID 16493)
-- Name: conversations conversation_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations ALTER COLUMN conversation_id SET DEFAULT nextval('public.conversations_conversation_id_seq'::regclass);


--
-- TOC entry 3338 (class 2604 OID 16494)
-- Name: messages message_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABpg_dump: dropping FK CONSTRAINT wallets wallets_user_id_fkey
pg_dump: dropping FK CONSTRAINT transactions transactions_to_wallet_fkey
pg_dump: dropping FK CONSTRAINT transactions transactions_from_wallet_fkey
pg_dump: dropping FK CONSTRAINT services services_created_by_fkey
pg_dump: dropping FK CONSTRAINT service_participations service_participations_validated_by_fkey
pg_dump: dropping FK CONSTRAINT service_participations service_participations_user_id_fkey
pg_dump: dropping FK CONSTRAINT service_participations service_participations_service_id_fkey
pg_dump: dropping FK CONSTRAINT messages messages_sender_id_fkey
pg_dump: dropping FK CONSTRAINT messages messages_receiver_id_fkey
pg_dump: dropping FK CONSTRAINT messages messages_conversation_id_fkey
pg_dump: dropping FK CONSTRAINT conversations conversations_user2_id_fkey
pg_dump: dropping FK CONSTRAINT conversations conversations_user1_id_fkey
pg_dump: dropping FK CONSTRAINT bookings bookings_user_id_fkey
pg_dump: dropping FK CONSTRAINT admin_actions admin_actions_admin_id_fkey
pg_dump: dropping INDEX idx_bookings_user_id
pg_dump: dropping INDEX idx_bookings_status
pg_dump: dropping INDEX idx_bookings_start_time
pg_dump: dropping CONSTRAINT wallets wallets_pkey
pg_dump: dropping CONSTRAINT users users_pkey
pg_dump: dropping CONSTRAINT users users_email_key
pg_dump: dropping CONSTRAINT conversations unique_dm
pg_dump: dropping CONSTRAINT transactions transactions_pkey
pg_dump: dropping CONSTRAINT services services_pkey
pg_dump: dropping CONSTRAINT service_participations service_participations_pkey
pg_dump: dropping CONSTRAINT messages messages_pkey
pg_dump: dropping CONSTRAINT conversations conversations_pkey
pg_dump: dropping CONSTRAINT bookings bookings_pkey
pg_dump: dropping CONSTRAINT api_keys api_keys_pkey
pg_dump: dropping CONSTRAINT admin_actions admin_actions_pkey
pg_dump: dropping DEFAULT transactions transaction_id
pg_dump: dropping DEFAULT service_participations participation_id
pg_dump: dropping DEFAULT messages message_id
pg_dump: dropping DEFAULT conversations conversation_id
pg_dump: dropping DEFAULT api_keys api_key_id
pg_dump: dropping DEFAULT admin_actions action_id
pg_dump: dropping TABLE wallets
pg_dump: dropping TABLE users
pg_dump: dropping SEQUENCE transactions_transaction_id_seq
pg_dump: dropping TABLE transactions
pg_dump: dropping TABLE services
pg_dump: dropping SEQUENCE service_participations_participation_id_seq
pg_dump: dropping TABLE service_participations
pg_dump: dropping SEQUENCE messages_message_id_seq
pg_dump: dropping TABLE messages
pg_dump: dropping SEQUENCE conversations_conversation_id_seq
pg_dump: dropping TABLE conversations
pg_dump: dropping TABLE bookings
pg_dump: dropping SEQUENCE api_keys_api_key_id_seq
pg_dump: dropping TABLE api_keys
pg_dump: dropping SEQUENCE admin_actions_action_id_seq
pg_dump: dropping TABLE admin_actions
pg_dump: dropping TYPE user_role
pg_dump: dropping TYPE tx_type
pg_dump: dropping TYPE tx_status
pg_dump: dropping TYPE participation_status
pg_dump: dropping EXTENSION uuid-ossp
pg_dump: creating EXTENSION "uuid-ossp"
pg_dump: creating COMMENT "EXTENSION "uuid-ossp""
pg_dump: creating TYPE "public.participation_status"
pg_dump: creating TYPE "public.tx_status"
pg_dump: creating TYPE "public.tx_type"
pg_dump: creating TYPE "public.user_role"
pg_dump: creating TABLE "public.admin_actions"
pg_dump: creating SEQUENCE "public.admin_actions_action_id_seq"
pg_dump: creating SEQUENCE OWNED BY "public.admin_actions_action_id_seq"
pg_dump: creating TABLE "public.api_keys"
pg_dump: creating SEQUENCE "public.api_keys_api_key_id_seq"
pg_dump: creating SEQUENCE OWNED BY "public.api_keys_api_key_id_seq"
pg_dump: creating TABLE "public.bookings"
pg_dump: creating COMMENT "public.TABLE bookings"
pg_dump: creating COMMENT "public.COLUMN bookings.status"
pg_dump: creating TABLE "public.conversations"
pg_dump: creating SEQUENCE "public.conversations_conversation_id_seq"
pg_dump: creating SEQUENCE OWNED BY "public.conversations_conversation_id_seq"
pg_dump: creating TABLE "public.messages"
pg_dump: creating SEQUENCE "public.messages_message_id_seq"
pg_dump: creating SEQUENCE OWNED BY "public.messages_message_id_seq"
pg_dump: creating TABLE "public.service_participations"
pg_dump: creating SEQUENCE "public.service_participations_participation_id_seq"
pg_dump: creating SEQUENCE OWNED BY "public.service_participations_participation_id_seq"
pg_dump: creating TABLE "public.services"
pg_dump: creating TABLE "public.transactions"
pg_dump: creating SEQUENCE "public.transactions_transaction_id_seq"
pg_dump: creating SEQUENCE OWNED BY "public.transactions_transaction_id_seq"
pg_dump: creating TABLE "public.users"
pg_dump: creating TABLE "public.wallets"
pg_dump: creating DEFAULT "public.admin_actions action_id"
pg_dump: creating DEFAULT "public.api_keys api_key_id"
pg_dump: creating DEFAULT "public.conversations conversation_id"
pg_dump: creating DEFAULT "public.messages message_id"
pg_dump: creating DEFAULT "public.service_participations participation_id"
pg_dump: creating DEFAULT "public.transactions transaction_id"
pg_dump: processing data for table "public.admin_actions"
pg_dump: dumping contents of table "public.admin_actions"
pg_dump: processing data for table "public.api_keys"
pg_dump: dumping contents of table "public.api_keys"
pg_dump: processing data for table "public.bookings"
pg_dump: dumping contents of table "public.bookings"
pg_dump: processing data for table "public.conversations"
pg_dump: dumping contents of table "public.conversations"
pg_dump: processing data for table "public.messages"
pg_dump: dumping contents of table "public.messages"
pg_dump: processing data for table "public.service_participations"
pg_dump: dumping contents of table "public.service_participations"
pg_dump: processing data for table "public.services"
pg_dump: dumping contents of table "public.services"
pg_dump: processing data for table "public.transactions"
pg_dump: dumping contents of table "public.transactions"
LE ONLY public.messages ALTER COLUMN message_id SET DEFAULT nextval('public.messages_message_id_seq'::regclass);


--
-- TOC entry 3341 (class 2604 OID 16495)
-- Name: service_participations participation_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations ALTER COLUMN participation_id SET DEFAULT nextval('public.service_participations_participation_id_seq'::regclass);


--
-- TOC entry 3344 (class 2604 OID 16496)
-- Name: transactions transaction_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.transactions ALTER COLUMN transaction_id SET DEFAULT nextval('public.transactions_transaction_id_seq'::regclass);


--
-- TOC entry 3540 (class 0 OID 16429)
-- Dependencies: 216
-- Data for Name: admin_actions; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.admin_actions (action_id, admin_id, action_type, target_id, description, created_at) FROM stdin;
\.


--
-- TOC entry 3542 (class 0 OID 16436)
-- Dependencies: 218
-- Data for Name: api_keys; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.api_keys (api_key_id, owner, key_hash, is_active, created_at) FROM stdin;
\.


--
-- TOC entry 3555 (class 0 OID 16588)
-- Dependencies: 231
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.bookings (booking_id, user_id, listing_id, title, description, subject, start_time, end_time, status, tutor_name, price, notes, created_at, updated_at) FROM stdin;
27d244d7-62d1-4b7e-8c05-9139f1c24648	b6073d5c-1bbd-4b05-99dc-d92af7f7028e	1771422234850	Anglais Technique pour l'Informatique	Améliorez votre anglais technique avec un focus sur les termes spécifiques à l'informatique. Idéal pour les professionnels ou étudiants en informatique.	Anglais	2026-02-19 15:12:00	2026-02-19 16:12:00	confirmed	Sevo HAKOBYAN	18.00	test de notes 	2026-02-18 14:12:12.149891	2026-02-18 14:12:57.169072
\.


--
-- TOC entry 3544 (class 0 OID 16444)
-- Dependencies: 220
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.conversations (conversation_id, user1_id, user2_id, created_at) FROM stdin;
\.


--
-- TOC entry 3546 (class 0 OID 16450)
-- Dependencies: 222
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.messages (message_id, conversation_id, sender_id, receiver_id, content, is_read, created_at) FROM stdin;
\.


--
-- TOC entry 3548 (class 0 OID 16458)
-- Dependencies: 224
-- Data for Name: service_participations; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.service_participations (participation_id, service_id, user_id, validated_by, status, validated_at) FROM stdin;
1	a1234567-1234-1234-1234-123456789abc	992b73dd-8d15-4188-963a-fb706d4c1a90	ce7b2d46-06c4-44c4-b03d-4543da466a1d	CONFIRMED	2026-02-18
\.


--
-- TOC entry 3550 (class 0 OID 16462)
-- Dependencies: 226
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.services (service_id, title, description, reward_amount, created_by, created_at) FROM stdin;
a1234567-1234-1234-1234-123456789abc	Cours de Mathématiques Avancées	Cours particulier de maths niveau universitaire	50.00000000	ce7b2d46-06c4-44c4-b03d-4543da466a1d	2026-02-18
b2345678-2345-2345-2345-234567890bcd	Cours de Physique Quantique	Introduction à la mécanique quantique	80.00000000	ce7b2d46-06c4-44c4-b03d-4543da466a1d	2026-02-18
\.


--
-- TOC entry 3551 (class 0 OID 16469)
-- Dependencies: 227
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.transactions (transaction_id, tx_hash, from_wallet, to_wallet, amount, status, type, created_at) FROM stdin;
1	0xabc123def456789	79df1982-c98a-4a7c-8a20-5400ee2f55f1	d86a961b-5e26-4c86-8e23-50be49af2ffd	50.00000000	CONFIRMED	REWARD	2026-02-18
2	0xdef789ghi012345	79df1982-c98a-4a7c-8a20-5400ee2f55f1	d86a961b-5e26-4c86-8e23-50be49af2ffd	75.50000000	CONFIRMED	REWARD	2026-02-18
\.


--
-- TOC entry 3pg_dump: processing data for table "public.users"
pg_dump: dumping contents of table "public.users"
pg_dump: processing data for table "public.wallets"
pg_dump: dumping contents of table "public.wallets"
pg_dump: executing SEQUENCE SET admin_actions_action_id_seq
pg_dump: executing SEQUENCE SET api_keys_api_key_id_seq
pg_dump: executing SEQUENCE SET conversations_conversation_id_seq
pg_dump: executing SEQUENCE SET messages_message_id_seq
pg_dump: executing SEQUENCE SET service_participations_participation_id_seq
pg_dump: executing SEQUENCE SET transactions_transaction_id_seq
pg_dump: creating CONSTRAINT "public.admin_actions admin_actions_pkey"
pg_dump: creating CONSTRAINT "public.api_keys api_keys_pkey"
pg_dump: creating CONSTRAINT "public.bookings bookings_pkey"
pg_dump: creating CONSTRAINT "public.conversations conversations_pkey"
pg_dump: creating CONSTRAINT "public.messages messages_pkey"
pg_dump: creating CONSTRAINT "public.service_participations service_participations_pkey"
pg_dump: creating CONSTRAINT "public.services services_pkey"
pg_dump: creating CONSTRAINT "public.transactions transactions_pkey"
pg_dump: creating CONSTRAINT "public.conversations unique_dm"
pg_dump: creating CONSTRAINT "public.users users_email_key"
pg_dump: creating CONSTRAINT "public.users users_pkey"
pg_dump: creating CONSTRAINT "public.wallets wallets_pkey"
pg_dump: creating INDEX "public.idx_bookings_start_time"
pg_dump: creating INDEX "public.idx_bookings_status"
pg_dump: creating INDEX "public.idx_bookings_user_id"
pg_dump: creating FK CONSTRAINT "public.admin_actions admin_actions_admin_id_fkey"
pg_dump: creating FK CONSTRAINT "public.bookings bookings_user_id_fkey"
pg_dump: creating FK CONSTRAINT "public.conversations conversations_user1_id_fkey"
pg_dump: creating FK CONSTRAINT "public.conversations conversations_user2_id_fkey"
pg_dump: creating FK CONSTRAINT "public.messages messages_conversation_id_fkey"
pg_dump: creating FK CONSTRAINT "public.messages messages_receiver_id_fkey"
pg_dump: creating FK CONSTRAINT "public.messages messages_sender_id_fkey"
pg_dump: creating FK CONSTRAINT "public.service_participations service_participations_service_id_fkey"
pg_dump: creating FK CONSTRAINT "public.service_participations service_participations_user_id_fkey"
pg_dump: creating FK CONSTRAINT "public.service_participations service_participations_validated_by_fkey"
pg_dump: creating FK CONSTRAINT "public.services services_created_by_fkey"
pg_dump: creating FK CONSTRAINT "public.transactions transactions_from_wallet_fkey"
pg_dump: creating FK CONSTRAINT "public.transactions transactions_to_wallet_fkey"
pg_dump: creating FK CONSTRAINT "public.wallets wallets_user_id_fkey"
553 (class 0 OID 16476)
-- Dependencies: 229
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.users (user_id, email, password_hash, first_name, last_name, role, is_verified, created_at, last_login) FROM stdin;
ce7b2d46-06c4-44c4-b03d-4543da466a1d	admin@test.com	hash_admin	Admin	Root	ADMIN	f	2026-01-14	\N
992b73dd-8d15-4188-963a-fb706d4c1a90	sevo@test.com	hash_sevo	Sevo	Hakobyan	STUDENT	f	2026-01-14	\N
5830914b-d857-49ec-975d-5068f8a5fdb0	thomas@test.com	hash_thomas	Thomas	Feler	STUDENT	f	2026-01-14	\N
2d228927-c66d-4d1a-83a1-282f05a0d9fd	sevo.hakobyan@test.com	$2b$12$gEHzMov2vn64TgYLvzUkO.oznMQ9OMAplG2xkho5rD.MYbN/jOZsy	Sevo	Hakobyan	TUTOR	f	2026-02-18	2026-02-18
b6073d5c-1bbd-4b05-99dc-d92af7f7028e	sevo.hakobyan.etu@test.com	$2b$12$MtPpvtwjUYOGKmSh4r/h5ufXjo94qx1cAZtmc9JU5yrGf7BO1kwKq	sevo	hakobyan	STUDENT	f	2026-02-18	2026-02-18
\.


--
-- TOC entry 3554 (class 0 OID 16484)
-- Dependencies: 230
-- Data for Name: wallets; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.wallets (wallet_id, user_id, public_address, blockchain, created_at) FROM stdin;
d86a961b-5e26-4c86-8e23-50be49af2ffd	ce7b2d46-06c4-44c4-b03d-4543da466a1d	0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1	ethereum	2026-02-18
9a555b5a-47a6-45c1-8e96-3b49b4b9bf8b	ce7b2d46-06c4-44c4-b03d-4543da466a1d	0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1	ethereum	2026-02-18
79df1982-c98a-4a7c-8a20-5400ee2f55f1	992b73dd-8d15-4188-963a-fb706d4c1a90	0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0	ethereum	2026-02-18
ebfd0445-08fd-418e-bf92-9a6a7c5b2b08	2d228927-c66d-4d1a-83a1-282f05a0d9fd	0x22d491Bde2303f2f43325b2108D26f1eAbA1e32b	ethereum	2026-02-18
707719aa-5f2d-4bc8-9f9b-c06dbf46a4b7	b6073d5c-1bbd-4b05-99dc-d92af7f7028e	0xE11BA2b4D45Eaed5996Cd0823791E0C93114882d	ethereum	2026-02-18
\.


--
-- TOC entry 3570 (class 0 OID 0)
-- Dependencies: 217
-- Name: admin_actions_action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.admin_actions_action_id_seq', 1, false);


--
-- TOC entry 3571 (class 0 OID 0)
-- Dependencies: 219
-- Name: api_keys_api_key_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.api_keys_api_key_id_seq', 1, false);


--
-- TOC entry 3572 (class 0 OID 0)
-- Dependencies: 221
-- Name: conversations_conversation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.conversations_conversation_id_seq', 1, false);


--
-- TOC entry 3573 (class 0 OID 0)
-- Dependencies: 223
-- Name: messages_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.messages_message_id_seq', 1, false);


--
-- TOC entry 3574 (class 0 OID 0)
-- Dependencies: 225
-- Name: service_participations_participation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.service_participations_participation_id_seq', 1, true);


--
-- TOC entry 3575 (class 0 OID 0)
-- Dependencies: 228
-- Name: transactions_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.transactions_transaction_id_seq', 2, true);


--
-- TOC entry 3357 (class 2606 OID 16498)
-- Name: admin_actions admin_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.admin_actions
    ADD CONSTRAINT admin_actions_pkey PRIMARY KEY (action_id);


--
-- TOC entry 3359 (class 2606 OID 16500)
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (api_key_id);


--
-- TOC entry 3379 (class 2606 OID 16598)
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (booking_id);


--
-- TOC entry 3361 (class 2606 OID 16502)
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (conversation_id);


--
-- TOC entry 3365 (class 2606 OID 16504)
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (message_id);


--
-- TOC entry 3367 (class 2606 OID 16506)
-- Name: service_participations service_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations
    ADD CONSTRAINT service_participations_pkey PRIMARY KEY (participation_id);


--
-- TOC entry 3369 (class 2606 OID 16508)
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (service_id);


--
-- TOC entry 3371 (class 2606 OID 16510)
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);


--
-- TOC entry 3363 (class 2606 OID 16512)
-- Name: conversations unique_dm; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT unique_dm UNIQUE (user1_id, user2_id);


--
-- TOC entry 3373 (class 2606 OID 16514)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3375 (class 2606 OID 16516)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3377 (class 2606 OID 16518)
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (wallet_id);


--
-- TOC entry 3380 (class 1259 OID 16605)
-- Name: idx_bookings_start_time; Type: INDEX; Schema: public; Owner: onlycode-admin
--

CREATE INDEX idx_bookings_start_time ON public.bookings USING btree (start_time);


--
-- TOC entry 3381 (class 1259 OID 16606)
-- Name: idx_bookings_status; Type: INDEX; Schema: public; Owner: onlycode-admin
--

CREATE INDEX idx_bookings_status ON public.bookings USING btree (status);


--
-- TOC entry 3382 (class 1259 OID 16604)
-- Name: idx_bookings_user_id; Type: INDEX; Schema: public; Owner: onlycode-admin
--

CREATE INDEX idx_bookings_user_id ON public.bookings USING btree (user_id);


--
-- TOC entry 3383 (class 2606 OID 16519)
-- Name: admin_actions admin_actions_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.admin_actions
    ADD CONSTRAINT admin_actions_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(user_id);


--
-- TOC entry 3396 (class 2606 OID 16599)
-- Name: bookings bookings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3384 (class 2606 OID 16524)
-- Name: conversations conversations_user1_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_user1_id_fkey FOREIGN KEY (user1_id) REFERENCES public.users(user_id);


--
-- TOC entry 3385 (class 2606 OID 16529)
-- Name: conversations conversations_user2_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_user2_id_fkey FOREIGN KEY (user2_id) REFERENCES public.users(user_id);


--
-- TOC entry 3386 (class 2606 OID 16534)
-- Name: messages messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(conversation_id) ON DELETE CASCADE;


--
-- TOC entry 3387 (class 2606 OID 16539)
-- Name: messages messages_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(user_id);


--
-- TOC entry 3388 (class 2606 OID 16544)
-- Name: messages messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(user_id);


--
-- TOC entry 3389 (class 2606 OID 16549)
-- Name: service_participations service_participations_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations
    ADD CONSTRAINT service_participations_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(service_id);


--
-- TOC entry 3390 (class 2606 OID 16554)
-- Name: service_participations service_participations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations
    ADD CONSTRAINT service_participations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3391 (class 2606 OID 16559)
-- Name: service_participations service_participations_validated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations
    ADD CONSTRAINT service_participations_validated_by_fkey FOREIGN KEY (validated_by) REFERENCES public.users(user_id);


--
-- TOC entry 3392 (class 2606 OID 16564)
-- Name: services services_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- TOC entry 3393 (class 2606 OID 16569)
-- Name: transactions transactions_from_wallet_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_from_wallet_fkey FOREIGN KEY (from_wallet) REFERENCES public.wallets(wallet_id);


--
-- TOC entry 3394 (class 2606 OID 16574)
-- Name: transactions transactions_to_wallet_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_to_wallet_fkey FOREIGN KEY (to_wallet) REFERENCES public.wallets(wallet_id);


--
-- TOC entry 3395 (class 2606 OID 16579)
-- Name: wallets wallets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


-- Completed on 2026-02-18 14:16:07 UTC

--
-- PostgreSQL database dump complete
--

\unrestrict hWWdSxU8hc3XgqGcryXxwC9rmXHeKg8HCSk8vBT6l9U4fcxktJygzYpgTD9PNyG


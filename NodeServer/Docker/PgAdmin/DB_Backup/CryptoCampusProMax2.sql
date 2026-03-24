--
-- PostgreSQL database dump
--

\restrict Fn8aSf9eXHyiQKX69KTWaXqrC3BsAC9tOaN3g1kdcZBoOKbkNEnMvqELJ79wLai

-- Dumped from database version 16.12 (Debian 16.12-1.pgdg13+1)
-- Dumped by pg_dump version 16.11

-- Started on 2026-03-24 15:15:43 UTC

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

--
-- TOC entry 2 (class 3079 OID 16385)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 3574 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 876 (class 1247 OID 16422)
-- Name: participation_status; Type: TYPE; Schema: public; Owner: onlycode-admin
--

CREATE TYPE public.participation_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'FAILED'
);


ALTER TYPE public.participation_status OWNER TO "onlycode-admin";

--
-- TOC entry 870 (class 1247 OID 16404)
-- Name: tx_status; Type: TYPE; Schema: public; Owner: onlycode-admin
--

CREATE TYPE public.tx_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'FAILED'
);


ALTER TYPE public.tx_status OWNER TO "onlycode-admin";

--
-- TOC entry 873 (class 1247 OID 16412)
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
-- TOC entry 867 (class 1247 OID 16397)
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
-- TOC entry 222 (class 1259 OID 16489)
-- Name: admin_actions; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.admin_actions (
    action_id integer NOT NULL,
    admin_id uuid NOT NULL,
    action_type character varying NOT NULL,
    target_id uuid,
    description text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.admin_actions OWNER TO "onlycode-admin";

--
-- TOC entry 221 (class 1259 OID 16488)
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
-- TOC entry 3575 (class 0 OID 0)
-- Dependencies: 221
-- Name: admin_actions_action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.admin_actions_action_id_seq OWNED BY public.admin_actions.action_id;


--
-- TOC entry 224 (class 1259 OID 16504)
-- Name: api_keys; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.api_keys (
    api_key_id integer NOT NULL,
    owner character varying NOT NULL,
    key_hash character varying NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.api_keys OWNER TO "onlycode-admin";

--
-- TOC entry 223 (class 1259 OID 16503)
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
-- TOC entry 3576 (class 0 OID 0)
-- Dependencies: 223
-- Name: api_keys_api_key_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.api_keys_api_key_id_seq OWNED BY public.api_keys.api_key_id;


--
-- TOC entry 232 (class 1259 OID 16598)
-- Name: bookings; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.bookings (
    booking_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    listing_id bigint,
    slot_id uuid,
    title character varying NOT NULL,
    description text,
    subject character varying,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    tutor_name character varying,
    tutor_email character varying,
    price numeric(10,2),
    notes text,
    is_notified_tutor boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT valid_booking_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'confirmed'::character varying, 'completed'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT valid_booking_time CHECK ((end_time > start_time))
);


ALTER TABLE public.bookings OWNER TO "onlycode-admin";

--
-- TOC entry 218 (class 1259 OID 16442)
-- Name: conversations; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.conversations (
    conversation_id integer NOT NULL,
    user1_id uuid NOT NULL,
    user2_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT no_self_dm CHECK ((user1_id <> user2_id))
);


ALTER TABLE public.conversations OWNER TO "onlycode-admin";

--
-- TOC entry 217 (class 1259 OID 16441)
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
-- TOC entry 3577 (class 0 OID 0)
-- Dependencies: 217
-- Name: conversations_conversation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.conversations_conversation_id_seq OWNED BY public.conversations.conversation_id;


--
-- TOC entry 220 (class 1259 OID 16463)
-- Name: messages; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.messages (
    message_id integer NOT NULL,
    conversation_id integer NOT NULL,
    sender_id uuid NOT NULL,
    receiver_id uuid NOT NULL,
    content text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.messages OWNER TO "onlycode-admin";

--
-- TOC entry 219 (class 1259 OID 16462)
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
-- TOC entry 3578 (class 0 OID 0)
-- Dependencies: 219
-- Name: messages_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.messages_message_id_seq OWNED BY public.messages.message_id;


--
-- TOC entry 230 (class 1259 OID 16563)
-- Name: service_participations; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.service_participations (
    participation_id integer NOT NULL,
    service_id uuid NOT NULL,
    user_id uuid NOT NULL,
    validated_by uuid,
    status public.participation_status NOT NULL,
    validated_at timestamp without time zone
);


ALTER TABLE public.service_participations OWNER TO "onlycode-admin";

--
-- TOC entry 229 (class 1259 OID 16562)
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
-- TOC entry 3579 (class 0 OID 0)
-- Dependencies: 229
-- Name: service_participations_participation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.service_participations_participation_id_seq OWNED BY public.service_participations.participation_id;


--
-- TOC entry 228 (class 1259 OID 16548)
-- Name: services; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.services (
    service_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying NOT NULL,
    description text,
    reward_amount numeric(18,8),
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.services OWNER TO "onlycode-admin";

--
-- TOC entry 227 (class 1259 OID 16529)
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
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.transactions OWNER TO "onlycode-admin";

--
-- TOC entry 226 (class 1259 OID 16528)
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
-- TOC entry 3580 (class 0 OID 0)
-- Dependencies: 226
-- Name: transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.transactions_transaction_id_seq OWNED BY public.transactions.transaction_id;


--
-- TOC entry 231 (class 1259 OID 16584)
-- Name: tutor_availability; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.tutor_availability (
    slot_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tutor_user_id uuid NOT NULL,
    listing_id bigint,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    is_booked boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT valid_slot_time CHECK ((end_time > start_time))
);


ALTER TABLE public.tutor_availability OWNER TO "onlycode-admin";

--
-- TOC entry 216 (class 1259 OID 16429)
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
    created_at timestamp without time zone DEFAULT now(),
    last_login timestamp without time zone
);


ALTER TABLE public.users OWNER TO "onlycode-admin";

--
-- TOC entry 225 (class 1259 OID 16514)
-- Name: wallets; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public.wallets (
    wallet_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    public_address character varying NOT NULL,
    blockchain character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.wallets OWNER TO "onlycode-admin";

--
-- TOC entry 3343 (class 2604 OID 16492)
-- Name: admin_actions action_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.admin_actions ALTER COLUMN action_id SET DEFAULT nextval('public.admin_actions_action_id_seq'::regclass);


--
-- TOC entry 3345 (class 2604 OID 16507)
-- Name: api_keys api_key_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN api_key_id SET DEFAULT nextval('public.api_keys_api_key_id_seq'::regclass);


--
-- TOC entry 3338 (class 2604 OID 16445)
-- Name: conversations conversation_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations ALTER COLUMN conversation_id SET DEFAULT nextval('public.conversations_conversation_id_seq'::regclass);


--
-- TOC entry 3340 (class 2604 OID 16466)
-- Name: messages message_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages ALTER COLUMN message_id SET DEFAULT nextval('public.messages_message_id_seq'::regclass);


--
-- TOC entry 3354 (class 2604 OID 16566)
-- Name: service_participations participation_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations ALTER COLUMN participation_id SET DEFAULT nextval('public.service_participations_participation_id_seq'::regclass);


--
-- TOC entry 3350 (class 2604 OID 16532)
-- Name: transactions transaction_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.transactions ALTER COLUMN transaction_id SET DEFAULT nextval('public.transactions_transaction_id_seq'::regclass);


--
-- TOC entry 3558 (class 0 OID 16489)
-- Dependencies: 222
-- Data for Name: admin_actions; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.admin_actions (action_id, admin_id, action_type, target_id, description, created_at) FROM stdin;
\.


--
-- TOC entry 3560 (class 0 OID 16504)
-- Dependencies: 224
-- Data for Name: api_keys; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.api_keys (api_key_id, owner, key_hash, is_active, created_at) FROM stdin;
\.


--
-- TOC entry 3568 (class 0 OID 16598)
-- Dependencies: 232
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.bookings (booking_id, user_id, listing_id, slot_id, title, description, subject, start_time, end_time, status, tutor_name, tutor_email, price, notes, is_notified_tutor, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3554 (class 0 OID 16442)
-- Dependencies: 218
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.conversations (conversation_id, user1_id, user2_id, created_at) FROM stdin;
\.


--
-- TOC entry 3556 (class 0 OID 16463)
-- Dependencies: 220
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.messages (message_id, conversation_id, sender_id, receiver_id, content, is_read, created_at) FROM stdin;
\.


--
-- TOC entry 3566 (class 0 OID 16563)
-- Dependencies: 230
-- Data for Name: service_participations; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.service_participations (participation_id, service_id, user_id, validated_by, status, validated_at) FROM stdin;
\.


--
-- TOC entry 3564 (class 0 OID 16548)
-- Dependencies: 228
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.services (service_id, title, description, reward_amount, created_by, created_at) FROM stdin;
\.


--
-- TOC entry 3563 (class 0 OID 16529)
-- Dependencies: 227
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.transactions (transaction_id, tx_hash, from_wallet, to_wallet, amount, status, type, created_at) FROM stdin;
\.


--
-- TOC entry 3567 (class 0 OID 16584)
-- Dependencies: 231
-- Data for Name: tutor_availability; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.tutor_availability (slot_id, tutor_user_id, listing_id, start_time, end_time, is_booked, created_at) FROM stdin;
\.


--
-- TOC entry 3552 (class 0 OID 16429)
-- Dependencies: 216
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.users (user_id, email, password_hash, first_name, last_name, role, is_verified, created_at, last_login) FROM stdin;
c18faf16-bd2a-41e8-9363-bdd2725256c7	eleve.etu@test.com	$2b$12$Iu9cxpaBWx9C3GysiA4vQe2W134lwYGVnaoEghL9ldpqI.oMwXhQO	eleve	etu	STUDENT	f	2026-03-24 14:43:45.47679	2026-03-24 14:43:46.681409
3f4a77ca-7395-4bcb-b341-ae6f2e66bd33	tuteur.etu@test.com	$2b$12$wTUM7MDJ7dCFgjkzyxkHVusJzUu6rnTx.mG2X2cu8DLJkKiCE04l6	tuteur	etu	TUTOR	f	2026-03-24 14:42:18.350938	2026-03-24 15:01:22.295078
\.


--
-- TOC entry 3561 (class 0 OID 16514)
-- Dependencies: 225
-- Data for Name: wallets; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.wallets (wallet_id, user_id, public_address, blockchain, created_at) FROM stdin;
b40a1339-4284-4b5f-a3cc-4459062f25e9	3f4a77ca-7395-4bcb-b341-ae6f2e66bd33	0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1	ethereum	2026-03-24 14:42:18.407459
90d506bb-b00a-44ee-a126-ada80f519a55	c18faf16-bd2a-41e8-9363-bdd2725256c7	0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0	ethereum	2026-03-24 14:43:45.505144
\.


--
-- TOC entry 3581 (class 0 OID 0)
-- Dependencies: 221
-- Name: admin_actions_action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.admin_actions_action_id_seq', 1, false);


--
-- TOC entry 3582 (class 0 OID 0)
-- Dependencies: 223
-- Name: api_keys_api_key_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.api_keys_api_key_id_seq', 1, false);


--
-- TOC entry 3583 (class 0 OID 0)
-- Dependencies: 217
-- Name: conversations_conversation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.conversations_conversation_id_seq', 1, false);


--
-- TOC entry 3584 (class 0 OID 0)
-- Dependencies: 219
-- Name: messages_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.messages_message_id_seq', 1, false);


--
-- TOC entry 3585 (class 0 OID 0)
-- Dependencies: 229
-- Name: service_participations_participation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.service_participations_participation_id_seq', 1, false);


--
-- TOC entry 3586 (class 0 OID 0)
-- Dependencies: 226
-- Name: transactions_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.transactions_transaction_id_seq', 1, false);


--
-- TOC entry 3378 (class 2606 OID 16497)
-- Name: admin_actions admin_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.admin_actions
    ADD CONSTRAINT admin_actions_pkey PRIMARY KEY (action_id);


--
-- TOC entry 3380 (class 2606 OID 16513)
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (api_key_id);


--
-- TOC entry 3392 (class 2606 OID 16611)
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (booking_id);


--
-- TOC entry 3372 (class 2606 OID 16449)
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (conversation_id);


--
-- TOC entry 3376 (class 2606 OID 16472)
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (message_id);


--
-- TOC entry 3388 (class 2606 OID 16568)
-- Name: service_participations service_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations
    ADD CONSTRAINT service_participations_pkey PRIMARY KEY (participation_id);


--
-- TOC entry 3386 (class 2606 OID 16556)
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (service_id);


--
-- TOC entry 3384 (class 2606 OID 16537)
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);


--
-- TOC entry 3390 (class 2606 OID 16592)
-- Name: tutor_availability tutor_availability_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.tutor_availability
    ADD CONSTRAINT tutor_availability_pkey PRIMARY KEY (slot_id);


--
-- TOC entry 3374 (class 2606 OID 16451)
-- Name: conversations unique_dm; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT unique_dm UNIQUE (user1_id, user2_id);


--
-- TOC entry 3368 (class 2606 OID 16440)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3370 (class 2606 OID 16438)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3382 (class 2606 OID 16522)
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (wallet_id);


--
-- TOC entry 3398 (class 2606 OID 16498)
-- Name: admin_actions admin_actions_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.admin_actions
    ADD CONSTRAINT admin_actions_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(user_id);


--
-- TOC entry 3407 (class 2606 OID 16617)
-- Name: bookings bookings_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_slot_id_fkey FOREIGN KEY (slot_id) REFERENCES public.tutor_availability(slot_id) ON DELETE SET NULL;


--
-- TOC entry 3408 (class 2606 OID 16612)
-- Name: bookings bookings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3393 (class 2606 OID 16452)
-- Name: conversations conversations_user1_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_user1_id_fkey FOREIGN KEY (user1_id) REFERENCES public.users(user_id);


--
-- TOC entry 3394 (class 2606 OID 16457)
-- Name: conversations conversations_user2_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_user2_id_fkey FOREIGN KEY (user2_id) REFERENCES public.users(user_id);


--
-- TOC entry 3395 (class 2606 OID 16473)
-- Name: messages messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(conversation_id) ON DELETE CASCADE;


--
-- TOC entry 3396 (class 2606 OID 16483)
-- Name: messages messages_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(user_id);


--
-- TOC entry 3397 (class 2606 OID 16478)
-- Name: messages messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(user_id);


--
-- TOC entry 3403 (class 2606 OID 16569)
-- Name: service_participations service_participations_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations
    ADD CONSTRAINT service_participations_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(service_id);


--
-- TOC entry 3404 (class 2606 OID 16574)
-- Name: service_participations service_participations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations
    ADD CONSTRAINT service_participations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3405 (class 2606 OID 16579)
-- Name: service_participations service_participations_validated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations
    ADD CONSTRAINT service_participations_validated_by_fkey FOREIGN KEY (validated_by) REFERENCES public.users(user_id);


--
-- TOC entry 3402 (class 2606 OID 16557)
-- Name: services services_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- TOC entry 3400 (class 2606 OID 16538)
-- Name: transactions transactions_from_wallet_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_from_wallet_fkey FOREIGN KEY (from_wallet) REFERENCES public.wallets(wallet_id);


--
-- TOC entry 3401 (class 2606 OID 16543)
-- Name: transactions transactions_to_wallet_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_to_wallet_fkey FOREIGN KEY (to_wallet) REFERENCES public.wallets(wallet_id);


--
-- TOC entry 3406 (class 2606 OID 16593)
-- Name: tutor_availability tutor_availability_tutor_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.tutor_availability
    ADD CONSTRAINT tutor_availability_tutor_user_id_fkey FOREIGN KEY (tutor_user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3399 (class 2606 OID 16523)
-- Name: wallets wallets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


-- Completed on 2026-03-24 15:15:43 UTC

--
-- PostgreSQL database dump complete
--

\unrestrict Fn8aSf9eXHyiQKX69KTWaXqrC3BsAC9tOaN3g1kdcZBoOKbkNEnMvqELJ79wLai


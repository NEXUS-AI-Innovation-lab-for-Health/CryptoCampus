--
-- PostgreSQL database dump
--

\restrict omuH5FCMd3oCsA01Fr2uai7220GyUxb2eTgDmI6GRxBdKOrmeIDoRM8p9ByqGMq

-- Dumped from database version 16.11 (Debian 16.11-1.pgdg13+1)
-- Dumped by pg_dump version 16.11

-- Started on 2026-01-14 17:31:49 UTC

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
-- TOC entry 2 (class 3079 OID 16396)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 3546 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 874 (class 1247 OID 16434)
-- Name: participation_status; Type: TYPE; Schema: public; Owner: onlycode-admin
--

CREATE TYPE public.participation_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'FAILED'
);


ALTER TYPE public.participation_status OWNER TO "onlycode-admin";

--
-- TOC entry 868 (class 1247 OID 16416)
-- Name: tx_status; Type: TYPE; Schema: public; Owner: onlycode-admin
--

CREATE TYPE public.tx_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'FAILED'
);


ALTER TYPE public.tx_status OWNER TO "onlycode-admin";

--
-- TOC entry 871 (class 1247 OID 16424)
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
-- TOC entry 865 (class 1247 OID 16408)
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
-- TOC entry 222 (class 1259 OID 16501)
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
-- TOC entry 221 (class 1259 OID 16500)
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
-- TOC entry 3547 (class 0 OID 0)
-- Dependencies: 221
-- Name: admin_actions_action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.admin_actions_action_id_seq OWNED BY public.admin_actions.action_id;


--
-- TOC entry 224 (class 1259 OID 16516)
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
-- TOC entry 223 (class 1259 OID 16515)
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
-- TOC entry 3548 (class 0 OID 0)
-- Dependencies: 223
-- Name: api_keys_api_key_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.api_keys_api_key_id_seq OWNED BY public.api_keys.api_key_id;


--
-- TOC entry 218 (class 1259 OID 16454)
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
-- TOC entry 217 (class 1259 OID 16453)
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
-- TOC entry 3549 (class 0 OID 0)
-- Dependencies: 217
-- Name: conversations_conversation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.conversations_conversation_id_seq OWNED BY public.conversations.conversation_id;


--
-- TOC entry 220 (class 1259 OID 16475)
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
-- TOC entry 219 (class 1259 OID 16474)
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
-- TOC entry 3550 (class 0 OID 0)
-- Dependencies: 219
-- Name: messages_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.messages_message_id_seq OWNED BY public.messages.message_id;


--
-- TOC entry 230 (class 1259 OID 16575)
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
-- TOC entry 229 (class 1259 OID 16574)
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
-- TOC entry 3551 (class 0 OID 0)
-- Dependencies: 229
-- Name: service_participations_participation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.service_participations_participation_id_seq OWNED BY public.service_participations.participation_id;


--
-- TOC entry 228 (class 1259 OID 16560)
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
-- TOC entry 227 (class 1259 OID 16541)
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
-- TOC entry 226 (class 1259 OID 16540)
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
-- TOC entry 3552 (class 0 OID 0)
-- Dependencies: 226
-- Name: transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: onlycode-admin
--

ALTER SEQUENCE public.transactions_transaction_id_seq OWNED BY public.transactions.transaction_id;


--
-- TOC entry 216 (class 1259 OID 16441)
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
-- TOC entry 225 (class 1259 OID 16526)
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
-- TOC entry 3335 (class 2604 OID 16504)
-- Name: admin_actions action_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.admin_actions ALTER COLUMN action_id SET DEFAULT nextval('public.admin_actions_action_id_seq'::regclass);


--
-- TOC entry 3337 (class 2604 OID 16519)
-- Name: api_keys api_key_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN api_key_id SET DEFAULT nextval('public.api_keys_api_key_id_seq'::regclass);


--
-- TOC entry 3330 (class 2604 OID 16457)
-- Name: conversations conversation_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations ALTER COLUMN conversation_id SET DEFAULT nextval('public.conversations_conversation_id_seq'::regclass);


--
-- TOC entry 3332 (class 2604 OID 16478)
-- Name: messages message_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages ALTER COLUMN message_id SET DEFAULT nextval('public.messages_message_id_seq'::regclass);


--
-- TOC entry 3346 (class 2604 OID 16578)
-- Name: service_participations participation_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations ALTER COLUMN participation_id SET DEFAULT nextval('public.service_participations_participation_id_seq'::regclass);


--
-- TOC entry 3342 (class 2604 OID 16544)
-- Name: transactions transaction_id; Type: DEFAULT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.transactions ALTER COLUMN transaction_id SET DEFAULT nextval('public.transactions_transaction_id_seq'::regclass);


--
-- TOC entry 3532 (class 0 OID 16501)
-- Dependencies: 222
-- Data for Name: admin_actions; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.admin_actions (action_id, admin_id, action_type, target_id, description, created_at) FROM stdin;
\.


--
-- TOC entry 3534 (class 0 OID 16516)
-- Dependencies: 224
-- Data for Name: api_keys; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.api_keys (api_key_id, owner, key_hash, is_active, created_at) FROM stdin;
\.


--
-- TOC entry 3528 (class 0 OID 16454)
-- Dependencies: 218
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.conversations (conversation_id, user1_id, user2_id, created_at) FROM stdin;
\.


--
-- TOC entry 3530 (class 0 OID 16475)
-- Dependencies: 220
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.messages (message_id, conversation_id, sender_id, receiver_id, content, is_read, created_at) FROM stdin;
\.


--
-- TOC entry 3540 (class 0 OID 16575)
-- Dependencies: 230
-- Data for Name: service_participations; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.service_participations (participation_id, service_id, user_id, validated_by, status, validated_at) FROM stdin;
\.


--
-- TOC entry 3538 (class 0 OID 16560)
-- Dependencies: 228
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.services (service_id, title, description, reward_amount, created_by, created_at) FROM stdin;
\.


--
-- TOC entry 3537 (class 0 OID 16541)
-- Dependencies: 227
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.transactions (transaction_id, tx_hash, from_wallet, to_wallet, amount, status, type, created_at) FROM stdin;
\.


--
-- TOC entry 3526 (class 0 OID 16441)
-- Dependencies: 216
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.users (user_id, email, password_hash, first_name, last_name, role, is_verified, created_at, last_login) FROM stdin;
ce7b2d46-06c4-44c4-b03d-4543da466a1d	admin@test.com	hash_admin	Admin	Root	ADMIN	f	2026-01-14	\N
992b73dd-8d15-4188-963a-fb706d4c1a90	sevo@test.com	hash_sevo	Sevo	Hakobyan	STUDENT	f	2026-01-14	\N
5830914b-d857-49ec-975d-5068f8a5fdb0	thomas@test.com	hash_thomas	Thomas	Feler	STUDENT	f	2026-01-14	\N
\.


--
-- TOC entry 3535 (class 0 OID 16526)
-- Dependencies: 225
-- Data for Name: wallets; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.wallets (wallet_id, user_id, public_address, blockchain, created_at) FROM stdin;
\.


--
-- TOC entry 3553 (class 0 OID 0)
-- Dependencies: 221
-- Name: admin_actions_action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.admin_actions_action_id_seq', 1, false);


--
-- TOC entry 3554 (class 0 OID 0)
-- Dependencies: 223
-- Name: api_keys_api_key_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.api_keys_api_key_id_seq', 1, false);


--
-- TOC entry 3555 (class 0 OID 0)
-- Dependencies: 217
-- Name: conversations_conversation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.conversations_conversation_id_seq', 1, false);


--
-- TOC entry 3556 (class 0 OID 0)
-- Dependencies: 219
-- Name: messages_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.messages_message_id_seq', 1, false);


--
-- TOC entry 3557 (class 0 OID 0)
-- Dependencies: 229
-- Name: service_participations_participation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.service_participations_participation_id_seq', 1, false);


--
-- TOC entry 3558 (class 0 OID 0)
-- Dependencies: 226
-- Name: transactions_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: onlycode-admin
--

SELECT pg_catalog.setval('public.transactions_transaction_id_seq', 1, false);


--
-- TOC entry 3359 (class 2606 OID 16509)
-- Name: admin_actions admin_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.admin_actions
    ADD CONSTRAINT admin_actions_pkey PRIMARY KEY (action_id);


--
-- TOC entry 3361 (class 2606 OID 16525)
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (api_key_id);


--
-- TOC entry 3353 (class 2606 OID 16461)
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (conversation_id);


--
-- TOC entry 3357 (class 2606 OID 16484)
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (message_id);


--
-- TOC entry 3369 (class 2606 OID 16580)
-- Name: service_participations service_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations
    ADD CONSTRAINT service_participations_pkey PRIMARY KEY (participation_id);


--
-- TOC entry 3367 (class 2606 OID 16568)
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (service_id);


--
-- TOC entry 3365 (class 2606 OID 16549)
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);


--
-- TOC entry 3355 (class 2606 OID 16463)
-- Name: conversations unique_dm; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT unique_dm UNIQUE (user1_id, user2_id);


--
-- TOC entry 3349 (class 2606 OID 16452)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3351 (class 2606 OID 16450)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3363 (class 2606 OID 16534)
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (wallet_id);


--
-- TOC entry 3375 (class 2606 OID 16510)
-- Name: admin_actions admin_actions_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.admin_actions
    ADD CONSTRAINT admin_actions_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(user_id);


--
-- TOC entry 3370 (class 2606 OID 16464)
-- Name: conversations conversations_user1_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_user1_id_fkey FOREIGN KEY (user1_id) REFERENCES public.users(user_id);


--
-- TOC entry 3371 (class 2606 OID 16469)
-- Name: conversations conversations_user2_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_user2_id_fkey FOREIGN KEY (user2_id) REFERENCES public.users(user_id);


--
-- TOC entry 3372 (class 2606 OID 16485)
-- Name: messages messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(conversation_id) ON DELETE CASCADE;


--
-- TOC entry 3373 (class 2606 OID 16495)
-- Name: messages messages_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(user_id);


--
-- TOC entry 3374 (class 2606 OID 16490)
-- Name: messages messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(user_id);


--
-- TOC entry 3380 (class 2606 OID 16581)
-- Name: service_participations service_participations_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations
    ADD CONSTRAINT service_participations_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(service_id);


--
-- TOC entry 3381 (class 2606 OID 16586)
-- Name: service_participations service_participations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations
    ADD CONSTRAINT service_participations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3382 (class 2606 OID 16591)
-- Name: service_participations service_participations_validated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.service_participations
    ADD CONSTRAINT service_participations_validated_by_fkey FOREIGN KEY (validated_by) REFERENCES public.users(user_id);


--
-- TOC entry 3379 (class 2606 OID 16569)
-- Name: services services_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- TOC entry 3377 (class 2606 OID 16550)
-- Name: transactions transactions_from_wallet_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_from_wallet_fkey FOREIGN KEY (from_wallet) REFERENCES public.wallets(wallet_id);


--
-- TOC entry 3378 (class 2606 OID 16555)
-- Name: transactions transactions_to_wallet_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_to_wallet_fkey FOREIGN KEY (to_wallet) REFERENCES public.wallets(wallet_id);


--
-- TOC entry 3376 (class 2606 OID 16535)
-- Name: wallets wallets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


-- Completed on 2026-01-14 17:31:49 UTC

--
-- PostgreSQL database dump complete
--

\unrestrict omuH5FCMd3oCsA01Fr2uai7220GyUxb2eTgDmI6GRxBdKOrmeIDoRM8p9ByqGMq


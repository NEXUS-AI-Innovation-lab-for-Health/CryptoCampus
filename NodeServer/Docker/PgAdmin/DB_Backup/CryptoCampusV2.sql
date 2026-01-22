--
-- PostgreSQL database dump
--

\restrict mPuVcr7Au98RbEtyrykHer9vMGfDwfPWAk8v18xy0yyYd0z3529SEdzvxtMKYmb

-- Dumped from database version 16.11 (Debian 16.11-1.pgdg13+1)
-- Dumped by pg_dump version 16.11

-- Started on 2026-01-22 11:41:45 UTC

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

SET default_tablespace = '';

SET default_table_access_method = heap;

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
-- TOC entry 3464 (class 0 OID 16476)
-- Dependencies: 229
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public.users (user_id, email, password_hash, first_name, last_name, role, is_verified, created_at, last_login) FROM stdin;
ce7b2d46-06c4-44c4-b03d-4543da466a1d	admin@test.com	hash_admin	Admin	Root	ADMIN	f	2026-01-14	\N
992b73dd-8d15-4188-963a-fb706d4c1a90	sevo@test.com	hash_sevo	Sevo	Hakobyan	STUDENT	f	2026-01-14	\N
5830914b-d857-49ec-975d-5068f8a5fdb0	thomas@test.com	hash_thomas	Thomas	Feler	STUDENT	f	2026-01-14	\N
\.


--
-- TOC entry 3318 (class 2606 OID 16514)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3320 (class 2606 OID 16516)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


-- Completed on 2026-01-22 11:41:45 UTC

--
-- PostgreSQL database dump complete
--

\unrestrict mPuVcr7Au98RbEtyrykHer9vMGfDwfPWAk8v18xy0yyYd0z3529SEdzvxtMKYmb


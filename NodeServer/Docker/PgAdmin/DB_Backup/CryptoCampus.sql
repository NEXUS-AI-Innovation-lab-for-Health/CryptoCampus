--
-- PostgreSQL database dump
--

\restrict BcqofVGu4iRwepo7UwfD27Uq4qsN7F5RaZMt9t34hxrRgkXIg1CcXHrq8Um81Od

-- Dumped from database version 16.11 (Debian 16.11-1.pgdg13+1)
-- Dumped by pg_dump version 16.11

-- Started on 2026-01-05 17:32:39 UTC

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
-- TOC entry 215 (class 1259 OID 16389)
-- Name: Users; Type: TABLE; Schema: public; Owner: onlycode-admin
--

CREATE TABLE public."Users" (
    "Username" character varying(50) NOT NULL,
    "FirstName" character varying(50) NOT NULL,
    "LastName" character varying(50) NOT NULL,
    "Balance" integer DEFAULT 0 NOT NULL
);


ALTER TABLE public."Users" OWNER TO "onlycode-admin";

--
-- TOC entry 3411 (class 0 OID 16389)
-- Dependencies: 215
-- Data for Name: Users; Type: TABLE DATA; Schema: public; Owner: onlycode-admin
--

COPY public."Users" ("Username", "FirstName", "LastName", "Balance") FROM stdin;
\.


--
-- TOC entry 3267 (class 2606 OID 16394)
-- Name: Users Users_pkey; Type: CONSTRAINT; Schema: public; Owner: onlycode-admin
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_pkey" PRIMARY KEY ("Username");


-- Completed on 2026-01-05 17:32:39 UTC

--
-- PostgreSQL database dump complete
--

\unrestrict BcqofVGu4iRwepo7UwfD27Uq4qsN7F5RaZMt9t34hxrRgkXIg1CcXHrq8Um81Od


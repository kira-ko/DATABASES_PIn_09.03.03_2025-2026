--
-- PostgreSQL database dump
--

\restrict wP1pCEAH3Yasof2giJ1mTee03iyNAy6Jpo1bmJ2VeSgmJzG0r4OxYmzDZDr6pB7

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

-- Started on 2026-06-02 22:43:18

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
-- TOC entry 5010 (class 1262 OID 24576)
-- Name: library_db; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE library_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';


ALTER DATABASE library_db OWNER TO postgres;

\unrestrict wP1pCEAH3Yasof2giJ1mTee03iyNAy6Jpo1bmJ2VeSgmJzG0r4OxYmzDZDr6pB7
\connect library_db
\restrict wP1pCEAH3Yasof2giJ1mTee03iyNAy6Jpo1bmJ2VeSgmJzG0r4OxYmzDZDr6pB7

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
-- TOC entry 6 (class 2615 OID 24577)
-- Name: library; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA library;


ALTER SCHEMA library OWNER TO postgres;

--
-- TOC entry 5011 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA library; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA library IS 'Schema for the Library database, variant 3';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 226 (class 1259 OID 24636)
-- Name: book_copy; Type: TABLE; Schema: library; Owner: postgres
--

CREATE TABLE library.book_copy (
    inventory_number character varying(20) NOT NULL,
    publication_id integer NOT NULL,
    storage_place_id integer NOT NULL,
    receipt_document_id integer NOT NULL,
    price numeric(10,2) NOT NULL,
    registration_date date NOT NULL,
    withdrawal_date date,
    copy_status character varying(30) NOT NULL,
    CONSTRAINT chk_book_copy_price CHECK ((price > (0)::numeric)),
    CONSTRAINT chk_book_copy_registration_date CHECK ((registration_date <= CURRENT_DATE)),
    CONSTRAINT chk_book_copy_status CHECK (((copy_status)::text = ANY ((ARRAY['available'::character varying, 'issued'::character varying, 'written off'::character varying, 'lost'::character varying])::text[]))),
    CONSTRAINT chk_book_copy_withdrawal_date CHECK (((withdrawal_date IS NULL) OR (withdrawal_date >= registration_date)))
);


ALTER TABLE library.book_copy OWNER TO postgres;

--
-- TOC entry 5012 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE book_copy; Type: COMMENT; Schema: library; Owner: postgres
--

COMMENT ON TABLE library.book_copy IS 'Stores information about individual physical copies of publications.';


--
-- TOC entry 221 (class 1259 OID 24601)
-- Name: employee; Type: TABLE; Schema: library; Owner: postgres
--

CREATE TABLE library.employee (
    employee_id integer NOT NULL,
    full_name character varying(255) NOT NULL,
    "position" character varying(100) NOT NULL,
    number_of_rates numeric(3,2) NOT NULL,
    CONSTRAINT chk_employee_number_of_rates CHECK (((number_of_rates > (0)::numeric) AND (number_of_rates <= (2)::numeric))),
    CONSTRAINT chk_employee_position CHECK ((("position")::text = ANY ((ARRAY['librarian'::character varying, 'accountant'::character varying, 'administrator'::character varying, 'fund manager'::character varying, 'other'::character varying])::text[])))
);


ALTER TABLE library.employee OWNER TO postgres;

--
-- TOC entry 5013 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE employee; Type: COMMENT; Schema: library; Owner: postgres
--

COMMENT ON TABLE library.employee IS 'Stores library employee data.';


--
-- TOC entry 220 (class 1259 OID 24600)
-- Name: employee_employee_id_seq; Type: SEQUENCE; Schema: library; Owner: postgres
--

ALTER TABLE library.employee ALTER COLUMN employee_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME library.employee_employee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 229 (class 1259 OID 24673)
-- Name: loan; Type: TABLE; Schema: library; Owner: postgres
--

CREATE TABLE library.loan (
    loan_id integer NOT NULL,
    library_card_number character varying(20) NOT NULL,
    inventory_number character varying(20) NOT NULL,
    issue_date date NOT NULL,
    planned_return_date date NOT NULL,
    actual_return_date date,
    fine_amount numeric(10,2) DEFAULT 0 NOT NULL,
    CONSTRAINT chk_loan_actual_return_date CHECK (((actual_return_date IS NULL) OR (actual_return_date >= issue_date))),
    CONSTRAINT chk_loan_fine_amount CHECK ((fine_amount >= (0)::numeric)),
    CONSTRAINT chk_loan_issue_date CHECK ((issue_date <= CURRENT_DATE)),
    CONSTRAINT chk_loan_planned_return_date CHECK (((planned_return_date >= issue_date) AND (planned_return_date <= (issue_date + '10 days'::interval))))
);


ALTER TABLE library.loan OWNER TO postgres;

--
-- TOC entry 5014 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE loan; Type: COMMENT; Schema: library; Owner: postgres
--

COMMENT ON TABLE library.loan IS 'Stores book loan records for readers.';


--
-- TOC entry 228 (class 1259 OID 24672)
-- Name: loan_loan_id_seq; Type: SEQUENCE; Schema: library; Owner: postgres
--

ALTER TABLE library.loan ALTER COLUMN loan_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME library.loan_loan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 217 (class 1259 OID 24579)
-- Name: publication; Type: TABLE; Schema: library; Owner: postgres
--

CREATE TABLE library.publication (
    publication_id integer NOT NULL,
    title character varying(255) NOT NULL,
    volume_number integer,
    release_year integer NOT NULL,
    author character varying(255) NOT NULL,
    publication_type character varying(100) NOT NULL,
    publisher character varying(255) NOT NULL,
    knowledge_area character varying(150),
    publication_city character varying(100),
    library_code character varying(50) NOT NULL,
    CONSTRAINT chk_publication_release_year CHECK (((release_year >= 1000) AND (release_year <= (EXTRACT(year FROM CURRENT_DATE))::integer))),
    CONSTRAINT chk_publication_type CHECK (((publication_type)::text = ANY ((ARRAY['collection'::character varying, 'reference book'::character varying, 'monograph'::character varying, 'textbook'::character varying, 'manual'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT chk_publication_volume_number CHECK (((volume_number IS NULL) OR (volume_number >= 1)))
);


ALTER TABLE library.publication OWNER TO postgres;

--
-- TOC entry 5015 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE publication; Type: COMMENT; Schema: library; Owner: postgres
--

COMMENT ON TABLE library.publication IS 'Stores bibliographic information about publications.';


--
-- TOC entry 216 (class 1259 OID 24578)
-- Name: publication_publication_id_seq; Type: SEQUENCE; Schema: library; Owner: postgres
--

ALTER TABLE library.publication ALTER COLUMN publication_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME library.publication_publication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 227 (class 1259 OID 24660)
-- Name: reader; Type: TABLE; Schema: library; Owner: postgres
--

CREATE TABLE library.reader (
    library_card_number character varying(20) NOT NULL,
    full_name character varying(255) NOT NULL,
    passport_data character varying(100) NOT NULL,
    address character varying(255) NOT NULL,
    phone character varying(20),
    email character varying(255),
    education_level character varying(100),
    CONSTRAINT chk_reader_email CHECK (((email IS NULL) OR ((email)::text ~~ '%@%'::text)))
);


ALTER TABLE library.reader OWNER TO postgres;

--
-- TOC entry 5016 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE reader; Type: COMMENT; Schema: library; Owner: postgres
--

COMMENT ON TABLE library.reader IS 'Stores library reader data.';


--
-- TOC entry 225 (class 1259 OID 24617)
-- Name: receipt_document; Type: TABLE; Schema: library; Owner: postgres
--

CREATE TABLE library.receipt_document (
    receipt_document_id integer NOT NULL,
    document_number character varying(50) NOT NULL,
    document_type character varying(80) NOT NULL,
    document_date date NOT NULL,
    supplier_id integer,
    employee_id integer NOT NULL,
    CONSTRAINT chk_receipt_document_date CHECK ((document_date <= CURRENT_DATE)),
    CONSTRAINT chk_receipt_document_type CHECK (((document_type)::text = ANY ((ARRAY['invoice'::character varying, 'acceptance act'::character varying, 'lost replacement act'::character varying])::text[])))
);


ALTER TABLE library.receipt_document OWNER TO postgres;

--
-- TOC entry 5017 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE receipt_document; Type: COMMENT; Schema: library; Owner: postgres
--

COMMENT ON TABLE library.receipt_document IS 'Stores documents used to register publications received by the library.';


--
-- TOC entry 224 (class 1259 OID 24616)
-- Name: receipt_document_receipt_document_id_seq; Type: SEQUENCE; Schema: library; Owner: postgres
--

ALTER TABLE library.receipt_document ALTER COLUMN receipt_document_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME library.receipt_document_receipt_document_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 219 (class 1259 OID 24590)
-- Name: storage_place; Type: TABLE; Schema: library; Owner: postgres
--

CREATE TABLE library.storage_place (
    storage_place_id integer NOT NULL,
    room_number integer NOT NULL,
    shelf_unit_number integer NOT NULL,
    shelf_number integer NOT NULL,
    CONSTRAINT chk_storage_room_number CHECK ((room_number > 0)),
    CONSTRAINT chk_storage_shelf_number CHECK ((shelf_number > 0)),
    CONSTRAINT chk_storage_shelf_unit_number CHECK ((shelf_unit_number > 0))
);


ALTER TABLE library.storage_place OWNER TO postgres;

--
-- TOC entry 5018 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE storage_place; Type: COMMENT; Schema: library; Owner: postgres
--

COMMENT ON TABLE library.storage_place IS 'Stores information about rooms, shelf units and shelves where book copies are located.';


--
-- TOC entry 218 (class 1259 OID 24589)
-- Name: storage_place_storage_place_id_seq; Type: SEQUENCE; Schema: library; Owner: postgres
--

ALTER TABLE library.storage_place ALTER COLUMN storage_place_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME library.storage_place_storage_place_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 223 (class 1259 OID 24609)
-- Name: supplier; Type: TABLE; Schema: library; Owner: postgres
--

CREATE TABLE library.supplier (
    supplier_id integer NOT NULL,
    supplier_name character varying(255) NOT NULL
);


ALTER TABLE library.supplier OWNER TO postgres;

--
-- TOC entry 5019 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE supplier; Type: COMMENT; Schema: library; Owner: postgres
--

COMMENT ON TABLE library.supplier IS 'Stores suppliers of library documents and publications.';


--
-- TOC entry 222 (class 1259 OID 24608)
-- Name: supplier_supplier_id_seq; Type: SEQUENCE; Schema: library; Owner: postgres
--

ALTER TABLE library.supplier ALTER COLUMN supplier_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME library.supplier_supplier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 231 (class 1259 OID 24694)
-- Name: write_off_act; Type: TABLE; Schema: library; Owner: postgres
--

CREATE TABLE library.write_off_act (
    write_off_act_id integer NOT NULL,
    act_date date NOT NULL,
    reason character varying(255) NOT NULL,
    disposal_direction character varying(255),
    CONSTRAINT chk_write_off_act_date CHECK ((act_date <= CURRENT_DATE)),
    CONSTRAINT chk_write_off_reason CHECK (((reason)::text = ANY ((ARRAY['physical loss'::character varying, 'worn out'::character varying, 'defective'::character varying, 'outdated'::character varying, 'non-core'::character varying, 'other'::character varying])::text[])))
);


ALTER TABLE library.write_off_act OWNER TO postgres;

--
-- TOC entry 5020 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE write_off_act; Type: COMMENT; Schema: library; Owner: postgres
--

COMMENT ON TABLE library.write_off_act IS 'Stores acts of writing off library fund objects.';


--
-- TOC entry 230 (class 1259 OID 24693)
-- Name: write_off_act_write_off_act_id_seq; Type: SEQUENCE; Schema: library; Owner: postgres
--

ALTER TABLE library.write_off_act ALTER COLUMN write_off_act_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME library.write_off_act_write_off_act_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 233 (class 1259 OID 24704)
-- Name: written_off_item; Type: TABLE; Schema: library; Owner: postgres
--

CREATE TABLE library.written_off_item (
    written_off_item_id integer NOT NULL,
    write_off_act_id integer NOT NULL,
    inventory_number character varying(20) NOT NULL,
    revaluation_coefficient numeric(5,2) NOT NULL,
    revalued_price numeric(10,2) NOT NULL,
    CONSTRAINT chk_written_off_revaluation_coefficient CHECK ((revaluation_coefficient > (0)::numeric)),
    CONSTRAINT chk_written_off_revalued_price CHECK ((revalued_price >= (0)::numeric))
);


ALTER TABLE library.written_off_item OWNER TO postgres;

--
-- TOC entry 5021 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE written_off_item; Type: COMMENT; Schema: library; Owner: postgres
--

COMMENT ON TABLE library.written_off_item IS 'Stores the list of book copies included in write-off acts.';


--
-- TOC entry 232 (class 1259 OID 24703)
-- Name: written_off_item_written_off_item_id_seq; Type: SEQUENCE; Schema: library; Owner: postgres
--

ALTER TABLE library.written_off_item ALTER COLUMN written_off_item_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME library.written_off_item_written_off_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 4997 (class 0 OID 24636)
-- Dependencies: 226
-- Data for Name: book_copy; Type: TABLE DATA; Schema: library; Owner: postgres
--

INSERT INTO library.book_copy VALUES ('INV0001', 1, 1, 1, 1200.00, '2025-01-11', NULL, 'available');
INSERT INTO library.book_copy VALUES ('INV0002', 1, 2, 1, 1200.00, '2025-01-11', NULL, 'issued');
INSERT INTO library.book_copy VALUES ('INV0003', 2, 3, 2, 1500.00, '2025-01-16', NULL, 'issued');
INSERT INTO library.book_copy VALUES ('INV0004', 2, 4, 2, 1500.00, '2025-01-16', NULL, 'available');
INSERT INTO library.book_copy VALUES ('INV0005', 3, 5, 3, 900.00, '2025-02-02', NULL, 'issued');
INSERT INTO library.book_copy VALUES ('INV0006', 4, 6, 3, 1100.00, '2025-02-02', NULL, 'available');
INSERT INTO library.book_copy VALUES ('INV0007', 5, 1, 4, 700.00, '2025-02-11', '2025-05-20', 'written off');
INSERT INTO library.book_copy VALUES ('INV0008', 6, 2, 2, 1700.00, '2025-03-05', NULL, 'available');


--
-- TOC entry 4992 (class 0 OID 24601)
-- Dependencies: 221
-- Data for Name: employee; Type: TABLE DATA; Schema: library; Owner: postgres
--

INSERT INTO library.employee OVERRIDING SYSTEM VALUE VALUES (1, 'Ivanova Anna Petrovna', 'librarian', 1.00);
INSERT INTO library.employee OVERRIDING SYSTEM VALUE VALUES (2, 'Petrov Sergey Ivanovich', 'fund manager', 1.00);
INSERT INTO library.employee OVERRIDING SYSTEM VALUE VALUES (3, 'Sidorova Marina Olegovna', 'administrator', 0.50);
INSERT INTO library.employee OVERRIDING SYSTEM VALUE VALUES (4, 'Kuznetsov Pavel Andreevich', 'accountant', 1.00);


--
-- TOC entry 5000 (class 0 OID 24673)
-- Dependencies: 229
-- Data for Name: loan; Type: TABLE DATA; Schema: library; Owner: postgres
--

INSERT INTO library.loan OVERRIDING SYSTEM VALUE VALUES (1, 'LC0001', 'INV0002', '2025-05-10', '2025-05-20', NULL, 150.00);
INSERT INTO library.loan OVERRIDING SYSTEM VALUE VALUES (2, 'LC0001', 'INV0003', '2025-05-18', '2025-05-28', NULL, 0.00);
INSERT INTO library.loan OVERRIDING SYSTEM VALUE VALUES (3, 'LC0002', 'INV0005', '2025-05-15', '2025-05-25', NULL, 50.00);
INSERT INTO library.loan OVERRIDING SYSTEM VALUE VALUES (4, 'LC0003', 'INV0001', '2025-04-01', '2025-04-10', '2025-04-08', 0.00);
INSERT INTO library.loan OVERRIDING SYSTEM VALUE VALUES (5, 'LC0004', 'INV0006', '2025-04-05', '2025-04-15', '2025-04-20', 100.00);


--
-- TOC entry 4988 (class 0 OID 24579)
-- Dependencies: 217
-- Data for Name: publication; Type: TABLE DATA; Schema: library; Owner: postgres
--

INSERT INTO library.publication OVERRIDING SYSTEM VALUE VALUES (1, 'Database Systems', 1, 2018, 'Petrov P. I.', 'textbook', 'Science Publishing House', 'Computer Science', 'Moscow', 'BBK 32.973');
INSERT INTO library.publication OVERRIDING SYSTEM VALUE VALUES (2, 'Programming in C#', NULL, 2021, 'Sidorov A. V.', 'manual', 'CodePress', 'Programming', 'Saint Petersburg', 'BBK 32.973');
INSERT INTO library.publication OVERRIDING SYSTEM VALUE VALUES (3, 'English Literature Anthology', 2, 2005, 'Brown J.', 'collection', 'World Books', 'Literature', 'London', 'BBK 84');
INSERT INTO library.publication OVERRIDING SYSTEM VALUE VALUES (4, 'Library Fund Accounting', NULL, 2019, 'Ivanova M. S.', 'monograph', 'BookTrade LLC', 'Library Science', 'Moscow', 'BBK 78.36');
INSERT INTO library.publication OVERRIDING SYSTEM VALUE VALUES (5, 'History Reference Book', NULL, 1999, 'Smirnov K. A.', 'reference book', 'Education Press', 'History', 'Kazan', 'BBK 63.3');
INSERT INTO library.publication OVERRIDING SYSTEM VALUE VALUES (6, 'Algorithms and Data Structures', NULL, 2020, 'Kormen T.', 'textbook', 'TechBooks', 'Computer Science', 'Moscow', 'BBK 32.973');


--
-- TOC entry 4998 (class 0 OID 24660)
-- Dependencies: 227
-- Data for Name: reader; Type: TABLE DATA; Schema: library; Owner: postgres
--

INSERT INTO library.reader VALUES ('LC0001', 'Smirnova Elena Viktorovna', '4001 123456', 'Saint Petersburg, Nevsky pr. 10', '+79001234567', 'smirnova@example.com', 'higher');
INSERT INTO library.reader VALUES ('LC0002', 'Volkov Dmitry Sergeevich', '4002 234567', 'Saint Petersburg, Rubinstein st. 5', '+79002345678', 'volkov@example.com', 'secondary');
INSERT INTO library.reader VALUES ('LC0003', 'Orlova Maria Pavlovna', '4003 345678', 'Saint Petersburg, Liteyny pr. 20', '+79003456789', 'orlova@example.com', 'higher');
INSERT INTO library.reader VALUES ('LC0004', 'Fedorov Ilya Romanovich', '4004 456789', 'Saint Petersburg, Sadovaya st. 15', '+79004567890', 'fedorov@example.com', 'student');


--
-- TOC entry 4996 (class 0 OID 24617)
-- Dependencies: 225
-- Data for Name: receipt_document; Type: TABLE DATA; Schema: library; Owner: postgres
--

INSERT INTO library.receipt_document OVERRIDING SYSTEM VALUE VALUES (1, 'INV-2025-001', 'invoice', '2025-01-10', 1, 1);
INSERT INTO library.receipt_document OVERRIDING SYSTEM VALUE VALUES (2, 'INV-2025-002', 'invoice', '2025-01-15', 2, 2);
INSERT INTO library.receipt_document OVERRIDING SYSTEM VALUE VALUES (3, 'ACT-2025-001', 'acceptance act', '2025-02-01', 3, 1);
INSERT INTO library.receipt_document OVERRIDING SYSTEM VALUE VALUES (4, 'LRA-2025-001', 'lost replacement act', '2025-02-10', 4, 2);


--
-- TOC entry 4990 (class 0 OID 24590)
-- Dependencies: 219
-- Data for Name: storage_place; Type: TABLE DATA; Schema: library; Owner: postgres
--

INSERT INTO library.storage_place OVERRIDING SYSTEM VALUE VALUES (1, 101, 1, 1);
INSERT INTO library.storage_place OVERRIDING SYSTEM VALUE VALUES (2, 101, 1, 2);
INSERT INTO library.storage_place OVERRIDING SYSTEM VALUE VALUES (3, 101, 2, 1);
INSERT INTO library.storage_place OVERRIDING SYSTEM VALUE VALUES (4, 102, 1, 1);
INSERT INTO library.storage_place OVERRIDING SYSTEM VALUE VALUES (5, 102, 2, 3);
INSERT INTO library.storage_place OVERRIDING SYSTEM VALUE VALUES (6, 201, 1, 1);


--
-- TOC entry 4994 (class 0 OID 24609)
-- Dependencies: 223
-- Data for Name: supplier; Type: TABLE DATA; Schema: library; Owner: postgres
--

INSERT INTO library.supplier OVERRIDING SYSTEM VALUE VALUES (1, 'BookTrade LLC');
INSERT INTO library.supplier OVERRIDING SYSTEM VALUE VALUES (2, 'Science Publishing House');
INSERT INTO library.supplier OVERRIDING SYSTEM VALUE VALUES (3, 'City Library Fund');
INSERT INTO library.supplier OVERRIDING SYSTEM VALUE VALUES (4, 'Reader Donation');


--
-- TOC entry 5002 (class 0 OID 24694)
-- Dependencies: 231
-- Data for Name: write_off_act; Type: TABLE DATA; Schema: library; Owner: postgres
--

INSERT INTO library.write_off_act OVERRIDING SYSTEM VALUE VALUES (1, '2025-05-20', 'worn out', 'Recycling');
INSERT INTO library.write_off_act OVERRIDING SYSTEM VALUE VALUES (2, '2025-05-25', 'outdated', 'Archive');


--
-- TOC entry 5004 (class 0 OID 24704)
-- Dependencies: 233
-- Data for Name: written_off_item; Type: TABLE DATA; Schema: library; Owner: postgres
--

INSERT INTO library.written_off_item OVERRIDING SYSTEM VALUE VALUES (1, 1, 'INV0007', 0.50, 350.00);


--
-- TOC entry 5022 (class 0 OID 0)
-- Dependencies: 220
-- Name: employee_employee_id_seq; Type: SEQUENCE SET; Schema: library; Owner: postgres
--

SELECT pg_catalog.setval('library.employee_employee_id_seq', 4, true);


--
-- TOC entry 5023 (class 0 OID 0)
-- Dependencies: 228
-- Name: loan_loan_id_seq; Type: SEQUENCE SET; Schema: library; Owner: postgres
--

SELECT pg_catalog.setval('library.loan_loan_id_seq', 5, true);


--
-- TOC entry 5024 (class 0 OID 0)
-- Dependencies: 216
-- Name: publication_publication_id_seq; Type: SEQUENCE SET; Schema: library; Owner: postgres
--

SELECT pg_catalog.setval('library.publication_publication_id_seq', 6, true);


--
-- TOC entry 5025 (class 0 OID 0)
-- Dependencies: 224
-- Name: receipt_document_receipt_document_id_seq; Type: SEQUENCE SET; Schema: library; Owner: postgres
--

SELECT pg_catalog.setval('library.receipt_document_receipt_document_id_seq', 4, true);


--
-- TOC entry 5026 (class 0 OID 0)
-- Dependencies: 218
-- Name: storage_place_storage_place_id_seq; Type: SEQUENCE SET; Schema: library; Owner: postgres
--

SELECT pg_catalog.setval('library.storage_place_storage_place_id_seq', 6, true);


--
-- TOC entry 5027 (class 0 OID 0)
-- Dependencies: 222
-- Name: supplier_supplier_id_seq; Type: SEQUENCE SET; Schema: library; Owner: postgres
--

SELECT pg_catalog.setval('library.supplier_supplier_id_seq', 4, true);


--
-- TOC entry 5028 (class 0 OID 0)
-- Dependencies: 230
-- Name: write_off_act_write_off_act_id_seq; Type: SEQUENCE SET; Schema: library; Owner: postgres
--

SELECT pg_catalog.setval('library.write_off_act_write_off_act_id_seq', 2, true);


--
-- TOC entry 5029 (class 0 OID 0)
-- Dependencies: 232
-- Name: written_off_item_written_off_item_id_seq; Type: SEQUENCE SET; Schema: library; Owner: postgres
--

SELECT pg_catalog.setval('library.written_off_item_written_off_item_id_seq', 1, true);


--
-- TOC entry 4820 (class 2606 OID 24644)
-- Name: book_copy book_copy_pkey; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.book_copy
    ADD CONSTRAINT book_copy_pkey PRIMARY KEY (inventory_number);


--
-- TOC entry 4810 (class 2606 OID 24607)
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (employee_id);


--
-- TOC entry 4828 (class 2606 OID 24682)
-- Name: loan loan_pkey; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.loan
    ADD CONSTRAINT loan_pkey PRIMARY KEY (loan_id);


--
-- TOC entry 4804 (class 2606 OID 24588)
-- Name: publication publication_pkey; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.publication
    ADD CONSTRAINT publication_pkey PRIMARY KEY (publication_id);


--
-- TOC entry 4822 (class 2606 OID 24667)
-- Name: reader reader_pkey; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.reader
    ADD CONSTRAINT reader_pkey PRIMARY KEY (library_card_number);


--
-- TOC entry 4816 (class 2606 OID 24623)
-- Name: receipt_document receipt_document_pkey; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.receipt_document
    ADD CONSTRAINT receipt_document_pkey PRIMARY KEY (receipt_document_id);


--
-- TOC entry 4806 (class 2606 OID 24597)
-- Name: storage_place storage_place_pkey; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.storage_place
    ADD CONSTRAINT storage_place_pkey PRIMARY KEY (storage_place_id);


--
-- TOC entry 4812 (class 2606 OID 24613)
-- Name: supplier supplier_pkey; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.supplier
    ADD CONSTRAINT supplier_pkey PRIMARY KEY (supplier_id);


--
-- TOC entry 4824 (class 2606 OID 24671)
-- Name: reader uq_reader_email; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.reader
    ADD CONSTRAINT uq_reader_email UNIQUE (email);


--
-- TOC entry 4826 (class 2606 OID 24669)
-- Name: reader uq_reader_passport_data; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.reader
    ADD CONSTRAINT uq_reader_passport_data UNIQUE (passport_data);


--
-- TOC entry 4818 (class 2606 OID 24625)
-- Name: receipt_document uq_receipt_document_number; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.receipt_document
    ADD CONSTRAINT uq_receipt_document_number UNIQUE (document_number);


--
-- TOC entry 4808 (class 2606 OID 24599)
-- Name: storage_place uq_storage_place; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.storage_place
    ADD CONSTRAINT uq_storage_place UNIQUE (room_number, shelf_unit_number, shelf_number);


--
-- TOC entry 4814 (class 2606 OID 24615)
-- Name: supplier uq_supplier_name; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.supplier
    ADD CONSTRAINT uq_supplier_name UNIQUE (supplier_name);


--
-- TOC entry 4832 (class 2606 OID 24712)
-- Name: written_off_item uq_written_off_item; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.written_off_item
    ADD CONSTRAINT uq_written_off_item UNIQUE (write_off_act_id, inventory_number);


--
-- TOC entry 4830 (class 2606 OID 24702)
-- Name: write_off_act write_off_act_pkey; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.write_off_act
    ADD CONSTRAINT write_off_act_pkey PRIMARY KEY (write_off_act_id);


--
-- TOC entry 4834 (class 2606 OID 24710)
-- Name: written_off_item written_off_item_pkey; Type: CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.written_off_item
    ADD CONSTRAINT written_off_item_pkey PRIMARY KEY (written_off_item_id);


--
-- TOC entry 4837 (class 2606 OID 24645)
-- Name: book_copy fk_book_copy_publication; Type: FK CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.book_copy
    ADD CONSTRAINT fk_book_copy_publication FOREIGN KEY (publication_id) REFERENCES library.publication(publication_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4838 (class 2606 OID 24655)
-- Name: book_copy fk_book_copy_receipt_document; Type: FK CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.book_copy
    ADD CONSTRAINT fk_book_copy_receipt_document FOREIGN KEY (receipt_document_id) REFERENCES library.receipt_document(receipt_document_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4839 (class 2606 OID 24650)
-- Name: book_copy fk_book_copy_storage_place; Type: FK CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.book_copy
    ADD CONSTRAINT fk_book_copy_storage_place FOREIGN KEY (storage_place_id) REFERENCES library.storage_place(storage_place_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4840 (class 2606 OID 24688)
-- Name: loan fk_loan_book_copy; Type: FK CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.loan
    ADD CONSTRAINT fk_loan_book_copy FOREIGN KEY (inventory_number) REFERENCES library.book_copy(inventory_number) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4841 (class 2606 OID 24683)
-- Name: loan fk_loan_reader; Type: FK CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.loan
    ADD CONSTRAINT fk_loan_reader FOREIGN KEY (library_card_number) REFERENCES library.reader(library_card_number) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4835 (class 2606 OID 24631)
-- Name: receipt_document fk_receipt_document_employee; Type: FK CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.receipt_document
    ADD CONSTRAINT fk_receipt_document_employee FOREIGN KEY (employee_id) REFERENCES library.employee(employee_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4836 (class 2606 OID 24626)
-- Name: receipt_document fk_receipt_document_supplier; Type: FK CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.receipt_document
    ADD CONSTRAINT fk_receipt_document_supplier FOREIGN KEY (supplier_id) REFERENCES library.supplier(supplier_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4842 (class 2606 OID 24713)
-- Name: written_off_item fk_written_off_item_act; Type: FK CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.written_off_item
    ADD CONSTRAINT fk_written_off_item_act FOREIGN KEY (write_off_act_id) REFERENCES library.write_off_act(write_off_act_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4843 (class 2606 OID 24718)
-- Name: written_off_item fk_written_off_item_book_copy; Type: FK CONSTRAINT; Schema: library; Owner: postgres
--

ALTER TABLE ONLY library.written_off_item
    ADD CONSTRAINT fk_written_off_item_book_copy FOREIGN KEY (inventory_number) REFERENCES library.book_copy(inventory_number) ON UPDATE CASCADE ON DELETE RESTRICT;


-- Completed on 2026-06-02 22:43:18

--
-- PostgreSQL database dump complete
--

\unrestrict wP1pCEAH3Yasof2giJ1mTee03iyNAy6Jpo1bmJ2VeSgmJzG0r4OxYmzDZDr6pB7


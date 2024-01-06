# Проектная работа по модулю «SQL и получение данных»

## 1.	В работе использовался локальный тип подключения.

 
## 2.	Скриншот ER-диаграммы из DBeaver`a.

 
## 3.	Краткое описание БД (таблицы и представления):

  
### 3.1	Таблицы:

- Aircrafts (Самолеты) –  код воздушного судна, модель, максимальная дальность полета в километрах. 
- Airports (Аэропорты) – код аэропорта, название аэропорта, город, координаты, часовой пояс.
- Boarding_passes (Посадочные талоны) – номер билета, id рейса, номер посадочного,  номер места.
- Booking (Бронирования) – номер бронирования, дата бронирования, полная сумма бронирования.
- Flights (Рейсы) – id рейса, номер рейса, время вылета и прилета по расписанию, аэропорты отправления и прибытия, статус рейса, код, фактическое время вылета и прилета.
- Seats (Места) – код, номер места, класс обслуживания.
- Tickets_flights (Перелеты) – номер билета, id рейса, класс обслуживания, стоимость перелета.
- Tickets (Билеты) – номер билета, номер бронирования, id пассажира, ФИ пассажира, контактные данные пассажира.

### 3.2	Представления

- Flights_v (Рейсы) – идентификатор рейса, номер рейса, время вылета по расписанию + местное время в пункте отправления, время прилёта по расписанию +  местное время в пункте прибытия, планируемая продолжительность полета, код аэропорта отправления, название аэропорта отправления, город отправления, код аэропорта прибытия, название аэропорта прибытия, город прибытия, статус рейса, код самолета, фактическое время вылета + местное время в пункте отправления, фактическое время прилёта + местное время в пункте прибытия, фактическая продолжительность полета.
- Routes_v (Маршруты) –  номер рейса, код аэропорта отправления, название аэропорта отправления, город отправления, город отправления, название аэропорта прибытия, название аэропорта прибытия, город прибытия, код самолета, продолжительность полета, дни недели, когда выполняются рейсы.

## 4.	Развернутый анализ БД - описание таблиц, логики, связей и бизнес области:

### 4.1	Aircrafts (Самолеты):

- Каждая модель воздушного судна идентифицируется своим трехзначным кодом (aircraft_code). Указывается также название модели (model) и максимальная дальность полета в километрах (range).
- Индексы: PRIMARY KEY, btree (aircraft_code)
- Ограничения-проверки: CHECK (range > 0)
- Ссылки извне:  TABLE "flights" FOREIGN KEY (aircraft_code)  REFERENCES aircrafts(aircraft_code) TABLE "seats" FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE

### 4.2	Airports (Аэропорты): 

- Аэропорт идентифицируется трехбуквенным кодом (airport_code) и имеет свое имя (airport_name). Для города не предусмотрено отдельной сущности, но название (city) указывается и может служить для того, чтобы определить аэропорты одного города. Также указывается широта (longitude), долгота (latitude) и часовой пояс (timezone).
- Индексы: PRIMARY KEY, btree (airport_code) 
- Ссылки извне: TABLE "flights" FOREIGN KEY (arrival_airport) REFERENCES airports(airport_code) TABLE "flights" FOREIGN KEY (departure_airport) REFERENCES airports(airport_code)

### 4.3	Boarding_passes (Посадочные талоны): 

- При регистрации на рейс, которая возможна за сутки до плановой даты отправления, пассажиру выдается посадочный талон. Он идентифицируется также, как и перелет — номером билета и номером рейса. Посадочным талонам присваиваются последовательные номера (boarding_no) в порядке регистрации пассажиров на рейс (этот номер будет уникальным только в пределах данного рейса). В посадочном талоне указывается номер места (seat_no).
- Индексы: PRIMARY KEY, btree (ticket_no, flight_id) UNIQUE CONSTRAINT, btree (flight_id, boarding_no) UNIQUE CONSTRAINT, btree (flight_id, seat_no) 
- Ограничения внешнего ключа: FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)

### 4.4	Booking (Бронирования) :

- Пассажир заранее (book_date, максимум за месяц до рейса) бронирует билет себе и, возможно, нескольким другим пассажирам. Бронирование идентифицируется номером (book_ref, шестизначная комбинация букв и цифр). Поле total_amount хранит общую стоимость включенных в бронирование перелетов всех пассажиров.
- Индексы: PRIMARY KEY, btree (book_ref) 
- Ссылки извне: TABLE "tickets" FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)

### 4.5	Flights (Рейсы):

- Естественный ключ таблицы рейсов состоит из двух полей — номера рейса (flight_no) и даты отправления (scheduled_departure). Чтобы сделать внешние ключи на эту таблицу компактнее, в качестве первичного используется суррогатный ключ (flight_id). Рейс всегда соединяет две точки — аэропорты вылета (departure_airport) и прибытия (arrival_airport). Такое понятие, как «рейс с пересадками» отсутствует: если из одного аэропорта до другого нет прямого рейса, в билет просто включаются несколько необходимых рейсов. У каждого рейса есть запланированные дата и время вылета (scheduled_departure) и прибытия (scheduled_arrival). Реальные время вылета (actual_departure) и прибытия (actual_arrival) могут отличаться: обычно не сильно, но иногда и на несколько часов, если рейс задержан.
- Индексы: PRIMARY KEY, btree (flight_id) UNIQUE CONSTRAINT, btree (flight_no, scheduled_departure) 
- Ограничения-проверки: CHECK (scheduled_arrival > scheduled_departure) CHECK ((actual_arrival IS NULL) OR ((actual_departure IS NOT NULL AND actual_arrival IS NOT NULL) AND (actual_arrival > actual_departure))) CHECK (status IN ('On Time', 'Delayed', 'Departed', 'Arrived', 'Scheduled', 'Cancelled')) 
- Ограничения внешнего ключа: FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) FOREIGN KEY (arrival_airport) REFERENCES airports(airport_code) FOREIGN KEY (departure_airport) REFERENCES airports(airport_code) 
- Ссылки извне: TABLE "ticket_flights" FOREIGN KEY (flight_id) REFERENCES flights(flight_id)

### 4.6	Seats (Места) :

- Места определяют схему салона каждой модели. Каждое место определяется своим номером (seat_no) и имеет закрепленный за ним класс обслуживания (fare_conditions) — Economy, Comfort или Business.
- Индексы: PRIMARY KEY, btree (aircraft_code, seat_no) 
- Ограничения-проверки: CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business')) 
- Ограничения внешнего ключа: FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE

### 4.7	Tickets_flights (Перелеты) :

- Перелет соединяет билет с рейсом и идентифицируется их номерами. Для каждого перелета указываются его стоимость (amount) и класс обслуживания (fare_conditions).
- Индексы: PRIMARY KEY, btree (ticket_no, flight_id) 
- Ограничения-проверки: CHECK (amount >= 0) CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business')) 
- Ограничения внешнего ключа: FOREIGN KEY (flight_id) REFERENCES flights(flight_id) FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no) 
- Ссылки извне: TABLE "boarding_passes" FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)

### 4.8	Tickets (Билеты):

- Билет имеет уникальный номер (ticket_no), состоящий из 13 цифр. Билет содержит идентификатор пассажира (passenger_id) — номер документа, удостоверяющего личность, — его фамилию и имя (passenger_name) и контактную информацию (contact_date). Ни идентификатор пассажира, ни имя не являются постоянными (можно поменять паспорт, можно сменить фамилию), поэтому однозначно найти все билеты одного и того же пассажира невозможно.
- Индексы: PRIMARY KEY, btree (ticket_no) 
- Ограничения внешнего ключа: FOREIGN KEY (book_ref) REFERENCES bookings(book_ref) 
- Ссылки извне: TABLE "ticket_flights" FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no)

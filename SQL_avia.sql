--ЗАДАНИЕ №1
--В каких городах больше одного аэропорта?

--Решение
--1. Из таблицы airports выводим два столбца: city и airport_name
--2. С помощью оператора count посчитаем кол-во аэропортов
--3. Для того, чтобы исключить повторения городов, группируем данные по столбцу city
--4. С помощью оператора having выводим только те города, 
--в которых больше одного аэропорта   

select city as "Город",
       count(airport_name) as "Количество аэропортов"
from airports 
group by city 
having count(airport_name)>1

--ЗАДАНИЕ №2
--В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью 
--перелета?

--Решение
--1. Из таблицы airports a выведем названия аэропортов
--2. С помощью оператора join из таблицы flights f присоединим номера рейсов
--3. Для того, чтобы оставить рейсы, выполняемые самолетом с максимальной дальностью 
--перелета, с помощью оператора join из таблицы aircrafts a2 присоединим 
--данные о дальности перелетов
--4.Составим подзапрос. Из таблицы aircrafts a2 выведем максимальную дальность 
--перелета

select distinct (a.airport_name) as "Название аэропорта"
from airports a
join flights f on f.arrival_airport = a.airport_code 
join aircrafts a2 on a2.aircraft_code = f.aircraft_code 
where a2.range =
	(select max(a2.range) 
from aircrafts a2)


--ЗАДАНИЕ №3
--Вывести 10 рейсов с максимальным временем задержки вылета

--Решение
--1. Из таблицы flights_v веводим номера рейсов, а также разницу
--между фактическим временем вылета и временем вылета по рассписанию
--2. Убираем нулевые значения
--3. Сортируем по убыванию
--4. Оставляем 10 значений

select flight_no as "Номер рейса",
       (actual_departure-scheduled_departure) as "Время задержки вылета"
from flights
where (actual_departure-scheduled_departure) is not null 
order by "Время задержки вылета" desc 
limit 10 

--ЗАДАНИЕ №4
--Были ли брони, по которым не были получены посадочные талоны?

--Решение
--1. Воводим номера бронирования из таблицы tickets t
--2. Используем left join, так как нам необходимо вывести 
--все номера бронирования и соответствующие им посадочные талоны
--3. Для того, чтобы оставить только те брони, по которым 
--не были получены посадочные талоны, выберем нулевые значения

select t.book_ref as "Номер бронирования"
from tickets t
left join boarding_passes bp on bp.ticket_no = t.ticket_no
where bp.boarding_no is null

--ЗАДАНИЕ №5
--Найдите процентное соотношение перелетов по типам самолетов от общего количества.

--Решение:
--Выводим модель самолема
--Рассчитываем процентное соотношение перелетов путем деления количества перелетов,
--выполненных каждой моделью самолетов, на общее кол-во перелетов
--Для определения общего кол-ва используем подзапрос
--Для получения более точного результата приводим значение числителя в numeric и
--округляем значение до 2 знаков после запятой
--Так как работаем с двумя таблицами, используем join
--Группируем данные по моделям самолетов 
 
select
a.model as "Модель самолета", 
round(count(f.flight_id)*100::numeric/(select count(*) from flights f), 2)
from aircrafts a
join flights f on f.aircraft_code = a.aircraft_code 
group by a.model

--ЗАДАНИЕ №6
--Были ли города, в которые можно  добраться бизнес - классом дешевле, 
--чем эконом-классом в рамках перелета?

--Решение
--1. Выведем города, классы обслуживания, а также стоимость перелетов
--2. Вооспользуемся функцией cte для того, чтобы воспользоваться этими
--данными в дальнейшем
--3. Выведем максимальную стоимость эконом класса и минимальную стоимость бизнес класса
--4. С помощью оператора HAVING оставляем города, в которые можно  добраться
-- бизнес - классом дешевле, чем эконом-классом
 
with cte_money as (
	select f.flight_id, 
	       a.city as "Город",
	       tf.fare_conditions, 
               tf.amount
	from ticket_flights tf   
	join flights f on f.flight_id = tf.flight_id 
	join airports a on a.airport_code = f.arrival_airport 
	order by a.city, tf.fare_conditions 
                  )
select flight_id,
       "Город",
       max(CASE WHEN fare_conditions = 'Economy' THEN amount ELSE NULL END) as "Макс эконом",
       min(CASE WHEN fare_conditions = 'Business' THEN amount ELSE NULL END) as "Мин бизнес" 
from cte_money
group by flight_id, "Город"
HAVING max(CASE WHEN fare_conditions = 'Economy' THEN amount ELSE NULL END) > min(CASE WHEN fare_conditions = 'Business' THEN amount ELSE NULL END)
order by flight_id asc 

 --ЗАДАНИЕ №7
--Между какими городами нет прямых рейсов?

--Решение
--1. Формируем через декартово произведение связи город-город, используя 
--таблицу airports 
--2. Используем функцию distinct, так как присутствуют города, 
--в которых больше одного аэропорта
--3. Используем where, так как один город не может быть одновременно 
--городом отправления и городом прибытия
--4. Из представления flights_v выбираем города отправления и прибытия, 
--так как опираясь на имеющиеся данные это идеальное решение
--5. Требуется создать представления, поэтому используем команду create view.
--Таким образом, у нас создано представление view_city, обновив которое мы 
--сможем получить актуальные данные в любой момент времени

create view view_city as
select a.city as "Город 1",
       a2.city as "Город 2"
from airports a, airports a2 
where a.city != a2.city
except 
select distinct departure_city,
   	        arrival_city 
from flights_v 


# Порівняння explain analyze
## Тестовий запит :
```sql
explain analyze
select
    p.first_name,
    p.last_name,
    f.flight_number,
    b.booked_at,
    b.price
from bookings b
join passengers p on b.passenger_id = p.passenger_id
join flights f on b.flight_id = f.flight_id
where b.status = 'confirmed'
order by b.booked_at desc
limit 100;
```

- До створення індексів : послідовне сканування

План виконання :
```txt
Limit  (cost=601.31..601.56 rows=100 width=35) (actual time=11.144..11.160 rows=100 loops=1)
  ->  Sort  (cost=601.31..609.63 rows=3328 width=35) (actual time=11.142..11.150 rows=100 loops=1)
        Sort Key: b.booked_at DESC
        Sort Method: top-N heapsort  Memory: 32kB
        ->  Nested Loop  (cost=0.59..474.12 rows=3328 width=35) (actual time=0.048..9.275 rows=3328 loops=1)
              ->  Nested Loop  (cost=0.30..352.52 rows=3328 width=32) (actual time=0.038..6.341 rows=3328 loops=1)
                    ->  Seq Scan on bookings b  (cost=0.00..219.00 rows=3328 width=22) (actual time=0.017..3.231 rows=3328 loops=1)
                          Filter: ((status)::text = 'confirmed'::text)
                          Rows Removed by Filter: 6672
                    ->  Memoize  (cost=0.30..0.51 rows=1 width=18) (actual time=0.000..0.000 rows=1 loops=3328)
                          Cache Key: b.passenger_id
                          Cache Mode: logical
                          Hits: 3228  Misses: 100  Evictions: 0  Overflows: 0  Memory Usage: 12kB
                          ->  Index Scan using passengers_pkey on passengers p  (cost=0.29..0.50 rows=1 width=18) (actual time=0.003..0.003 rows=1 loops=100)
                                Index Cond: (passenger_id = b.passenger_id)
              ->  Memoize  (cost=0.29..0.39 rows=1 width=11) (actual time=0.000..0.000 rows=1 loops=3328)
                    Cache Key: b.flight_id
                    Cache Mode: logical
                    Hits: 3228  Misses: 100  Evictions: 0  Overflows: 0  Memory Usage: 11kB
                    ->  Index Scan using flights_pkey on flights f  (cost=0.28..0.38 rows=1 width=11) (actual time=0.003..0.003 rows=1 loops=100)
                          Index Cond: (flight_id = b.flight_id)
Planning Time: 0.563 ms
Execution Time: 11.223 ms
```
Аналіз : Виконується seq scan по таблиці bookings - перебирається кожен рядок, щоб знайти потрібні
за фільтром. Час виконання 11.223 ms.


- Після створення індексу : сканування за індексом
Доданий індекс :
```sql
create index idx_bookings_status_booked_at
on bookings(status, booked_at desc);
```
План виконання :
```sql
Limit  (cost=0.87..21.41 rows=100 width=35) (actual time=0.039..0.400 rows=100 loops=1)
  ->  Nested Loop  (cost=0.87..684.45 rows=3328 width=35) (actual time=0.037..0.391 rows=100 loops=1)
        ->  Nested Loop  (cost=0.58..562.86 rows=3328 width=32) (actual time=0.032..0.233 rows=100 loops=1)
              ->  Index Scan using idx_bookings_status_booked_at on bookings b  (cost=0.29..429.34 rows=3328 width=22) (actual time=0.020..0.052 rows=100 loops=1)
                    Index Cond: ((status)::text = 'confirmed'::text)
              ->  Memoize  (cost=0.30..0.51 rows=1 width=18) (actual time=0.001..0.001 rows=1 loops=100)
                    Cache Key: b.passenger_id
                    Cache Mode: logical
                    Hits: 34  Misses: 66  Evictions: 0  Overflows: 0  Memory Usage: 8kB
                    ->  Index Scan using passengers_pkey on passengers p  (cost=0.29..0.50 rows=1 width=18) (actual time=0.001..0.001 rows=1 loops=66)
                          Index Cond: (passenger_id = b.passenger_id)
        ->  Memoize  (cost=0.29..0.39 rows=1 width=11) (actual time=0.001..0.001 rows=1 loops=100)
              Cache Key: b.flight_id
              Cache Mode: logical
              Hits: 34  Misses: 66  Evictions: 0  Overflows: 0  Memory Usage: 8kB
              ->  Index Scan using flights_pkey on flights f  (cost=0.28..0.38 rows=1 width=11) (actual time=0.001..0.001 rows=1 loops=66)
                    Index Cond: (flight_id = b.flight_id)
Planning Time: 0.356 ms
Execution Time: 0.436 ms
```
Аналіз : Завдяки індексу, одразу виконується index scan і потрібні рядки замість усієї таблиці.
Повністю прибирається етап сортування, бо рядки вже впорядковані всередині індексу. Час виконання 0.436 ms.
Загалом, час у виконанні зменшився у ~26 разів.

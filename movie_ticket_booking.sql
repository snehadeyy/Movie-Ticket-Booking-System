-- movie ticket booking system (MySQL 8.0.16 or above)

create database if not exists movie_booking;
use movie_booking;

-- tables (basic structure first, constraints are added later in the steps)

create table movies (
    movie_id int primary key auto_increment,
    movie_name varchar(100),
    genre varchar(30),
    language varchar(20),
    duration int,
    release_date date,
    rating decimal(3,1)
);

create table theatres (
    theatre_id int primary key auto_increment,
    theatre_name varchar(100),
    city varchar(50),
    address varchar(150)
);

create table shows (
    show_id int primary key auto_increment,
    movie_id int,
    theatre_id int,
    show_date date,
    show_time time,
    ticket_price decimal(8,2)
);

create table seats (
    seat_id int primary key auto_increment,
    seat_no varchar(5),
    seat_type varchar(20),
    theatre_id int
);

create table customers (
    customer_id int primary key auto_increment,
    full_name varchar(80),
    email varchar(100),
    phone varchar(15)
);

create table bookings (
    booking_id int primary key auto_increment,
    customer_id int,
    show_id int,
    booking_date date,
    booking_status varchar(15),
    total_amount decimal(10,2)
);

create table booking_seats (
    booking_seat_id int primary key auto_increment,
    booking_id int,
    seat_id int
);

-- sample data (some duplicates and nulls are kept on purpose for cleaning)

insert into movies values
(1, 'Leo', 'Action', 'Tamil', 164, '2023-10-19', 7.2),
(2, 'Jawan', 'Action', 'Hindi', 169, '2023-09-07', 7.0),
(3, 'Kantara', 'Drama', 'Kannada', 148, '2022-09-30', 8.2),
(4, 'Dunki', null, 'Hindi', 161, '2023-12-21', 6.8),
(5, 'Jawan', 'Action', 'Hindi', 169, '2023-09-07', 7.0);

insert into theatres values
(1, 'INOX South City', 'Kolkata', 'Prince Anwar Shah Road'),
(2, 'PVR Mani Square', 'Kolkata', 'EM Bypass'),
(3, 'Cinepolis Acropolis', 'Kolkata', 'Rajdanga');

insert into shows values
(1, 1, 1, '2026-11-28', '18:30:00', 250),
(2, 2, 1, '2026-11-28', '21:00:00', 300),
(3, 3, 2, '2026-11-29', '15:00:00', 200),
(4, 1, 2, '2026-11-30', '18:00:00', null);

insert into seats values
(1, 'A1', 'Regular', 1),
(2, 'A2', 'Regular', 1),
(3, 'A3', 'Regular', 1),
(4, 'B1', 'Premium', 1),
(5, 'B2', 'Premium', 1),
(6, 'B3', 'Premium', 1),
(7, 'C1', 'Regular', 2),
(8, 'C2', 'Recliner', 2);

insert into customers values
(1, 'Rahul Das', 'rahul@gmail.com', '9830012345'),
(2, 'Priya Sen', 'priya@gmail.com', null),
(3, 'Amit Roy', 'amit@gmail.com', '9831098765'),
(4, 'Rahul Das', 'rahul@gmail.com', '9830012345');

insert into bookings values
(1, 1, 1, '2026-11-24', 'Confirmed', 500),
(2, 2, 2, '2026-11-24', 'Confirmed', 300),
(3, 3, 3, '2026-11-25', 'Cancelled', 200);

insert into booking_seats values
(1, 1, 1),
(2, 1, 2),
(3, 2, 3),
(4, 3, 7);


-- 1. remove duplicate
-- keeping the row with the smaller id

set sql_safe_updates = 0;

delete m1 from movies m1
join movies m2
  on m1.movie_name = m2.movie_name
 and m1.release_date = m2.release_date
 and m1.movie_id > m2.movie_id;

delete c1 from customers c1
join customers c2
  on c1.email = c2.email
 and c1.customer_id > c2.customer_id;

-- email should not repeat again
alter table customers add constraint uq_customer_email unique (email);

-- same seat should not be added twice in the same booking
alter table booking_seats add constraint uq_booking_seat unique (booking_id, seat_id);


-- 2. check constraint

alter table movies
    add constraint chk_rating check (rating between 0 and 10),
    add constraint chk_duration check (duration > 0);

alter table shows
    add constraint chk_price check (ticket_price > 0);

alter table seats
    add constraint chk_seat_type check (seat_type in ('Regular', 'Premium', 'Recliner'));

alter table bookings
    add constraint chk_status check (booking_status in ('Confirmed', 'Cancelled', 'Pending')),
    add constraint chk_amount check (total_amount >= 0);


-- 3. foreign key constraint

alter table shows
    add constraint fk_shows_movie foreign key (movie_id) references movies(movie_id),
    add constraint fk_shows_theatre foreign key (theatre_id) references theatres(theatre_id);

alter table seats
    add constraint fk_seats_theatre foreign key (theatre_id) references theatres(theatre_id);

alter table bookings
    add constraint fk_bookings_customer foreign key (customer_id) references customers(customer_id),
    add constraint fk_bookings_show foreign key (show_id) references shows(show_id);

alter table booking_seats
    add constraint fk_bs_booking foreign key (booking_id) references bookings(booking_id) on delete cascade,
    add constraint fk_bs_seat foreign key (seat_id) references seats(seat_id);


-- 4. null value cleaning

-- find the nulls first
select * from movies where genre is null;

select * from customers where phone is null;

select * from shows where ticket_price is null;

update movies set genre = 'Unknown' where genre is null;

update customers set phone = 'Not Provided' where phone is null;

update shows set ticket_price = 150 where ticket_price is null;

-- now these columns can be made not null

alter table movies modify movie_name varchar(100) not null;

alter table movies modify genre varchar(30) not null;

alter table shows modify ticket_price decimal(8,2) not null;

alter table customers modify full_name varchar(80) not null;

alter table customers modify email varchar(100) not null;


-- 5. joining
-- full details of every booking

select b.booking_id,
       c.full_name,
       m.movie_name,
       t.theatre_name,
       s.show_date,
       s.show_time,
       se.seat_no,
       b.booking_status,
       b.total_amount
from bookings b
join customers c      on b.customer_id = c.customer_id
join shows s          on b.show_id = s.show_id
join movies m         on s.movie_id = m.movie_id
join theatres t       on s.theatre_id = t.theatre_id
join booking_seats bs on b.booking_id = bs.booking_id
join seats se         on bs.seat_id = se.seat_id
order by b.booking_id;

-- movies which have no show (left join)
select m.movie_name
from movies m
left join shows s on m.movie_id = s.movie_id
where s.show_id is null;


-- 6. subquery

-- customers whose booking amount is more than the average
select full_name
from customers
where customer_id in (
    select customer_id
    from bookings
    where total_amount > (select avg(total_amount) from bookings)
);


select c.full_name, b.total_amount
from customers c
join bookings b on c.customer_id = b.customer_id
where b.total_amount > (select avg(total_amount) from bookings);

select c.customer_id, c.full_name 
    from customers c inner join bookings b 
    where b.total_amount > (select avg(total_amount) from bookings);
    

select total_amount from bookings;

-- movies that are not running in any theatre
select movie_name
from movies
where movie_id not in (select movie_id from shows);

-- show with highest ticket price

select show_id, ticket_price
from shows
where ticket_price = (select max(ticket_price) from shows);


-- 7. transaction
-- priya books seats B1 and B2 for show 1

start transaction;

insert into bookings (customer_id, show_id, booking_date, booking_status, total_amount)
select 2, 1, curdate(), 'Confirmed', ticket_price * 2
from shows
where show_id = 1;

set @new_booking = last_insert_id();

insert into booking_seats (booking_id, seat_id)
values (@new_booking, 4), (@new_booking, 5);

commit;

-- if something goes wrong we can undo everything
start transaction;

update bookings set booking_status = 'Cancelled' where booking_id = 1;
delete from booking_seats where booking_id = 1;

rollback;   -- nothing is changed because of rollback

select * from bookings where booking_id = 1;


-- 8. trigger
-- stop the same seat from being booked twice for the same show

delimiter $$

create trigger trg_check_seat
before insert on booking_seats
for each row
begin
    declare v_show int;
    declare v_taken int;

    select show_id into v_show
    from bookings
    where booking_id = new.booking_id;

    select count(*) into v_taken
    from booking_seats bs
    join bookings b on bs.booking_id = b.booking_id
    where bs.seat_id = new.seat_id
      and b.show_id = v_show
      and b.booking_status = 'Confirmed';

    if v_taken > 0 then
        signal sqlstate '45000'
        set message_text = 'This seat is already booked for the show';
    end if;
end$$

delimiter ;

-- test: seat 4 is already booked for show 1 by the transaction above,
-- so this gives an error
-- insert into bookings (customer_id, show_id, booking_date, booking_status, total_amount)
-- values (3, 1, curdate(), 'Confirmed', 250);
-- insert into booking_seats (booking_id, seat_id) values (last_insert_id(), 4);


-- 9. view

create or replace view v_booking_details as
select b.booking_id,
       c.full_name,
       m.movie_name,
       t.theatre_name,
       s.show_date,
       s.show_time,
       b.booking_status,
       b.total_amount
from bookings b
join customers c on b.customer_id = c.customer_id
join shows s     on b.show_id = s.show_id
join movies m    on s.movie_id = m.movie_id
join theatres t  on s.theatre_id = t.theatre_id;


create or replace view v_movie_revenue as
select m.movie_name,
       count(b.booking_id) as total_bookings,
       sum(b.total_amount) as revenue
from movies m
join shows s     on m.movie_id = s.movie_id
join bookings b  on s.show_id = b.show_id
where b.booking_status = 'Confirmed'
group by m.movie_name;

select * from v_booking_details;
select * from v_movie_revenue;

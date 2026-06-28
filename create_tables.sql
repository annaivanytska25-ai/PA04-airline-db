create table passengers (
    passenger_id serial primary key,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    email varchar(100) unique not null,
    phone varchar(20),
    date_of_birth date not null,
    passport_number varchar(20) unique not null
);

create table passenger_details (
    detail_id serial primary key,
    passenger_id int unique not null references passengers(passenger_id) on delete cascade,
    nationality varchar(50),
    frequent_flyer_status varchar(20) default 'none',
    total_flights int default 0 check (total_flights >= 0)
);

create table aircraft (
    aircraft_id serial primary key,
    model varchar(50) not null,
    total_seats int not null check (total_seats > 0),
    registration_number varchar(10) unique not null,
    active boolean default true
);

create table airports (
    airport_id serial primary key,
    airport_name varchar(100) not null,
    city varchar(100) not null,
    country varchar(100) not null
);

create table flights (
    flight_id serial primary key,
    flight_number varchar(10) unique not null,
    aircraft_id int not null references aircraft(aircraft_id),
    departure_airport_id int not null references airports(airport_id),
    arrival_airport_id int not null references airports(airport_id),
    departure_time timestamp not null,
    arrival_time timestamp not null,
    status varchar(20) default 'scheduled'
);

create table seats (
    seat_id serial primary key,
    aircraft_id int not null references aircraft(aircraft_id) on delete cascade,
    seat_number varchar(10) not null,
    seat_class varchar(20) not null,
    unique (aircraft_id, seat_number)
);

create table crew_members (
    crew_id serial primary key,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    role varchar(50) not null,
    active boolean default true
);

create table bookings (
    booking_id serial primary key,
    passenger_id int not null references passengers(passenger_id),
    flight_id int not null references flights(flight_id),
    seat_id int not null references seats(seat_id),
    booked_at timestamp default current_timestamp,
    price numeric(10,2) not null check (price > 0),
    status varchar(20) default 'confirmed',
    unique (flight_id, seat_id)
);

create table flight_crew (
    flight_id int not null references flights(flight_id) on delete cascade,
    crew_id int not null references crew_members(crew_id) on delete cascade,
    primary key (flight_id, crew_id)
);
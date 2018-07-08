create extension if not exists "postgis";
create extension if not exists "uuid-ossp";

create role application_user;

create table if not exists users (
  id uuid default uuid_generate_v4() not null primary key,
  name text not null
);

create table if not exists items (
  id uuid default uuid_generate_v4() not null primary key,
  value text,
  created_at timestamp with time zone default now(),
  parent_id uuid references public.items(id),
  public boolean default false,
  permissions name[]
);

grant all
on schema public
to application_user;

grant all
on all tables in schema public
to application_user;

alter table items
enable row level security;

create policy item_owner
on items
as permissive
for all
to application_user
using (
  items.permissions @> array[current_setting('jwt.claims.role')::name]
)
with check (
  items.permissions @> array[current_setting('jwt.claims.role')::name]

);

create or replace function insert_item_permission()
  returns trigger
  as $$
begin
  new.permissions = array[current_setting('jwt.claims.role')::name];
  return new;
end
$$ language plpgsql;

create trigger item_permission
before insert
on items
for each row
execute procedure insert_item_permission();

create or replace function create_role()
  returns trigger
  as $$
begin
  execute 'create role ' || quote_ident( new.id::text ) || ' inherit';
  execute 'grant application_user to ' || quote_ident( new.id::text );
  return new;
end
$$ language plpgsql;

create trigger insert_user_trigger
after insert
on users
for each row
execute procedure create_role();

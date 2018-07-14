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
  public boolean default false,
  read uuid[],
  write uuid[]
);

create index read_permissions_index on items using gin(read);
create index write_permissions_index on items using gin(write);

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
  items.public
  or items.read && array[current_setting('jwt.claims.role')::uuid]
  or items.write && array[current_setting('jwt.claims.role')::uuid]
)
with check (
  items.public
  or items.write && array[current_setting('jwt.claims.role')::uuid]
);

create or replace function insert_item_permission()
  returns trigger
  as $$
begin
  new.write = array[current_setting('jwt.claims.role')::uuid];
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

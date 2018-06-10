create extension if not exists "postgis";
create extension if not exists "uuid-ossp";

create role application_user;

create table if not exists items (
  id uuid default uuid_generate_v4() not null primary key,
  value text,
  created_at timestamp with time zone default now()
);

create table if not exists user_items (
  item_id uuid references items(id),
  user_role text
);

create or replace view items_with_permissions as
	select
		items.*,
		jsonb_build_array(user_items.user_role) as roles,
		current_role,
		session_user,
		current_setting('jwt.claims.role') role_setting
	from items
	join user_items
    on user_items.item_id = items.id
    and user_items.user_role = current_setting('jwt.claims.role');

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
for all
to application_user
using (
  (
    select true as bool from (
      select item_id from user_items where user_role = current_setting('jwt.claims.role')
    ) as user_items where item_id = items.id
  ) = true
)
with check (true);

create or replace function insert_user_item()
  returns trigger
  as $$
begin
  insert into user_items (item_id, user_role) values (
    new.id,
    current_setting('jwt.claims.role')
  );
  return new;
end
$$ language plpgsql;

create trigger insert_user_item_trigger
after insert
on items
for each row
execute procedure insert_user_item();

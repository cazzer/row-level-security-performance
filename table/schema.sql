create extension if not exists "postgis";
create extension if not exists "uuid-ossp";

create role application_user;

create table if not exists users_and_groups (
  id uuid default uuid_generate_v4() not null primary key,
  name text not null
);

create table if not exists items (
  id uuid default uuid_generate_v4() not null primary key,
  value text,
  public boolean default false
);

create type permission_role as enum (
  'read',
  'write'
);

create table if not exists permissions (
  item_id uuid references items(id),
  user_or_group_id uuid references users_and_groups(id),
  role permission_role default 'read' not null
);

create index on permissions(item_id);
create index on permissions(user_or_group_id);

create unique index permissions_index ON permissions (item_id, user_or_group_id);

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
  items.public = true
  or exists(
    select item_id
    from permissions
    where (
      permissions.user_or_group_id =
        any(regexp_split_to_array(current_setting('jwt.claims.roles'), ',')::uuid[])
      and permissions.item_id = items.id
    )
  )
)
with check (exists(
  select item_id
  from permissions
  where (
    permissions.user_or_group_id =
      any(regexp_split_to_array(current_setting('jwt.claims.roles'), ',')::uuid[])
    and permissions.item_id = items.id
    and permissions.role = 'write'
  )
));

create policy new_item
on items
as permissive
for insert
to application_user
with check (true);

create policy permission_owner
on permissions
for all
to application_user
using (
  permissions.user_or_group_id =
      any(regexp_split_to_array(current_setting('jwt.claims.roles'), ',')::uuid[])
)
with check (
  permissions.user_or_group_id =
      any(regexp_split_to_array(current_setting('jwt.claims.roles'), ',')::uuid[])
  and permissions.role = 'write'
);

create or replace function insert_permission()
  returns trigger
  as $$
begin
  insert into permissions (item_id, user_or_group_id, role) values (
    new.id,
    (regexp_split_to_array(current_setting('jwt.claims.roles'), ',')::uuid[])[1],
    'write'
  );
  return new;
end
$$ language plpgsql;

create trigger insert_permission_trigger
after insert
on items
for each row
execute procedure insert_permission();

-- this is only neccessary if we plan to give SQL access to users
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
on users_and_groups
for each row
execute procedure create_role();

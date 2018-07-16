create or replace function insert_data(n integer)
returns integer
AS $$
DECLARE
  counter integer := 0;
  public boolean;
begin
  loop
  exit when counter = n;
    counter := counter + 1;
    if random() < .2 then
      public := true;
    else
      public := false;
    end if;
    insert into items (value, public) values ('test value ' || counter, public);
  end loop;
  return n;
end;
$$ language plpgsql;

create or replace function insert_users(n integer)
returns integer
as $$
declare
  counter integer := 0;
  user_id uuid;
begin
  loop
  exit when counter = n;
    counter := counter + 1;
    insert into users (name) values ('user ' || counter) returning id into user_id;
    execute 'set local jwt.claims.role = ''' || user_id || '''';
    perform insert_data(1000);
    update items
      set acl_read = array_append(acl_read, user_id)
      where random() > .99
      and not acl_read @> array[user_id];
  end loop;
  return n;
end;
$$ language plpgsql;

create or replace function user_item_stats()
  returns setof text
  as $$
declare
  user_id uuid;
  row record;
begin
  select id
    from users
    where random() > .95
    limit 1 into user_id;
  execute 'set local role = ''' || user_id || '''';
  execute 'set local jwt.claims.role = ''' || user_id || '''';
  return query
    explain analyze select count(*)
    from items;
  return;
end
$$ language plpgsql;

create view permission_stats as
  select
    min(array_length(acl_read, 1)),
    avg(array_length(acl_read, 1)),
    max(array_length(acl_read, 1)),
    sum(array_length(acl_read, 1)),
    (
      select count(*) from items
    ) as item_count,
    (
      select count(*) from users
    ) as user_count
  from items;

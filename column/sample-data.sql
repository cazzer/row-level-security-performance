create or replace function insert_data(n integer)
returns integer
AS $$
DECLARE
  counter INTEGER := 0;
BEGIN
  LOOP
  EXIT WHEN counter = n;
  counter := counter + 1;
  insert into items (value) values ('test value ' || counter);
  end loop;
  return n;
end;
$$ LANGUAGE plpgsql;

create or replace function insert_users(n integer)
returns integer
AS $$
DECLARE
  counter INTEGER := 0;
  user_id name;
BEGIN
  LOOP
  EXIT WHEN counter = n;
    counter := counter + 1;
    insert into users (name) values ('user ' || counter) returning id into user_id;
    execute 'set local jwt.claims.role = ''' || user_id || '''';
    perform insert_data(1000);
    update items
      set permissions = array_append(permissions, user_id)
      where random() > .99
      and not permissions @> array[user_id];
  end loop;
  return n;
end;
$$ LANGUAGE plpgsql;

select insert_users(100);

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
    min(array_length(permissions, 1)),
    avg(array_length(permissions, 1)),
    max(array_length(permissions, 1)),
    sum(array_length(permissions, 1)),
    (
      select count(*) from items
    ) as item_count,
    (
      select count(*) from users
    ) as user_count
  from items;

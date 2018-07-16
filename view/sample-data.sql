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
  user_id uuid;
BEGIN
  LOOP
  EXIT WHEN counter = n;
	  counter := counter + 1;
	  insert into users (name) values ('user ' || counter) returning id into user_id;
	  execute 'set local jwt.claims.role = ''' || user_id || '''';
	  perform insert_data(1000);
    execute 'insert into user_items (item_id, user_id)
      select
        items.id as item_id,
        ''' || user_id || '''
      from items
      left outer join user_items on items.id = item_id and user_id = ''' || user_id || '''
      where user_id is null
      and random() > .99';
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
    from items_view;
  return;
end
$$ language plpgsql;

create view permission_stats as
  select
    min(count),
    avg(count),
    max(count),
    sum(count),
    (
      select count(*) from items
    ) as item_count,
    (
      select count(*) from users
    ) as user_count
  from (
    select
      count(user_id)
    from user_items
    group by item_id
  ) permission_counts;

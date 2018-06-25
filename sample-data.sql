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

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

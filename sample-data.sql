create or replace function insert_data(n integer)
AS $$
DECLARE
  counter INTEGER := 0;
BEGIN
  LOOP
  EXIT WHEN counter = n;
  counter := counter + 1;
  insert into items (value) values ('test value ' || counter)
  end loop;
end;
$$ LANGUAGE plpgsql;

begin;

insert into users (id, name) values
('279d9644-f1ee-4e2c-967a-861f1ee1c2aa', 'bob'),
('166fc198-1664-49c0-8bbd-d3b47533f5ca', 'alice');

set local jwt.claims.role = '279d9644-f1ee-4e2c-967a-861f1ee1c2aa';
insert into items (id, value) values
('3a9261a6-e231-480c-adea-e3bdeda03269', 'test value for bob');
insert into items (value, parent_id) values
('test child value for bob', '3a9261a6-e231-480c-adea-e3bdeda03269'),
('another child value for bob', '3a9261a6-e231-480c-adea-e3bdeda03269');

set local jwt.claims.role = '166fc198-1664-49c0-8bbd-d3b47533f5ca';
insert into items (id, value) values
('4fac0156-0e51-4e70-9229-2c472e11d117', 'test value for alice');
insert into items (value, parent_id) values
('test child value for alice', '4fac0156-0e51-4e70-9229-2c472e11d117'),
('another child value for alice', '4fac0156-0e51-4e70-9229-2c472e11d117');

commit;

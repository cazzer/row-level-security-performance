create role alice inherit;
grant application_user to alice;

create role bob inherit;
grant application_user to bob;

begin;

set local jwt.claims.role = 'bob';
insert into items (value) values
('test value for bob');

set local jwt.claims.role = 'alice';
insert into items (value) values
('test value for alice');

commit;

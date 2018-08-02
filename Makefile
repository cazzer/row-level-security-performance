## CAUTION this will completely destroy your database!!
## Run migrations and salesforce-import to restore

seed-db:
	make run-schema && \
	make insert-sample-data

destroy-db:
	docker-compose down && \
	docker volume rm breakdown_pgdata && \
	rm -f pgdata && touch pgdata

run-db:
	docker-compose up &

run-schema:
	psql -d test -h localhost -W postgres -w -f $(schema)/schema.sql

insert-sample-data:
	psql -d test -h localhost -W postgres -w -f $(schema)/sample-data.sql

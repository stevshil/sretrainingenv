FROM mysql:8.0.24
EXPOSE 3306
ENV MYSQL_ROOT_PASSWORD=secret123
ADD  createTables.sql /docker-entrypoint-initdb.d

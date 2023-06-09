FROM python:3.12-rc-alpine
RUN mkdir /app; useradd -m cdapi; ln -s /app/env/.env /app/.env
COPY *.py requirements.txt /app
COPY .envdocker /app/env/.env
RUN pip install -r /app/requirements.txt
VOLUME /app/env
EXPOSE 8080
WORKDIR /app
USER cdapi
ENTRYPOINT [ "./cdapi.py" ]

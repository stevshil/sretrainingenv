FROM python:3.10-rc-slim-buster
RUN mkdir /app; ln -s /app/env/.env /app/.env
# RUN apk add build-base; apk add py3-greenlet; apk add libffi-dev
RUN apt-get -y update; apt-get -y install build-essential libssl-dev libffi-dev
COPY *.py requirements.txt /app
COPY .envdocker /app/env/.env
RUN pip install -r /app/requirements.txt
RUN chmod a+x /app/cdapi.py
VOLUME /app/env
EXPOSE 8080
WORKDIR /app
RUN useradd -m cdapi
USER cdapi
ENTRYPOINT [ "./cdapi.py" ]

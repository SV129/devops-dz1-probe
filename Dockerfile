FROM python:3.11-alpine

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -i https://mirrors.aliyun.com/pypi/simple/ -r requirements.txt
COPY . .

ARG VERSION=dev
RUN echo "$VERSION" > /app/VERSION

ENV APP_PORT=5008
ENV MARKER=netlab
ENV PYTHONDONTWRITEBYTECODE=1
EXPOSE 5008

CMD ["python", "app.py"]

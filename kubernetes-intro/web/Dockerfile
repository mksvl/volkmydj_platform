FROM python:slim
WORKDIR /app
COPY app/* /app
USER 1001:1001
EXPOSE 8000
CMD ["python3", "-m", "http.server"]

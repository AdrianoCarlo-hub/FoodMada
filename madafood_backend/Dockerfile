FROM dart:stable

WORKDIR /app

COPY pubspec.* ./

RUN dart pub get

COPY . .

RUN dart pub get

RUN dart_frog build

EXPOSE 8080

CMD ["dart_frog", "serve", "build", "--port", "8080", "--hostname", "0.0.0.0"]
FROM ruby:2.7-alpine

RUN apk update && \ 
    apk --no-cache add tzdata postgresql-dev postgresql-client ruby-bundler build-base ruby-dev libc-dev linux-headers 


WORKDIR /app
COPY ./ /app

RUN bundle install

EXPOSE 8080

CMD ["bundle", "exec", "ruby",  "app.rb"]


FROM ruby:2.3

RUN apt update && apt install -y mysql-client && apt-get clean
RUN gem install dm-mysql-adapter pry

CMD 'bash'

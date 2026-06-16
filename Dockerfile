# Development-oriented image. Production deployment is out of scope for this task,
# so we optimise for a fast, reproducible local setup rather than a slim prod build.
FROM ruby:4.0.5-slim

# build-essential — компиляция нативных расширений гемов (oj, panko, bootsnap)
# libpq-dev    — заголовки клиента PostgreSQL для гема pg
# libyaml-dev  — заголовки libyaml для гема psych (YAML)
# pkg-config   — поиск заголовков при сборке нативных расширений
# git          — часть гемов тянется из git-источников
RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends build-essential libpq-dev libyaml-dev pkg-config git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Ставим гемы отдельным слоем: правки кода приложения не инвалидируют кеш bundle
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENTRYPOINT ["bin/docker-entrypoint"]
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]

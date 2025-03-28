FROM ghcr.io/samvera/hyku/base:latest as hyku-knap-base

# This is specifically NOT $APP_PATH but the parent directory
COPY --chown=1001:101 . /app/samvera
COPY --chown=1001:101 bundler.d/ /app/.bundler.d/
ENV BUNDLE_LOCAL__HYKU_KNAPSACK=/app/samvera
ENV BUNDLE_DISABLE_LOCAL_BRANCH_CHECK=true
ENV BUNDLE_BUNDLER_INJECT__GEM_PATH=/app/samvera/bundler.d

RUN bundle install --jobs "$(nproc)"

USER root

# Install "best" training data for Tesseract
RUN echo "📚 Installing Tesseract Best (training data)!" && \
    wget https://github.com/tesseract-ocr/tessdata_best/raw/main/eng.traineddata -O /usr/share/tessdata/eng_best.traineddata && \
    git config --global --add safe.directory /app/samvera

ENV PATH="/app/samvera/bin:/app/samvera/hyrax-webapp/bin:/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

FROM hyku-knap-base as hyku-web
RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb DB_URL='postgresql://fake' bundle exec rake assets:precompile && yarn install

CMD ./bin/web

FROM hyku-web as hyku-worker
CMD ./bin/worker

FROM emscripten/emsdk:3.1.10
ENV PYTHONUNBUFFERED=1
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
          libgeos-dev ed \
          automake autoconf libtool \
          pkg-config wget xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /code

# From /code, build.sh resolves ../libsndfile-emscripten to /libsndfile-emscripten.
COPY build_libsndfile.sh ./
RUN ./build_libsndfile.sh

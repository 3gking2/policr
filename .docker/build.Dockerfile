FROM bluerain/crystal:0.30.0-build


RUN apt update && \
    apt install libsqlite3-dev librocksdb-dev sqlite3 -y && \
    rm -rf /var/lib/apt/lists/*  && \
    rm -rf /var/lib/apt/lists/partial/*

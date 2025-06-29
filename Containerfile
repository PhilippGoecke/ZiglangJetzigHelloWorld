FROM debian:bookworm-slim as install

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y \
  && apt install -y --no-install-recommends --no-install-suggests ca-certificates curl xz-utils minisign \
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives

WORKDIR /ziglang

RUN curl -fsSL https://ziglang.org/builds/zig-x86_64-linux-0.15.0-dev.847+850655f06.tar.xz --output zig-x86_64-linux-0.15.0-dev.847+850655f06.tar.xz \
  && curl https://ziglang.org/builds/zig-x86_64-linux-0.15.0-dev.847+850655f06.tar.xz.minisig --output zig.tar.xz.minisig \
  && minisign -V -x zig.tar.xz.minisig -m zig-x86_64-linux-0.15.0-dev.847+850655f06.tar.xz -P 'RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U' \
  && tar xf zig-x86_64-linux-0.15.0-dev.847+850655f06.tar.xz \
  && mv zig-x86_64-linux-0.15.0-dev.847+850655f06/zig /usr/bin/ \
  && mv zig-x86_64-linux-0.15.0-dev.847+850655f06/lib/ /usr/lib/zig/ \
  && zig version

FROM debian:bookworm-slim as jetzig

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y \
  && apt install -y --no-install-recommends --no-install-suggests git ca-certificates curl \
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives

COPY --from=install /usr/bin/zig /usr/bin/zig
COPY --from=install /usr/lib/zig /usr/lib/zig

WORKDIR /jetzig

RUN git clone https://github.com/jetzig-framework/jetzig --depth 1 \
  && cd jetzig/cli \
  && zig build install \
  && mv zig-out/bin/jetzig /usr/bin/ \
  && jetzig --help

FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y \
  && apt install -y --no-install-recommends --no-install-suggests git ca-certificates curl \
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives

COPY --from=install /usr/bin/zig /usr/bin/zig
COPY --from=install /usr/lib/zig /usr/lib/zig
COPY --from=jetzig /usr/bin/jetzig /usr/bin/jetzig

WORKDIR /jetzig-app

RUN jetzig init . \
  && jetzig update \
  && ls -lisah

RUN zig build -Doptimize=ReleaseFast

EXPOSE 8080

#CMD ["jetzig" , "server"]

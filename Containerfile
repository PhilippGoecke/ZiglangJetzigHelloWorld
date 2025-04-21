FROM debian:bookworm-slim as install

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y \
  && apt install -y --no-install-recommends --no-install-suggests ca-certificates curl xz-utils minisign \
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives

WORKDIR /ziglang

RUN curl -fsSL https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz --output zig-linux-x86_64-0.14.0.tar.xz \
  && curl https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz.minisig --output zig.tar.xz.minisig \
  && ls -lisah \
  && minisign -V -x zig.tar.xz.minisig -m zig-linux-x86_64-0.14.0.tar.xz -P 'RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U' \
  && tar xf zig-linux-x86_64-0.14.0.tar.xz \
  && mv zig-linux-x86_64-0.14.0/zig /usr/bin/ \
  && mv zig-linux-x86_64-0.14.0/lib/ /usr/lib/zig/ \
  && zig version
  
FROM debian:bookworm-slim as zig

COPY --from=install /usr/bin/zig /usr/bin/zig
COPY --from=install /usr/lib/zig /usr/lib/zig

WORKDIR /hellozig

RUN zig version

RUN echo "const std = @import(\"std\");\n" > hello.zig \
  &&  echo "pub fn main() void {" >> hello.zig \
  &&  echo "  std.debug.print(\"Hello Zig!\\n", .{});" >> hello.zig \
  &&  echo "}" >> hello.zig \
  && cat hello.zig

RUN ls -lisah \
  && zig run hello.zig

FROM debian:bookworm-slim as jetzig

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y \
  && apt install -y --no-install-recommends --no-install-suggests git ca-certificates \
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

RUN jetzig version \
  && jetzig init . \
  && ls -lisah

#CMD zig build run

RUN zig build -Doptimize=ReleaseFast \
  && ls -lisah zig-out/bin/

EXPOSE 8080

#CMD ["jetzig" , "--bind", "0.0.0.0", "--port", "8080"]

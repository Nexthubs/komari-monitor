FROM --platform=$BUILDPLATFORM node:20-alpine AS frontend-builder

ARG KOMARI_WEB_REPO=https://github.com/komari-monitor/komari-web.git
ARG KOMARI_WEB_REF=main

WORKDIR /src

RUN apk add --no-cache git

RUN git clone --depth 1 --branch "${KOMARI_WEB_REF}" "${KOMARI_WEB_REPO}" komari-web

WORKDIR /src/komari-web

RUN npm install
RUN npm run build


FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS backend-builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /src

RUN apk add --no-cache build-base git

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Inject the built default theme so go:embed can package the frontend assets.
RUN mkdir -p public/defaultTheme/dist
COPY --from=frontend-builder /src/komari-web/dist ./public/defaultTheme/dist

RUN CGO_ENABLED=1 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} go build -trimpath -ldflags="-s -w" -o /out/komari .


FROM alpine:3.21

WORKDIR /app

RUN apk add --no-cache libgcc libstdc++ sqlite-libs tzdata

COPY --from=backend-builder /out/komari /app/komari

RUN chmod +x /app/komari

ENV GIN_MODE=release
ENV KOMARI_DB_TYPE=sqlite
ENV KOMARI_DB_FILE=/app/data/komari.db
ENV KOMARI_DB_HOST=localhost
ENV KOMARI_DB_PORT=3306
ENV KOMARI_DB_USER=root
ENV KOMARI_DB_PASS=
ENV KOMARI_DB_NAME=komari
ENV KOMARI_LISTEN=0.0.0.0:25774

EXPOSE 25774

CMD ["/app/komari", "server"]

# Build the manager binary
FROM golang:1.10.3 as builder

ENV DEP_VERSION 0.5.4

# Copy in the go src
WORKDIR /go/src/sigs.k8s.io/aws-alb-ingress-controller
COPY pkg/    pkg/
COPY cmd/    cmd/

# Get dependencies
COPY Gopkg.toml Gopkg.lock ./
RUN curl -fsSL -o /usr/local/bin/dep https://github.com/golang/dep/releases/download/v${DEP_VERSION}/dep-linux-amd64 && chmod +x /usr/local/bin/dep
RUN /usr/local/bin/dep ensure -vendor-only

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o manager sigs.k8s.io/aws-alb-ingress-controller/cmd/manager


# Copy the controller-manager into a thin image
FROM amazonlinux:2 as amazonlinux
FROM scratch
WORKDIR /
COPY --from=builder /go/src/sigs.k8s.io/aws-alb-ingress-controller/manager .
COPY --from=amazonlinux /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/
ENTRYPOINT ["/manager"]

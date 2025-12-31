# Note: Alpine has compatibility issues with Fedora 43's kernel (6.17+)
# due to RELRO protection in musl libc. Using Fedora-based image instead.
FROM fedora:latest
RUN dnf install -y curl && dnf clean all


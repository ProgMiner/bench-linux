# syntax=docker/dockerfile:1

FROM alpine:3.21 AS build

# https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage

RUN apk add --no-cache doas alpine-sdk alpine-conf syslinux xorriso squashfs-tools grub grub-efi

RUN adduser -D build && addgroup build abuild
RUN echo permit nopass :abuild >/etc/doas.d/doas.conf

WORKDIR /home/build
USER build:abuild

RUN abuild-keygen -i -a -n

RUN git clone --depth 1 -b 3.21-stable https://gitlab.alpinelinux.org/alpine/aports.git
WORKDIR /home/build/aports/scripts

COPY mkimg.benchmark.sh genapkowl-benchmark.sh .
RUN doas chown build:abuild ./*benchmark.sh && chmod +x ./*benchmark.sh

RUN ./mkimage.sh \
    --outdir /home/build/iso \
    --tag 3.21 \
    --repository https://dl-cdn.alpinelinux.org/alpine/v3.21/main \
    --profile benchmark \
    --arch x86_64

FROM scratch
COPY --from=build /home/build/iso/ /iso/
CMD ["/bin/true"]

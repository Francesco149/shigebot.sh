FROM voidlinux/voidlinux
RUN xbps-install -Syu
RUN xbps-install -Sy xxd wget curl glibc-locales
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/default/libc-locales && \
  echo 'en_US ISO-8859-1' >> /etc/default/libc-locales && \
  xbps-reconfigure -f glibc-locales && \
  echo "LANG=en_US.UTF-8" > /etc/locale.conf
ADD shigebot.sh /shigebot.sh
ADD config.sh /config.sh
ADD handlers /handlers
CMD [ "/shigebot.sh" ]

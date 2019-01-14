FROM voidlinux/voidlinux
RUN xbps-install -Syu
ADD shigebot.sh /shigebot.sh
ADD config.sh /config.sh
ADD handlers /handlers
CMD [ "/shigebot.sh" ]

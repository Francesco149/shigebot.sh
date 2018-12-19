FROM kubler/libressl-musl
ADD shigebot.sh /shigebot.sh
ADD config.sh /config.sh
ADD handlers /handlers
CMD [ "/shigebot.sh" ]

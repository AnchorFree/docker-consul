FROM consul:1.6.1

HEALTHCHECK CMD consul info

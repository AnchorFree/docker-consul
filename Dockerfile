FROM consul:0.9.3

HEALTHCHECK CMD consul info

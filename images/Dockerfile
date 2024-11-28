ARG CONDA_VERSION=latest

FROM continuumio/miniconda3:${CONDA_VERSION}

RUN apt-get update --yes && \
    apt-get install --yes curl gnupg2

# Installing Microsoft ODBC driver 
# https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15#debian17

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

RUN . /etc/os-release && \
    curl https://packages.microsoft.com/config/debian/$VERSION_ID/prod.list > /etc/apt/sources.list.d/mssql-release.list

RUN apt-get update --yes && \
    echo msodbcsql18 msodbcsql/ACCEPT_EULA boolean true | debconf-set-selections && \
    apt-get install --yes msodbcsql18
	
# Cleaning image

RUN apt-get remove --yes curl gnupg2 && \
    apt-get autoremove --yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

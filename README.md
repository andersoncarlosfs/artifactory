# Python Images

## Introduction
This document explains how to create images for projects using Python and Conda.

## Containerizing a project
In order to containerize a project, the project image can be derived from a base image that contains the minimal set of dependencies required to run the project.

### Creating a base image
This image adds the dependencies to access databases. For instance:

```Dockerfile
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
```

### Creating the project image
This image includes the project and its dependencies. It is necessary to inform the credentials to access `Artifactory` and the name of the base image. For instance:

```Dockerfile
ARG IMAGE_NAME=python
ARG PYTHON_VERSION=latest

FROM ${IMAGE_NAME}:${PYTHON_VERSION}

ARG ARTIFACTORY_HOST=
ARG ARTIFACTORY_CONDA_REPOSITORY=
ARG ARTIFACTORY_PYPI_REPOSITORY=

WORKDIR /usr/src/project

# Creating enviroment

COPY ./package-list.txt ./

COPY ./requirements.txt ./

COPY ./source/__main__.py ./

RUN --mount=type=secret,id=artifactory_user,target=/run/secrets/artifactory_user \ 
    --mount=type=secret,id=artifactory_password,target=/run/secrets/artifactory_password \
    conda install --channel https://$(cat /run/secrets/artifactory_user):$(cat /run/secrets/artifactory_password)@${ARTIFACTORY_HOST}/artifactory/api/conda/@${ARTIFACTORY_CONDA_REPOSITORY} --override-channels --insecure --file package-list.txt --yes && \
    rm --force package-list.txt

RUN --mount=type=secret,id=artifactory_user,target=/run/secrets/artifactory_user \ 
    --mount=type=secret,id=artifactory_password,target=/run/secrets/artifactory_password \
    pip install --no-cache-dir --index-url https://$(cat /run/secrets/artifactory_user):$(cat /run/secrets/artifactory_password)@${ARTIFACTORY_HOST}/artifactory/api/pypi/@${ARTIFACTORY_PYPI_REPOSITORY}/simple --trusted-host {ARTIFACTORY_HOST} --requirement requirements.txt && \
    rm --force requirements.txt

ENTRYPOINT ["python", "./__main__.py"]
```

### Building the images
The images can be build using `docker build` or `docker compose`.

### Using docker build  
First, it is necessary to build the base image adding a `tag` to name it. For instance:

```bash
docker build --tag python:latest ./base
```

Second, it is necessary to pass the `secrets` and a `tag` to build the project image. For instance:

```bash
docker build --tag project:latest --secret id=artifactory_user,src=./secrets/artifactory/user --secret id=artifactory_password,src=./secrets/artifactory/password ./project
```

#### Using docker compose
It is possible to use `docker compose` to define the image names, build order and secrets. For instance:

```yaml
version: '3'
  
secrets:
  artifactory_user:
    file: ./secrets/artifactory/user
  artifactory_password:
    file: ./secrets/artifactory/password 
    
volumes:
  logs:

services:
  python:
    image: python
    build:
      context: ./images
      args:
        CONDA_VERSION: latest

  project:
    image: project
      depends_on:
        - python
      #dns_search:
      #  -
    build:
      context: ./
      args:
        IMAGE_NAME: python
        ARTIFACTORY_HOST:
        ARTIFACTORY_CONDA_REPOSITORY:
        ARTIFACTORY_PYPI_REPOSITORY:
      secrets:
        - artifactory_user
        - artifactory_password
    cap_add:
      - SYS_ADMIN       # Adding administrators privileges to the container
      - DAC_READ_SEARCH # Adding standard permissions to the container
```

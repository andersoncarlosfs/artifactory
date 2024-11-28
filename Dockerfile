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

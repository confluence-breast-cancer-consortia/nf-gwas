FROM quay.io/genepi/nf-gwas:v1.0.9

# Install regenie (not as conda package available)
WORKDIR "/opt"
ENV REGENIE_VERSION="v4.1"
RUN rm -rf regenie && \ 
    mkdir regenie && cd regenie && \
    wget https://github.com/rgcgithub/regenie/releases/download/${REGENIE_VERSION}/regenie_${REGENIE_VERSION}.gz_x86_64_Linux.zip && \
    unzip -q regenie_${REGENIE_VERSION}.gz_x86_64_Linux.zip && \
    rm regenie_${REGENIE_VERSION}.gz_x86_64_Linux.zip && \
    mv regenie_${REGENIE_VERSION}.gz_x86_64_Linux regenie && \
    chmod +x regenie

ENV PATH="/opt/regenie/:${PATH}"

# Install bgenix via conda
RUN conda install -c conda-forge bgenix

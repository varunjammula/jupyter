FROM jupyter/datascience-notebook:latest
COPY jupyter_notebook_config.json /opt/conda/etc/jupyter/jupyter_notebook_config.json

USER root

RUN apt-get update \
    && apt-get install -y less vim htop libpq-dev lsb wget gnupg apt-transport-https python3.6 python-requests curl \
    && apt-get clean \
    && rm -rf /usr/lib/apt/lists/* \
    && fix-permissions $CONDA_DIR

RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | apt-key add - \
    && echo "deb [arch=amd64] https://packages.irods.org/apt/ xenial main" > /etc/apt/sources.list.d/renci-irods.list \
    && apt-get update \
    && apt-get install -y irods-icommands \
    && apt-get clean \
    && rm -rf /usr/lib/apt/lists/* \
    && fix-permissions $CONDA_DIR

RUN pip install ipython-sql jupyterlab==1.0.9 jupyterlab_sql psycopg2 \
    && conda update -n base conda \
    && conda install -c conda-forge nodejs \
    && jupyter serverextension enable jupyterlab_sql --py --sys-prefix \
    && jupyter lab build

# install the irods plugin for jupyter lab
RUN pip install jupyterlab_irods==3.0.2 \
    && jupyter serverextension enable --py jupyterlab_irods \
    && jupyter labextension install ijab

# install jupyterlab hub-extension, lab-manager, bokeh
RUN jupyter lab --version \
    && jupyter labextension install @jupyterlab/hub-extension \
                                    @jupyter-widgets/jupyterlab-manager \
                                    jupyterlab_bokeh 
                              
# install jupyterlab git extension
RUN jupyter labextension install @jupyterlab/git && \
        pip install --upgrade jupyterlab-git && \
        jupyter serverextension enable --py jupyterlab_git

# install jupyterlab github extension
RUN jupyter labextension install @jupyterlab/github

# add Bash kernel
RUN pip install bash_kernel && python3 -m bash_kernel.install 

RUN usermod -d /home/vjammula -u 1000 vjammula
RUN chown -R vjammula:users /home/vjammula

USER vjammula

COPY entry.sh /bin
RUN mkdir -p /home/vjammula/.irods


ENTRYPOINT ["bash", "/bin/entry.sh"]

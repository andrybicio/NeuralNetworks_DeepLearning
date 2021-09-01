# This is not the best and optimized Dockerfile one can think of (it weights 9GB...), 
# since packages and dependences were added on the fly as it had been needed to add them
# However, this configuration has been tested using Windows10 and WSL2 and it works.
# For sure some packages are redundant, or even do not needed, but this ain't my goal for the homework

#TL;DR -> Image is not at all optimized, so it weights 9GB. Though it works. :)
FROM pytorch/pytorch

RUN apt update
RUN apt-get install wget -y
RUN pip install jupyter jupyterlab pandas numpy scikit-learn cython matplotlib seaborn optuna plotly imageio
RUN apt-get install python-opengl -y && apt install xvfb -y && pip install pyvirtualdisplay && pip install piglet

ENV DEBIAN_FRONTEND=noninteractive 
RUN apt-get install keyboard-configuration -y

RUN apt-get install \
   curl \
   git \
   libgl1-mesa-dev \
   libgl1-mesa-glx \
   libglew-dev \
   libosmesa6-dev \
   net-tools \
   unzip \
   vim \
   xpra \
   xserver-xorg-dev -y

# I don't think Mujoco is needed. However, to be able to use several gym environments it is needed.
# IF MUJOCO is not needed, 
# one can neglect (i.e. comment) the Dockerfile from

###########################  HERE  ###############################################

# Please note that:
# - a license "mjkey.txt" is needed, you can download it from mujoco site 
# - files requirements.txt and requirements.dev.txt can be found here -> https://github.com/wiplug/mujoco-py


# Download mujoco
RUN curl https://www.roboti.us/download/mjpro150_linux.zip --output /tmp/mujoco.zip && \
    mkdir -p /root/.mujoco && \
    unzip /tmp/mujoco.zip -d /root/.mujoco && \
    rm -f /tmp/mujoco.zip


COPY ./mjkey.txt /root/.mujoco/
RUN apt-get install -y cmake zlib1g-dev libjpeg-dev xvfb xorg-dev python-opengl libboost-all-dev libsdl2-dev swig
ENV LD_LIBRARY_PATH /root/.mujoco/mujoco200/bin:${LD_LIBRARY_PATH}
WORKDIR /mujoco_py
# Copy over just requirements.txt at first. That way, the Docker cache doesn't
# expire until we actually change the requirements.
COPY ./requirements.txt /mujoco_py/
COPY ./requirements.dev.txt /mujoco_py/
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -r requirements.dev.txt
WORKDIR / 

# Set library load path
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/root/.mujoco/mjpro150/bin

# Install gym with mujoco
RUN pip3 install gym[mujoco]

########################### TO HERE  ###############################################


EXPOSE 8886 8887 8888 8889
RUN pip install pyglet opencv-python box2d-py Box2D gym[Box_2D]

RUN echo "export DISPLAY=:0"  >> /etc/profile

WORKDIR /workspace

ENTRYPOINT jupyter notebook --ip=0.0.0.0 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password='' --port 8886 
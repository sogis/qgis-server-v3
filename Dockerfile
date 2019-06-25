FROM ubuntu:18.04

MAINTAINER Andreas Neumann <andreas.neumann@bd.so.ch>

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL=C

# get build dependencies
#RUN apt-get update -y && apt-get install -y bison ca-certificates ccache cmake cmake-curses-gui dh-python doxygen expect flex gdal-bin git graphviz grass-dev libexiv2-dev libexpat1-dev libfcgi-dev libgdal-dev libgeos-dev libgsl-dev libosgearth-dev libpq-dev libproj-dev libqca-qt5-2-dev libqca-qt5-2-plugins libqt5opengl5-dev libqt5scintilla2-dev libqt5serialport5-dev libqt5sql5-sqlite libqt5svg5-dev libqt5webkit5-dev libqwt-qt5-dev libspatialindex-dev libspatialite-dev libsqlite3-dev libsqlite3-mod-spatialite libyaml-tiny-perl libzip-dev lighttpd locales ninja-build ocl-icd-opencl-dev opencl-headers pkg-config poppler-utils pyqt5-dev pyqt5-dev-tools pyqt5.qsci-dev python-autopep8 python3-all-dev python3-dateutil python3-dev python3-future python3-gdal python3-httplib2 python3-jinja2 python3-markupsafe python3-mock python3-nose2 python3-owslib python3-plotly python3-psycopg2 python3-pygments python3-pyproj python3-pyqt5 python3-pyqt5.qsci python3-pyqt5.qtsql python3-pyqt5.qtsvg python3-pyqt5.qtwebkit python3-requests python3-sip python3-sip-dev python3-six python3-termcolor python3-tz python3-yaml qt3d-assimpsceneimport-plugin qt3d-defaultgeometryloader-plugin qt3d-gltfsceneio-plugin qt3d-scene2d-plugin qt3d5-dev qt5-default qt5keychain-dev qtbase5-dev qtbase5-private-dev qtpositioning5-dev qttools5-dev qttools5-dev-tools saga spawn-fcgi txt2tags xauth xfonts-100dpi xfonts-75dpi xfonts-base xfonts-scalable xvfb spawn-fcgi cron
RUN apt-get update -y && apt-get install -y bison ca-certificates ccache cmake cmake-curses-gui dh-python doxygen expect flex gdal-bin git graphviz grass-dev libexpat1-dev libfcgi-dev libgdal-dev libgeos-dev libgsl-dev libosgearth-dev libpq-dev libproj-dev libqca-qt5-2-dev libqca-qt5-2-plugins libqscintilla2-qt5-dev libqt5opengl5-dev libqt5serialport5-dev libqt5sql5-sqlite libqt5svg5-dev libqt5webkit5-dev libqt5xmlpatterns5-dev libqwt-qt5-dev libspatialindex-dev libspatialite-dev libsqlite3-dev libsqlite3-mod-spatialite libyaml-tiny-perl libzip-dev lighttpd locales ninja-build ocl-icd-opencl-dev opencl-headers pkg-config poppler-utils pyqt5-dev pyqt5-dev-tools pyqt5.qsci-dev python3-all-dev python-autopep8 python3-dateutil python3-dev python3-future python3-gdal python3-httplib2 python3-jinja2 python3-markupsafe python3-mock python3-nose2 python3-owslib python3-plotly python3-psycopg2 python3-pygments python3-pyproj python3-pyqt5 python3-pyqt5.qsci python3-pyqt5.qtsql python3-pyqt5.qtsvg python3-pyqt5.qtwebkit python3-requests python3-sip python3-sip-dev python3-six python3-termcolor python3-tz python3-yaml qt3d-assimpsceneimport-plugin qt3d-defaultgeometryloader-plugin qt3d-gltfsceneio-plugin qt3d-scene2d-plugin qt3d5-dev qt5-default qt5keychain-dev qtbase5-dev qtbase5-private-dev qtpositioning5-dev qttools5-dev qttools5-dev-tools saga spawn-fcgi txt2tags xauth xfonts-100dpi xfonts-75dpi xfonts-base xfonts-scalable xvfb spawn-fcgi

#locale and timezone settings
RUN locale-gen de_CH.UTF-8
RUN update-locale

#non interactive timezone setting
ENV TZ=Europe/Zurich
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# what version of QGIS should we checkout?
# this can be overriden at build time with --build-arg qgis_branch=master
ARG qgis_branch=release-3_4
#ARG qgis_branch=master

# clone from git repo
COPY build-scripts /build/scripts
RUN /build/scripts/cloneQGISRepo.sh $qgis_branch

# build
RUN /build/scripts/buildQGIS.sh

# get rid of python plugin problems
RUN echo "" > /build/QGIS/build/python/plugins/cmake_install.cmake
RUN cd /build/QGIS/build; ninja install

# PostgreSQL-Service definitions
COPY conf/pg_service.conf /etc/pg_service.conf

#copy main start script
COPY scripts/start.sh /usr/local/bin/start.sh

# environment variables for QGIS server
ENV GDAL_SKIP "ECW JP2ECW"
ENV QGIS_PREFIX_PATH /usr
#ENV QGIS_PLUGINPATH /io/plugins

ENV QGIS_SERVER_LOG_FILE /logs/qgis-server.log
# logging to stderr works only if QGIS_SERVER_LOG_FILE is not defined. setting it to false is not enough.
# ENV QGIS_SERVER_LOG_STDERR false
ENV QGIS_SERVER_LOG_LEVEL 0
ENV QGIS_DEBUG 1

ENV HTTPS on
ENV QGIS_SERVER_PARALLEL_RENDERING true
ENV QGIS_SERVER_MAX_THREADS 2
#max image size in pixel
ENV QGIS_SERVER_WMS_MAX_WIDTH 7500
ENV QGIS_SERVER_WMS_MAX_HEIGHT 7500
#locale settings and group separator (thousand separator)
ENV QGIS_SERVER_OVERRIDE_SYSTEM_LOCALE de_CH.utf8
ENV QGIS_SERVER_SHOW_GROUP_SEPARATOR 0 
#how many layer references to cache
ENV MAX_CACHE_LAYERS 2000
#where to find the PostgreSQL service definitions
ENV PGSERVICEFILE /etc/pg_service.conf

ENV DEFAULT_DATUM_TRANSFORM       "EPSG:21781/EPSG:2056/100001/-1;EPSG:2056/EPSG:21781/-1/100001"
ENV LC_NUMERIC                    de_CH.utf8
ENV LANG                          de_CH.utf8

ENV QT_GRAPHICSSYSTEM raster
ENV DISPLAY :99

# add new user and create directory to hold svg symbols and logs
RUN useradd -u 9999 qgis
RUN mkdir /var/lib/qgis && chmod 1777 /var/lib/qgis
ENV HOME /var/lib/qgis
WORKDIR $HOME
RUN mkdir /logs && chown qgis /logs/

# work tools
RUN apt-get update -y && apt-get install -y vim mlocate


# clean
# RUN /build/scripts/clean.sh

# start von Nginx/QGIS Server
EXPOSE 9991
CMD /usr/local/bin/start.sh

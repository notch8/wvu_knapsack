#!/bin/bash

# set terminal
export TERM=vt100

# Copy Solr 8 module JARs where the webapp can find them
cp -r /opt/solr/modules/extraction/lib/* /opt/solr/server/solr-webapp/webapp/WEB-INF/lib/ 2>/dev/null || true
cp -r /opt/solr/modules/analysis-extras/lib/* /opt/solr/server/solr-webapp/webapp/WEB-INF/lib/ 2>/dev/null || true

chown -R 8983:8983 /var/solr

# Seed solr.xml into the data dir if this is a fresh volume.
# When bind-mounting /var/solr/data the container's default solr.xml is absent.
if [ ! -f /var/solr/data/solr.xml ]; then
  cp /opt/solr/server/solr/solr.xml /var/solr/data/solr.xml
  chown 8983:8983 /var/solr/data/solr.xml
fi

# Push security config to ZooKeeper before starting Solr in SolrCloud mode.
# ZK_HOST is set in docker-compose (e.g. zoo:2181).
/opt/solr/bin/solr zk cp file:/solr-setup/security.json zk:/security.json \
  -z "${ZK_HOST:-zoo:2181}" || true

# Start Solr in SolrCloud mode:
#   -f   = foreground (don't daemonize)
#   -c   = SolrCloud mode
#   -z   = ZooKeeper host
runuser -u solr -- solr start -f -c -z "${ZK_HOST:-zoo:2181}"
#!/bin/bash

# set terminal
export TERM=vt100

# Copy Solr 9+ module JARs (no-op on older versions)
cp -r /opt/solr/modules/extraction/lib/* /opt/solr/server/solr-webapp/webapp/WEB-INF/lib/ 2>/dev/null || true
cp -r /opt/solr/modules/analysis-extras/lib/* /opt/solr/server/solr-webapp/webapp/WEB-INF/lib/ 2>/dev/null || true

chown -R 8983:8983 /var/solr

# Push security config to ZooKeeper before starting Solr in SolrCloud mode.
# ZK_HOST is set in docker-compose (e.g. zoo:2181).
/opt/solr/bin/solr zk cp file:/solr9-setup/security.json zk:/security.json \
  -z "${ZK_HOST:-zoo:2181}" || true

# Start Solr in SolrCloud mode.
# SOLR_ENABLE_CLOUD_MODE=yes and ZK_HOST are read by solr-foreground automatically.
runuser -u solr -- /opt/docker-solr/scripts/solr-foreground
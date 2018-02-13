#!/usr/bin/env bash
# Set up a directory server.
#
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

#set -x

source /opt/opendj/env.sh

DB_NAME=${DB_NAME:-userRoot}

# The type of DJ we want to bootstrap. This determines the ldif files and scripts to load. Defaults to a userstore.
BOOTSTRAP_TYPE="${BOOTSTRAP_TYPE:-userstore}"

INIT_OPTION="--addBaseEntry"

# If NUMBER_SAMPLE_USERS is set AND we are the first node, then generate sample users.
if [[  -n "${NUMBER_SAMPLE_USERS}" && $HOSTNAME = *"0"* ]]; then
    INIT_OPTION="--sampleData ${NUMBER_SAMPLE_USERS}"
fi

# fork added this line:
# -b "dc=openidm,dc=forgerock,dc=com" \
# todo: We may want to specify a keystore using --usePkcs12keyStore, --useJavaKeystore
/opt/opendj/setup directory-server -p 1389 --ldapsPort 1636 --enableStartTLS  \
  --adminConnectorPort 4444 \
  --instancePath ./data \
  --baseDN "${BASE_DN}" -h "${DJ_FQDN}" \
   -b "dc=openidm,dc=forgerock,dc=com" \
  --rootUserPasswordFile "${DIR_MANAGER_PW_FILE}" \
  --acceptLicense \
  ${INIT_OPTION} || (echo "Setup failed, will sleep for debugging"; sleep 10000)

# fork added these create schema providers
/opt/opendj/bin/dsconfig \
   create-schema-provider \
   --hostname localhost \
   --port 4444 \
   --bindDN "cn=Directory Manager" \
   --bindPassword password \
   --provider-name "IDM managed/role Json Schema" \
   --type json-query-equality-matching-rule \
   --set enabled:true \
   --set case-sensitive-strings:false \
   --set ignore-white-space:true \
   --set matching-rule-name:caseIgnoreJsonQueryMatchManagedRole \
   --set matching-rule-oid:1.3.6.1.4.1.36733.2.3.4.2  \
   --set indexed-field:"condition/**" \
   --set indexed-field:"temporalConstraints/**" \
   --trustAll \
   --no-prompt

/opt/opendj/bin/dsconfig \
   create-schema-provider \
   --hostname localhost \
   --port 4444 \
   --bindDN "cn=Directory Manager" \
   --bindPassword password \
   --provider-name "IDM Relationship Json Schema" \
   --type json-query-equality-matching-rule \
   --set enabled:true \
   --set case-sensitive-strings:false \
   --set ignore-white-space:true \
   --set matching-rule-name:caseIgnoreJsonQueryMatchRelationship \
   --set matching-rule-oid:1.3.6.1.4.1.36733.2.3.4.3  \
   --set indexed-field:firstId \
   --set indexed-field:firstPropertyName \
   --set indexed-field:secondId \
   --set indexed-field:secondPropertyName \
   --trustAll \
   --no-prompt

/opt/opendj/bin/dsconfig \
   create-schema-provider \
   --hostname localhost \
   --port 4444 \
   --bindDN "cn=Directory Manager" \
   --bindPassword password \
   --provider-name "IDM Cluster Object Json Schema" \
   --type json-query-equality-matching-rule \
   --set enabled:true \
   --set case-sensitive-strings:false \
   --set ignore-white-space:true \
   --set matching-rule-name:caseIgnoreJsonQueryMatchClusterObject \
   --set matching-rule-oid:1.3.6.1.4.1.36733.2.3.4.4  \
   --set indexed-field:"timestamp" \
   --set indexed-field:"state" \
   --trustAll \
   --no-prompt

# fork added this
/opt/opendj/bin/stop-ds

# fork added this
cp -r /tmp/schema/* /opt/opendj/data/config/schema

# fork added this
/opt/opendj/bin/start-ds

# fork added these indexes
/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-uuid \
    --set index-type:equality \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-link-firstid \
    --set index-type:equality \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-link-secondid \
    --set index-type:equality \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-link-qualifier \
    --set index-type:equality \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-link-type \
    --set index-type:equality \
    --trustAll \
    --no-prompt


/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-managed-role-json \
    --set index-type:equality \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-cluster-json \
    --set index-type:equality \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-relationship-json \
    --set index-type:equality \
    --trustAll \
    --no-prompt


# vlvs for admin UI usage

/opt/opendj/bin/dsconfig \
    create-backend-vlv-index \
    --hostname localhost \
    --port 4444 \
    --bindDn "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name people-by-uid \
    --set base-dn:ou=People,dc=example,dc=com \
    --set filter:"(uid=*)" \
    --set scope:single-level \
    --set sort-order:"+uid" \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-vlv-index \
    --hostname localhost \
    --port 4444 \
    --bindDn "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name people-by-uid-matchall \
    --set base-dn:ou=People,dc=example,dc=com \
    --set filter:"(&)" \
    --set scope:single-level \
    --set sort-order:"+uid" \
    --trustAll \
    --no-prompt


# If any optional LDIF files are present, load them.
ldif="bootstrap/userstore/ldif"

if [ -d "$ldif" ]; then
    echo "Loading LDIF files in $ldif"
    for file in "${ldif}"/*.ldif;  do
        echo "Loading $file"
        # search + replace all placeholder variables. Naming conventions are from AM.
        sed -e "s/@BASE_DN@/$BASE_DN/"  \
            -e "s/@userStoreRootSuffix@/$BASE_DN/"  \
            -e "s/@DB_NAME@/$DB_NAME/"  \
            -e "s/@SM_CONFIG_ROOT_SUFFIX@/$BASE_DN/"  <${file}  >/tmp/file.ldif

        ./bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h localhost -p 1389 -j ${DIR_MANAGER_PW_FILE} -f /tmp/file.ldif
      echo "  "
    done
fi

script="bootstrap/userstore/post-install.sh"

if [ -r "$script" ]; then
    echo "executing post install script $script"
    sh "$script"
fi

ldif="bootstrap/extra/ldif"

if [ -d "$ldif" ]; then
    echo "Loading LDIF files in $ldif"
    for file in "${ldif}"/*.ldif;  do
        echo "Loading $file"
        # search + replace all placeholder variables. Naming conventions are from AM.
        sed -e "s/@BASE_DN@/$BASE_DN/"  \
            -e "s/@userStoreRootSuffix@/$BASE_DN/"  \
            -e "s/@DB_NAME@/$DB_NAME/"  \
            -e "s/@SM_CONFIG_ROOT_SUFFIX@/$BASE_DN/"  <${file}  >/tmp/file.ldif

        ./bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h localhost -p 1389 -j ${DIR_MANAGER_PW_FILE} -f /tmp/file.ldif
      echo "  "
    done
fi

script="bootstrap/extra/post-install.sh"

if [ -r "$script" ]; then
    echo "executing post install script $script"
    sh "$script"
fi

ldif="bootstrap/cts/ldif"

if [ -d "$ldif" ]; then
    echo "Loading LDIF files in $ldif"
    for file in "${ldif}"/*.ldif;  do
        echo "Loading $file"
        # search + replace all placeholder variables. Naming conventions are from AM.
        sed -e "s/@BASE_DN@/$BASE_DN/"  \
            -e "s/@userStoreRootSuffix@/$BASE_DN/"  \
            -e "s/@DB_NAME@/$DB_NAME/"  \
            -e "s/@SM_CONFIG_ROOT_SUFFIX@/$BASE_DN/"  <${file}  >/tmp/file.ldif

        ./bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h localhost -p 1389 -j ${DIR_MANAGER_PW_FILE} -f /tmp/file.ldif
      echo "  "
    done
fi

script="bootstrap/cts/post-install.sh"

if [ -r "$script" ]; then
    echo "executing post install script $script"
    sh "$script"
fi

/opt/opendj/schedule_backup.sh

/opt/opendj/rebuild.sh
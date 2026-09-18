#!/bin/bash

set -e

echo "=========================================="
echo " PostgreSQL Configuration"
echo "=========================================="

# --------------------------------------------------
# 3. Find PostgreSQL configuration files
# --------------------------------------------------

echo
echo ">>> Finding PostgreSQL configuration file..."

PG_CONF=$(sudo -u postgres psql -tAc "SHOW config_file;" | xargs)

echo "Config file:"
echo "$PG_CONF"


echo
echo ">>> Finding pg_hba.conf..."

PG_HBA=$(sudo -u postgres psql -tAc "SHOW hba_file;" | xargs)

echo "HBA file:"
echo "$PG_HBA"


# --------------------------------------------------
# Backup configuration files
# --------------------------------------------------

echo
echo ">>> Creating configuration backups..."

sudo cp "$PG_CONF" "${PG_CONF}.bak"
sudo cp "$PG_HBA" "${PG_HBA}.bak"

echo "Backups created."


# --------------------------------------------------
# Configure listen_addresses
# --------------------------------------------------

echo
echo ">>> Configuring listen_addresses..."

if grep -Eq '^[[:space:]]*#?[[:space:]]*listen_addresses[[:space:]]*=' "$PG_CONF"; then

    sudo sed -i \
        -E "s|^[[:space:]]*#?[[:space:]]*listen_addresses[[:space:]]*=.*|listen_addresses = '*'|" \
        "$PG_CONF"

else

    echo "listen_addresses = '*'" | sudo tee -a "$PG_CONF" > /dev/null

fi

echo "listen_addresses = '*' configured."


# --------------------------------------------------
# 4. Find Docker Compose network
# --------------------------------------------------

echo
echo ">>> Detecting Docker Compose network..."

NETWORK_NAME=$(docker network ls \
    --format '{{.Name}}' \
    | grep '_default$' \
    | head -1 || true)

if [ -z "$NETWORK_NAME" ]; then
    echo
    echo "ERROR: Docker Compose network was not found."
    echo
    echo "Available Docker networks:"
    docker network ls
    echo
    echo "Make sure your Docker Compose network already exists."
    exit 1
fi

echo "Docker Compose network:"
echo "$NETWORK_NAME"


# --------------------------------------------------
# Find actual Docker subnet
# --------------------------------------------------

echo
echo ">>> Detecting Docker subnet..."

SUBNET=$(docker network inspect "$NETWORK_NAME" \
    --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')

if [ -z "$SUBNET" ]; then
    echo "ERROR: Docker subnet could not be determined."
    exit 1
fi

echo "Actual Docker subnet:"
echo "$SUBNET"


# --------------------------------------------------
# Add pg_hba.conf rule
# --------------------------------------------------

echo
echo ">>> Configuring pg_hba.conf..."

RULE="host    all    microapp    ${SUBNET}    scram-sha-256"

if sudo grep -Fxq "$RULE" "$PG_HBA"; then

    echo "Rule already exists:"
    echo "$RULE"

else

    echo "Adding rule:"
    echo "$RULE"

    echo "$RULE" | sudo tee -a "$PG_HBA" > /dev/null

    echo "Rule added successfully."

fi


# --------------------------------------------------
# 5. Restart PostgreSQL
# --------------------------------------------------

echo
echo ">>> Restarting PostgreSQL..."

sudo systemctl restart postgresql

echo "PostgreSQL restarted successfully."


# --------------------------------------------------
# Verification
# --------------------------------------------------

echo
echo "=========================================="
echo " Verification"
echo "=========================================="

echo
echo ">>> PostgreSQL listening address:"
sudo -u postgres psql -c "SHOW listen_addresses;"

echo
echo ">>> Docker Compose network:"
echo "$NETWORK_NAME"

echo
echo ">>> Docker subnet:"
echo "$SUBNET"

echo
echo ">>> PostgreSQL microapp rule:"
sudo grep "microapp" "$PG_HBA" || true

echo
echo ">>> Port 5432:"
sudo ss -lntp | grep 5432 || true

echo
echo "=========================================="
echo " PostgreSQL configuration completed"
echo "=========================================="

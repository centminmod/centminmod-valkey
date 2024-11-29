#!/bin/bash

yum -y install valkey valkey-compat-redis --allowerasing

mkdir -p /etc/systemd/system/valkey.service.d
\cp -af /etc/systemd/system/redis.service.d/limit.conf.rpmsave /etc/systemd/system/valkey.service.d/limit.conf

if [ ! -f /etc/valkey/valkey.conf.bak ]; then
  cp -a /etc/valkey/valkey.conf /etc/valkey/valkey.conf.bak
fi

sed -i 's|\/var\/log\/redis\/redis.log|\/var\/log\/valkey\/valkey.log|g' /etc/valkey/valkey.conf

cat > "/etc/systemd/system/valkey.service.d/user.conf" <<EOF
[Service]
User=valkey
Group=nginx
EOF

cat > "/etc/systemd/system/disable-thp.service" <<EOF
[Unit]
Description=Disable Transparent Huge Pages (THP)
After=network.target

[Service]
Type=simple
ExecStart=/bin/sh -c "/usr/bin/echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled"

[Install]
WantedBy=multi-user.target
EOF

cat > "/etc/systemd/system/valkey.service.d/failure-restart.conf" <<TDG
[Unit]
StartLimitIntervalSec=30
StartLimitBurst=5

[Service]
Restart=on-failure
RestartSec=5s
TDG

echo
echo 'systemctl daemon-reload'
systemctl daemon-reload
echo
echo 'systemctl restart disable-thp'
systemctl restart disable-thp
echo
echo 'systemctl enable disable-thp'
systemctl enable disable-thp
echo
echo 'systemctl start valkey'
systemctl start valkey
echo
echo 'systemctl enable valkey'
systemctl enable valkey
echo
echo 'systemctl status disable-thp --no-pager -l'
systemctl status disable-thp --no-pager -l
echo
echo 'systemctl status valkey --no-pager -l'
systemctl status valkey --no-pager -l
echo
echo 'valkey-server -v'
valkey-server -v
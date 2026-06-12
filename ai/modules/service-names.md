### Service names (do not guess)

- Node exporter: `node-exporter` (hyphen, port 9101 behind metrics-proxy)
- IPMI exporter: `prometheus-ipmi-exporter` (Ansible-managed) OR
  `ipmi_exporter` (scott custom)
- Metrics proxy: `metrics_proxy` (underscore, port 9100)
- ZFS exporter: `zfs-exporter` (hyphen)
- When in doubt: `systemctl list-units | grep <keyword>`, don't guess
  the name.

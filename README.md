# HMIOS - The HMI Operating System

> Bringing Linux to Industrial HMIs

HMIOS transforms commodity hardware into reliable, centrally-managed industrial HMI terminals using NixOS, Git-based configuration management, and open-source technologies.



## 🎯 Features

- **Hardware Agnostic**: x86 PCs, tablets, Raspberry Pi, embedded systems
- **Git-Managed**: Version control for all configurations
- **Fleet Deployment**: Update hundreds of HMIs with one command  
- **Atomic Updates**: Instant rollback if anything goes wrong
- **Open Source**: No vendor lock-in, unlimited customization
- **Air-Gap Friendly**: Works on isolated industrial networks

## 🏭 Use Cases

- Manufacturing plant dashboards
- Power plant control rooms
- Water treatment monitoring
- Oil & gas facility displays
- Pharmaceutical clean room interfaces
- Food processing oversight systems

## 📊 Supported Dashboards

- Grafana (metrics and monitoring)
- Ignition Perspective (SCADA HMI)
- Custom web applications
- Node-RED dashboards
- Prometheus monitoring
- Any web-based interface

## 🛠️ Hardware Profiles

| Profile | Description | Status |
|---------|-------------|--------|
| `x86-industrial` | Fanless industrial PCs | ✅ Stable |
| `tablet` | Surface, ThinkPad tablets | ✅ Stable |
| `raspberry-pi` | Pi 3/4 systems | ✅ Stable |
| `custom` | Generic hardware | 🧪 Beta |

## 📋 Installation Requirements

- NixOS 23.11+ compatible hardware
- 4GB+ RAM recommended
- 32GB+ storage
- Network connectivity (for initial setup)
- UEFI boot support

## 🌐 Configuration Examples

### Factory Site Configuration
```nix
{
  site = {
    name = "chemical-plant-a";
    location = "Building 3, Control Room";
    
    dashboards = {
      primary = "http://plant-scada:8080/main-overview";
      safety = "http://safety-system:3000/alarms";
      maintenance = "http://cmms:8088/work-orders";
    };
    
    features = {
      alarm_audio = true;
      touch_interface = true;
      auto_rotation = false;
    };
  };
}
```

### Fleet Deployment
```bash
# Deploy to all factory sites
./scripts/deploy-fleet.sh --all

# Deploy to specific site
./scripts/deploy-fleet.sh --site chemical-plant-a

# Emergency rollback
./scripts/deploy-fleet.sh --rollback --all
```

## 🔧 Management Commands

```bash
# Check system status
hmios status

# Update configuration from Git
hmios update

# Deploy to fleet
hmios deploy --site factory-1

# Health monitoring
hmios monitor --continuous

# Emergency recovery
sudo nixos-rebuild switch --rollback
```

## 📈 Architecture

```
Central Git Repository
         │
    ┌────┼────┐
    │    │    │
Factory A │ Factory B
    │    │    │
┌───┼─┐  │ ┌──┼──┐
│HMI│ │  │ │HMI│ │
│   │ │  │ │   │ │
└───┘ │  │ └───┘ │
  HMI │  │   HMI │
      │  │       │
   Maintenance   Mobile
```

## 🤝 Contributing

We welcome contributions! See our [Contributing Guide](docs/CONTRIBUTING.md).

### Quick Contribution
```bash
# Fork the repository
git clone https://github.com/yourusername/hmios-core.git
cd hmios-core

# Create feature branch
git checkout -b feature/new-hardware-support

# Make changes and test
nixos-rebuild test

# Submit pull request
git push origin feature/new-hardware-support
```

## 📚 Documentation

- [Installation Guide](docs/installation.md)
- [Configuration Reference](docs/configuration.md)
- [Fleet Deployment](docs/deployment.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Hardware Profiles](docs/hardware.md)

## 🛡️ Security

HMIOS is designed for industrial environments with security in mind:

- Minimal attack surface
- Read-only root filesystem
- Configurable firewall rules
- SSH key authentication
- Audit logging
- Air-gap network support

## 📊 Roadmap

- [ ] Web-based configuration interface
- [ ] Advanced fleet analytics
- [ ] Mobile device support (full touch and OSK)
- [ ] Cloud synchronization (optional)
- [ ] Industrial protocol support (Modbus, OPC-UA)

## 🏆 Success Stories



## 🆘 Support

- 🐛 [Report Issues](https://github.com/yourusername/hmios-core/issues)
- 💬 [Discussion Forum](https://github.com/yourusername/hmios-core/discussions)  
- 📧 [Email Support](mailto:support@hmios.org)
- 📖 [Documentation](https://hmios.org/docs)

## 📄 License

HMIOS is open source software licensed under the [MIT License](LICENSE).

## 🙏 Acknowledgments

Built on the shoulders of giants:
- [NixOS](https://nixos.org/) - Declarative Linux distribution
- [Git](https://git-scm.com/) - Distributed version control
- [Grafana](https://grafana.com/) - Observability platform
- The entire open source industrial automation community

---

**HMIOS - Industrial Computing, Reimagined** 🏭⚡

*Star this repository if HMIOS is useful for your industrial automation projects!*

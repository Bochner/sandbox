# GOAD Offline Cache System

## Overview
The offline cache system is designed to enable GOAD (Game of Active Directory) deployment in air-gapped or limited-connectivity environments. It pre-downloads all necessary components, allowing for complete lab setup without internet access.

## System Architecture

### Integration with GOAD
The offline cache system serves as a local repository for all external dependencies required by GOAD, including:
- Operating system packages
- Security tools and agents
- Monitoring components
- PowerShell modules
- Ansible collections
- Python packages

### Directory Structure
```
offline_cache/
├── ansible-collections/     # Ansible Galaxy collections
├── elk/                    # Elasticsearch, Logstash, Kibana
│   ├── server/            # ELK server components
│   ├── windows-agent/     # Winlogbeat, Filebeat for Windows
│   └── linux-agent/       # Filebeat, Metricbeat for Linux
├── exchange/              # Microsoft Exchange components
│   └── prerequisites/     # Exchange prerequisites (VC++, etc.)
├── installers/            # Common Windows installers
├── pip-packages/          # Python dependencies
├── powershell-modules/    # PowerShell modules for AD management
│   └── modules/          # Downloaded PS modules
├── scripts/              # Cache management scripts
├── sql-server/           # SQL Server installers and tools
└── wazuh/               # Wazuh security monitoring
    ├── server/          # Wazuh manager, indexer, dashboard
    ├── windows-agent/   # Wazuh Windows agent
    └── linux-agent/     # Wazuh Linux agent
```

## Component Details

### Core Infrastructure Components
1. **Active Directory Components**
   - LAPS (Local Administrator Password Solution)
   - RSAT Tools (Remote Server Administration Tools)
   - PowerShell modules for AD management

2. **Exchange Server**
   - Exchange 2019 CU13 ISO
   - Visual C++ Redistributables
   - IIS URL Rewrite Module
   - Unified Communications Managed API

3. **SQL Server**
   - SQL Server 2019/2022 Installation Media
   - SQL Server Management Studio (SSMS)

### Monitoring & Security Tools

1. **ELK Stack (v8.11.1)**
   - Elasticsearch
   - Logstash
   - Kibana
   - Beats agents (Winlogbeat, Filebeat, Metricbeat)

2. **Wazuh Security Platform (v4.7.3)**
   - Wazuh Manager
   - Wazuh Indexer
   - Wazuh Dashboard
   - Agents for Windows and Linux

### Development & Automation Tools

1. **Ansible Components**
   - Core collections for Windows management
   - AD-specific roles and playbooks
   - Custom GOAD automation collections

2. **PowerShell Modules**
   - ActiveDirectory module
   - ADCSTemplate
   - xAdcsDeployment
   - SecurityPolicyDsc
   - NetworkingDsc
   - ComputerManagementDsc

## Cache Management

### Caching Process
1. **Initial Setup**
   ```bash
   ./scripts/cache_dependencies.sh
   ```
   - Downloads all components using robust retry mechanisms
   - Organizes files into appropriate directories
   - Validates downloads with error checking
   - Uses user-agent strings to handle restricted downloads

2. **Cache Maintenance**
   ```bash
   ./scripts/clear_cache.sh
   ```
   - Safely cleans all cached content
   - Preserves directory structure
   - Includes safety checks to prevent accidental deletions

### Integration with GOAD Deployment

1. **Pre-deployment Phase**
   - GOAD checks for offline_cache directory
   - Validates required components
   - Falls back to online sources if cache is incomplete

2. **Deployment Phase**
   - Uses cached installers for VM provisioning
   - Deploys monitoring agents from local cache
   - Installs PowerShell modules from cache
   - Configures security tools using cached packages

3. **Post-deployment Phase**
   - Updates configuration to use local resources
   - Establishes monitoring using cached agents
   - Configures security tools from local repository

## Automatic Cache Integration

### How GOAD Uses the Cache
GOAD automatically detects and uses the offline cache through these mechanisms:

1. **Detection Phase**
   - During startup, GOAD checks for the `offline_cache` directory in the project root
   - If found, it validates the required components for the chosen lab configuration
   - No manual configuration is needed - the presence of the cache directory triggers offline mode

2. **Component Resolution**
   - Each component type has a specific resolution order:
     ```
     a. Check offline cache first
     b. Fall back to online sources if file not found in cache
     c. Show warning if component is missing and can't be downloaded
     ```

3. **Cache Usage by Component**

   **PowerShell Modules**
   - GOAD first looks in `offline_cache/powershell-modules/modules`
   - Used during domain controller setup and AD configuration
   - Modules are copied to target VMs during provisioning

   **Python Dependencies**
   - Pip packages from `offline_cache/pip-packages` are used for initial GOAD setup
   - Used by `goad.sh` during environment preparation
   - Installed using `--no-index --find-links` pointing to cache

   **Ansible Collections**
   - Collections in `offline_cache/ansible-collections` are used for infrastructure deployment
   - Automatically loaded during playbook execution
   - No need to modify playbooks - Ansible detects local collections

   **Monitoring Components**
   - ELK Stack components from `offline_cache/elk` are used for log management setup
   - Wazuh components from `offline_cache/wazuh` are used for security monitoring
   - Agents are automatically deployed to VMs from cache

   **Windows Components**
   - Exchange prerequisites from `offline_cache/exchange` for Exchange Server setup
   - SQL Server installers from `offline_cache/sql-server` for database setup
   - Common Windows tools from `offline_cache/installers` for general infrastructure

### Validation Process
1. GOAD performs these checks before using cached files:
   - File existence in expected location
   - Basic file size validation
   - File name pattern matching
   - Version compatibility checks where applicable

2. Error handling:
   - Missing critical components trigger warnings
   - Version mismatches are reported
   - Download attempts are made for missing non-critical components if online
   - Detailed errors in logs help troubleshoot cache issues

### Cache Priority System
1. Local cache always takes precedence over online sources
2. Version-specific matches are preferred over generic matches
3. Cached files are used even if newer versions are available online
4. Missing critical components will block deployment
5. Missing optional components generate warnings but allow continuation

### Example Cache Usage Flow
```
1. User runs goad.sh
   ↓
2. GOAD detects offline_cache directory
   ↓
3. Components are validated
   ↓
4. Python deps installed from cache
   ↓
5. Ansible collections loaded from cache
   ↓
6. VM provisioning starts
   ↓
7. Windows components deployed from cache
   ↓
8. Monitoring tools installed from cache
   ↓
9. PowerShell modules deployed from cache
```

## Version Control & Updates

### Current Versions
- Wazuh Security Platform: 4.7.3
- ELK Stack: 8.11.1
- Exchange Server: 2019 CU13
- SQL Server: 2019/2022
- PowerShell Modules: Latest stable versions
- Ansible Collections: Latest compatible versions

### Update Process
1. Update version numbers in cache_dependencies.sh
2. Clear existing cache: `./scripts/clear_cache.sh`
3. Download new versions: `./scripts/cache_dependencies.sh`
4. Test deployment with new cache
5. Commit changes to version control

## Troubleshooting

### Common Issues
1. **Download Failures**
   - Check network connectivity
   - Verify URL availability
   - Check for required authentication
   - Review wget error messages

2. **Cache Validation**
   - Verify file integrity
   - Check directory permissions
   - Ensure sufficient disk space
   - Validate file versions

3. **Deployment Issues**
   - Verify cache completeness
   - Check file permissions
   - Review deployment logs
   - Validate component compatibility

### Best Practices
1. **Cache Management**
   - Regular cache updates
   - Version tracking
   - Space monitoring
   - Integrity verification

2. **Deployment**
   - Pre-deployment cache validation
   - Component version verification
   - Network connectivity checks
   - Error logging and monitoring

## Future Enhancements
- Automated cache validation
- Component version tracking
- Delta updates for large installers
- Compression for space optimization
- Automated integrity checking
- Cache status monitoring
- Component dependency mapping